# Validation benchmark meant to compare different versions of the library.
#
# The script only uses the public API so the same file can be run against
# multiple checkouts (git worktrees) of the library:
#
#     mix run /path/to/bench/validation.exs
#
# Environment variables:
#
# * BENCH_FILTER - Only run scenarios whose name contains this string.
# * BENCH_ROUNDS - Number of measured rounds per scenario, default 9.
# * BENCH_ROUND_MS - Approximate duration of a round in milliseconds, default
#   300.
# * BENCH_PRECHECK - When "1", only check that every scenario builds and that
#   its valid and invalid data validate as expected, without measuring.
#
# Each round runs in a fresh process. The reported time is the median of the
# rounds, along with the fastest round. Reductions per call are less sensitive
# to machine noise than time and are a good first signal when comparing two
# checkouts.

defmodule Bench.Tag do
  use JSV.Schema

  defschema name: string(minLength: 1), weight: integer(minimum: 0)
end

defmodule Bench.Item do
  use JSV.Schema

  defschema id: integer(),
            label: string(maxLength: 100),
            price: number(minimum: 0),
            tags: array_of(Bench.Tag),
            meta: %{type: :object, additionalProperties: %{type: :string}}
end

defmodule Bench.Customer do
  use JSV.Schema

  defschema name: string(), email: optional(string())
end

defmodule Bench.Order do
  use JSV.Schema

  defschema id: string(),
            customer: Bench.Customer,
            items: array_of(Bench.Item),
            status: string_enum_to_atom([:new, :paid])
end

defmodule Bench.Node do
  use JSV.Schema

  defschema value: integer(), child: optional(Bench.Node)
end

defmodule Bench.Cat do
  use JSV.Schema

  defschema kind: const("cat"), lives: integer(minimum: 0, maximum: 9)
end

defmodule Bench.Dog do
  use JSV.Schema

  defschema kind: const("dog"), good: boolean()
end

defmodule Bench.Named do
  use JSV.Schema

  defschema name: string()
end

defmodule Bench.Aged do
  use JSV.Schema

  defschema age: integer()
end

defmodule Bench.Combinators do
  use JSV.Schema

  defschema pets: array_of(one_of([Bench.Cat, Bench.Dog])),
            any: array_of(any_of([Bench.Cat, Bench.Dog])),
            person: all_of([Bench.Named, Bench.Aged])
end

defmodule Bench.Scenarios do
  def all do
    [
      plain_object(),
      structs(),
      struct_deep(),
      struct_combinators(),
      struct_array_large(),
      plain_array_large(),
      unevaluated()
    ]
  end

  defp item(i) do
    %{
      "id" => i,
      "label" => "item #{i}",
      "price" => i * 1.5,
      "tags" => [%{"name" => "a", "weight" => 1}, %{"name" => "b", "weight" => 2}],
      "meta" => %{"x" => "y"}
    }
  end

  defp order do
    %{
      "id" => "o1",
      "customer" => %{"name" => "bob", "email" => "bob@example.com"},
      "items" => Enum.map(1..10, &item/1),
      "status" => "paid"
    }
  end

  defp invalid_order do
    put_in(order(), ["items", Access.at(3), "tags", Access.at(1), "weight"], -1)
  end

  defp plain_order_schema do
    tag = %{
      type: :object,
      properties: %{name: %{type: :string, minLength: 1}, weight: %{type: :integer, minimum: 0}},
      required: [:name, :weight]
    }

    item = %{
      type: :object,
      properties: %{
        id: %{type: :integer},
        label: %{type: :string, maxLength: 100},
        price: %{type: :number, minimum: 0},
        tags: %{type: :array, items: tag},
        meta: %{type: :object, additionalProperties: %{type: :string}}
      },
      required: [:id, :label, :price, :tags, :meta]
    }

    %{
      type: :object,
      properties: %{
        id: %{type: :string},
        customer: %{
          type: :object,
          properties: %{name: %{type: :string}, email: %{type: :string}},
          required: [:name]
        },
        items: %{type: :array, items: item},
        status: %{enum: ["new", "paid"]}
      },
      required: [:id, :customer, :items, :status]
    }
  end

  defp plain_object do
    %{name: "plain_object", schema: plain_order_schema(), valid: order(), invalid: invalid_order()}
  end

  defp structs do
    %{name: "structs", schema: Bench.Order, valid: order(), invalid: invalid_order()}
  end

  defp struct_deep do
    nest = fn leaf_value ->
      Enum.reduce(1..30, %{"value" => leaf_value}, fn i, acc -> %{"value" => i, "child" => acc} end)
    end

    %{name: "struct_deep", schema: Bench.Node, valid: nest.(0), invalid: nest.("not an integer")}
  end

  defp struct_combinators do
    pets =
      Enum.flat_map(1..10, fn i ->
        [%{"kind" => "cat", "lives" => rem(i, 9)}, %{"kind" => "dog", "good" => true}]
      end)

    valid = %{"pets" => pets, "any" => pets, "person" => %{"name" => "alice", "age" => 30}}
    invalid = put_in(valid, ["pets", Access.at(15), "good"], "yes")

    %{name: "struct_combinators", schema: Bench.Combinators, valid: valid, invalid: invalid}
  end

  defp struct_array_large do
    valid = Enum.map(1..1000, &%{"name" => "tag #{&1}", "weight" => &1})
    invalid = List.replace_at(valid, 500, %{"name" => "", "weight" => -1})

    %{name: "struct_array_large", schema: JSV.Schema.Helpers.array_of(Bench.Tag), valid: valid, invalid: invalid}
  end

  defp plain_array_large do
    schema = %{
      type: :array,
      prefixItems: [%{type: :string}, %{type: :boolean}],
      items: %{type: :integer, minimum: 0}
    }

    valid = ["head", true | Enum.to_list(1..1000)]
    invalid = List.replace_at(valid, 500, -1)

    %{name: "plain_array_large", schema: schema, valid: valid, invalid: invalid}
  end

  defp unevaluated do
    schema = %{
      type: :object,
      properties: %{id: %{type: :string}},
      allOf: [
        %{properties: %{name: %{type: :string}}},
        %{properties: %{tags: %{type: :array, items: %{type: :string}}}}
      ],
      anyOf: [%{required: [:name]}, %{properties: %{alias: %{type: :string}}}],
      unevaluatedProperties: false
    }

    valid = %{"id" => "1", "name" => "x", "tags" => Enum.map(1..20, &"t#{&1}"), "alias" => "y"}
    invalid = Map.put(valid, "extra", 1)

    %{name: "unevaluated", schema: schema, valid: valid, invalid: invalid}
  end
end

defmodule Bench.Runner do
  def run do
    rounds = String.to_integer(System.get_env("BENCH_ROUNDS", "9"))
    round_ms = String.to_integer(System.get_env("BENCH_ROUND_MS", "300"))
    filter = System.get_env("BENCH_FILTER", "")

    scenarios =
      for scenario <- Bench.Scenarios.all(), String.contains?(scenario.name, filter) do
        precheck(scenario)
      end

    if System.get_env("BENCH_PRECHECK") in ["1", "true"] do
      IO.puts("precheck ok: #{Enum.map_join(scenarios, ", ", & &1.name)}")
    else
      IO.puts("JSV #{Application.spec(:jsv, :vsn)} - #{rounds} rounds of ~#{round_ms}ms")
      IO.puts(header())

      for scenario <- scenarios, {variant, data} <- [valid: scenario.valid, invalid: scenario.invalid] do
        fun = fn -> JSV.validate(data, scenario.root) end
        IO.puts(row("#{scenario.name} #{variant}", measure(fun, rounds, round_ms)))
      end
    end
  end

  defp precheck(scenario) do
    root = JSV.build!(scenario.schema, atoms: true)

    case {JSV.validate(scenario.valid, root), JSV.validate(scenario.invalid, root)} do
      {{:ok, _}, {:error, _}} ->
        Map.put(scenario, :root, root)

      {valid_result, invalid_result} ->
        raise "precheck failed for #{scenario.name}, valid data: #{inspect(valid_result)}, " <>
                "invalid data: #{inspect(invalid_result)}"
    end
  end

  defp measure(fun, rounds, round_ms) do
    iterations = calibrate(fun, round_ms)
    results = Enum.map(1..rounds, fn _ -> run_round(fun, iterations) end)
    times = Enum.sort(Enum.map(results, &elem(&1, 0)))
    reductions = Enum.sort(Enum.map(results, &elem(&1, 1)))

    %{median: median(times), min: hd(times), reductions: median(reductions)}
  end

  defp calibrate(fun, round_ms) do
    {ns, _} = run_round(fun, 100)
    max(100, trunc(round_ms * 1_000_000 / ns))
  end

  defp run_round(fun, iterations) do
    task =
      Task.async(fn ->
        loop(fun, div(iterations, 10) + 1)
        :erlang.garbage_collect()
        {:reductions, r0} = Process.info(self(), :reductions)
        t0 = System.monotonic_time(:nanosecond)
        loop(fun, iterations)
        t1 = System.monotonic_time(:nanosecond)
        {:reductions, r1} = Process.info(self(), :reductions)
        {(t1 - t0) / iterations, (r1 - r0) / iterations}
      end)

    Task.await(task, :infinity)
  end

  defp loop(_fun, 0) do
    :ok
  end

  defp loop(fun, n) do
    fun.()
    loop(fun, n - 1)
  end

  defp median(sorted) do
    Enum.at(sorted, div(length(sorted), 2))
  end

  defp header do
    pad("scenario", 30) <> lpad("median µs", 12) <> lpad("min µs", 12) <> lpad("reductions", 12)
  end

  defp row(label, %{median: median, min: min, reductions: reductions}) do
    pad(label, 30) <> lpad(us(median), 12) <> lpad(us(min), 12) <> lpad(Integer.to_string(round(reductions)), 12)
  end

  defp us(ns) do
    :erlang.float_to_binary(ns / 1000, decimals: 2)
  end

  defp pad(s, n) do
    String.pad_trailing(s, n)
  end

  defp lpad(s, n) do
    String.pad_leading(s, n)
  end
end

Bench.Runner.run()
