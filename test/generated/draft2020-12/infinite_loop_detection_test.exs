# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
defmodule Elixir.Moonwalk.Generated.Draft202012.InfiniteLoopDetectionTest do
  alias Moonwalk.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/infinite-loop-detection.json
  """

  describe "evaluating the same schema location against the same data location twice is not a sign of an infinite loop:" do
    setup do
      json_schema = %{
        "$defs" => %{"int" => %{"type" => "integer"}},
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "allOf" => [
          %{"properties" => %{"foo" => %{"$ref" => "#/$defs/int"}}},
          %{"additionalProperties" => %{"$ref" => "#/$defs/int"}}
        ]
      }

      schema = JsonSchemaSuite.build_schema(json_schema, [])
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "passing case", c do
      data = %{"foo" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "failing case", c do
      data = %{"foo" => "a string"}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end
end
