# Flame graph trace of a single, simple JSV validation.
#
# Run with:
#
#     mix run bench/eflambe_simple.exs
#
# This builds a flat string schema (no nesting, no $ref, no applicators) so the
# trace shows the engine's per-call overhead rather than the cost of the
# individual keyword checks.
#
# eflambe is a *tracing* profiler: it records every function call/return, so it
# captures a full call tree even though a single validation runs in well under a
# microsecond — far too fast for a sampling profiler to see. The flip side is
# that tracing inflates absolute timings, so trust the *shape and call counts*,
# not the nanoseconds.
#
# Output is written as a Brendan Gregg collapsed-stack file (`.bggg`) in
# `bench/output/`. View it by:
#   * dragging the file onto https://www.speedscope.app, or
#   * piping it through Brendan Gregg's `flamegraph.pl > out.svg`.

{:ok, _} = Application.ensure_all_started(:jsv)

output_dir = Path.join(__DIR__, "output")
File.mkdir_p!(output_dir)

# How many times to run the validation inside a single trace. One call already
# yields the full call tree; more iterations give the frames meaningful weight.
iterations = String.to_integer(System.get_env("ITERATIONS", "100"))

schema = %{
  "type" => "string",
  "minLength" => 3,
  "maxLength" => 50,
  "pattern" => "^[a-z]+$"
}

root = JSV.build!(schema)
data = "hello"

# Sanity check before tracing.
{:ok, "hello"} = JSV.validate(data, root)

IO.puts("Tracing #{iterations} validations of a flat string schema...")

before = output_dir |> File.ls!() |> MapSet.new()

eflambe_opts = [
  output_directory: String.to_charlist(output_dir),
  output_format: :brendan_gregg
]

# For a single call, trace `JSV.validate/2` directly so the flame graph is
# rooted at the function under study instead of an `Enum.each` wrapper. For many
# iterations, wrap in a loop to give the frames meaningful weight.
case iterations do
  1 ->
    :eflambe.apply({JSV, :validate, [data, root]}, eflambe_opts)

  n ->
    run = fn -> Enum.each(1..n, fn _ -> {:ok, _} = JSV.validate(data, root) end) end
    :eflambe.apply({run, []}, eflambe_opts)
end

# The newest file in the output dir is the trace we just produced.
trace_file =
  output_dir
  |> File.ls!()
  |> MapSet.new()
  |> MapSet.difference(before)
  |> Enum.map(&Path.join(output_dir, &1))
  |> Enum.max_by(&File.stat!(&1).mtime)

# eflambe writes a *time-ordered* sample stream in Brendan Gregg collapsed format
# ("frame;frame;...;leaf count") and only folds adjacent identical stacks. So
# across N iterations the same stack recurs non-adjacently and is written N times
# over. Speedscope's default "Time Order" view then shows N separate towers; use
# its "Left Heavy" view to merge them — or load the pre-folded file we write
# below, which aggregates identical stacks regardless of time.
{by_module, by_leaf, stacks, total} =
  trace_file
  |> File.stream!()
  |> Enum.reduce({%{}, %{}, %{}, 0}, fn line, {mods, leaves, stacks, tot} ->
    line = String.trim_trailing(line)
    [stack, count] = Regex.run(~r/^(.*) (\d+)$/, line, capture: :all_but_first)
    count = String.to_integer(count)
    leaf = stack |> String.split(";") |> List.last()
    mod = leaf |> String.split(":") |> List.first()

    {Map.update(mods, mod, count, &(&1 + count)),
     Map.update(leaves, leaf, count, &(&1 + count)),
     Map.update(stacks, stack, count, &(&1 + count)), tot + count}
  end)

# Write a folded file with one line per unique stack (counts summed), so all
# iterations collapse into a single combined flame graph in any viewer/view.
folded_file = Path.rootname(trace_file) <> ".folded"

folded_contents =
  stacks
  |> Enum.sort_by(fn {_stack, count} -> -count end)
  |> Enum.map_join("", fn {stack, count} -> "#{stack} #{count}\n" end)

File.write!(folded_file, folded_contents)

format_rows = fn map ->
  map
  |> Enum.sort_by(fn {_k, v} -> -v end)
  |> Enum.take(12)
  |> Enum.map_join("\n", fn {k, v} ->
    "  #{String.pad_leading(to_string(v), 9)}  #{:erlang.float_to_binary(100 * v / total, decimals: 1)}%  #{k}"
  end)
end

IO.puts("""

Raw trace (time-ordered):  #{trace_file}
Folded (iterations merged): #{folded_file}   <- #{map_size(stacks)} unique stacks

View the FOLDED file at https://www.speedscope.app (drag & drop) for a single
combined flame graph. If you load the raw trace, switch Speedscope to the
"Left Heavy" view — the default "Time Order" view shows each iteration separately.

Self-time by module (top 12 of #{total} samples):
#{format_rows.(by_module)}

Self-time by function (top 12):
#{format_rows.(by_leaf)}
""")
