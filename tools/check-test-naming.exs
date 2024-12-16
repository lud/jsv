#!/usr/bin/env elixir
Mix.install([:modkit])

defmodule Tool do
  @mount Modkit.Mount.define!([
           {JSV, "test/jsv"},
           {JSVTest, :ignore}
         ])

  def run do
    Path.wildcard(Path.join(File.cwd!(), "test/**/*test.exs"))
    |> Enum.flat_map(&check_naming/1)
    |> Enum.map(&with_preferred_path/1)
    |> Enum.each(&maybe_move/1)
  end

  defp check_naming(path) do
    path
    |> File.stream!()
    |> Stream.map(&String.trim/1)
    |> Stream.filter(&String.starts_with?(&1, "defmodule"))
    |> Enum.take(1)
    |> case do
      [] -> []
      ["defmodule " <> rest] -> [{path, String.split(rest, " ") |> hd()}]
    end
  end

  defp with_preferred_path({path, module_str}) do
    module = Module.concat([module_str])

    case Modkit.Mount.preferred_path(@mount, module) do
      {:ok, pref_path} ->
        pref_path = String.replace(pref_path, ~r/\.ex$/, ".exs")

        {path, module_str, pref_path}

      {:error, :not_mounted} ->
        {path, module_str, :not_mounted}

      :ignore ->
        {path, module_str, :ignore}
    end
  end

  defp maybe_move({path, module_str, :not_mounted}) do
    IO.puts("# not mounted #{inspect(module_str)} in #{path}")
  end

  defp maybe_move({_path, _module_str, :ignore}) do
    :ok
  end

  defp maybe_move({path, module_str, pref_path}) do
    module = Module.concat([module_str])
    cur_path = Path.relative_to_cwd(path)

    if cur_path == pref_path do
      # pass
    else
      IO.puts("# relocate module #{inspect(module)}")
      IO.puts("# relocate module #{inspect(module)}")
      print_move(module, cur_path, pref_path)
      IO.puts("mkdir -p " <> Path.dirname(pref_path))
      IO.puts("mv -vn #{cur_path} #{pref_path}\n")
    end
  end

  defp print_move(module, cur_path, pref_path) do
    {bad_rest, good_rest, common} = deviate_path(cur_path, pref_path)

    IO.puts([
      "# ",
      [inspect(module)],
      [
        "\n#  move ",
        common,
        color(:red, bad_rest),
        "\n#  to   ",
        common,
        color(:green, good_rest)
      ]
    ])
  end

  def color(color, str) do
    [apply(IO.ANSI, color, []), str, IO.ANSI.reset()]
  end

  defp deviate_path(from, to) do
    deviate_path(Path.split(from), Path.split(to), [])
  end

  defp deviate_path([same | from], [same | to], acc) do
    deviate_path(from, to, [same | acc])
  end

  defp deviate_path(from_rest, to_rest, acc) do
    common_path =
      case acc do
        [] -> ""
        list -> [Path.join(:lists.reverse(list)), ?/]
      end

    {Path.join(from_rest), Path.join(to_rest), common_path}
  end
end

Tool.run()
