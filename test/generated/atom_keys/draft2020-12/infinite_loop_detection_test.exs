# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule JSV.Generated.Draft202012.AtomKeys.InfiniteLoopDetectionTest do
  alias JSV.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/infinite-loop-detection.json
  """

  describe "evaluating the same schema location against the same data location twice is not a sign of an infinite loop" do
    setup do
      json_schema = %JSV.Schema{
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        "$defs": %{int: %JSV.Schema{type: "integer"}},
        allOf: [
          %JSV.Schema{properties: %{foo: %JSV.Schema{"$ref": "#/$defs/int"}}},
          %JSV.Schema{additionalProperties: %JSV.Schema{"$ref": "#/$defs/int"}}
        ]
      }

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "passing case", x do
      data = %{"foo" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end

    test "failing case", x do
      data = %{"foo" => "a string"}
      expected_valid = false
      JsonSchemaSuite.run_test(x.json_schema, x.schema, data, expected_valid, print_errors: false)
    end
  end
end
