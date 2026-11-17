defmodule JSV.ErrorLevelTest do
  alias JSV.ErrorFormatter
  use ExUnit.Case, async: true

  defp findings(schema, data, opts) do
    root = JSV.build!(schema)
    assert {:error, err} = JSV.validate(data, root)

    %{details: details} = JSV.normalize_error(err, [sort: :asc] ++ opts)

    Enum.flat_map(details, fn unit ->
      Enum.map(unit.errors, fn error -> {unit.instanceLocation, error.kind, error.message} end)
    end)
  end

  @issue_schema %{
    type: :object,
    properties: %{
      user: %{
        type: :object,
        additionalProperties: false,
        properties: %{
          role: %{enum: ["admin", "user"]},
          name: %{type: :string}
        }
      }
    }
  }

  @issue_data %{"user" => %{"role" => "boss", "extra" => 1, "name" => 42}}

  test "all errors are returned by default" do
    assert [
             {"#", :properties, _},
             {"#/user", :properties, _},
             {"#/user", :properties, _},
             {"#/user", :additionalProperties, _},
             {"#/user/extra", :boolean_schema, _},
             {"#/user/name", :type, _},
             {"#/user/role", :enum, _}
           ] = findings(@issue_schema, @issue_data, [])

    assert findings(@issue_schema, @issue_data, []) ==
             findings(@issue_schema, @issue_data, min_error_level: 0)
  end

  test "the cause level keeps one error per invalidated data point" do
    assert [
             {"#/user/extra", :boolean_schema, "additional properties are not allowed but found property 'extra'"},
             {"#/user/name", :type, "value is not of type string"},
             {"#/user/role", :enum, "value must be one of the enum values: \"admin\" or \"user\""}
           ] = findings(@issue_schema, @issue_data, min_error_level: ErrorFormatter.level_cause())

    # Former level_parent_reported value
    assert findings(@issue_schema, @issue_data, min_error_level: ErrorFormatter.level_cause()) ==
             findings(@issue_schema, @issue_data, min_error_level: 8)
  end

  test "levels are not part of the normalized output" do
    root = JSV.build!(@issue_schema)
    assert {:error, err} = JSV.validate(@issue_data, root)

    normalized = JSV.normalize_error(err)

    refute normalized |> inspect(limit: :infinity) |> String.contains?("level")
  end

  describe "boolean subschemas" do
    test "a false property schema is reported on the child" do
      schema = %{properties: %{a: false}}

      assert [
               {"#", :properties, "property 'a' did not conform to the property schema"},
               {"#/a", :boolean_schema, "property 'a' is not allowed"}
             ] = findings(schema, %{"a" => 1}, [])

      assert [{"#/a", :boolean_schema, "property 'a' is not allowed"}] =
               findings(schema, %{"a" => 1}, min_error_level: ErrorFormatter.level_cause())
    end

    test "a false patternProperties schema is reported on the child" do
      schema = %{patternProperties: %{"^f" => false}}

      assert [
               {"#/foo", :boolean_schema, "properties matching /^f/ are not allowed but found property 'foo'"}
             ] = findings(schema, %{"foo" => 1}, min_error_level: ErrorFormatter.level_cause())
    end

    test "a false propertyNames schema is reported on the child" do
      schema = %{properties: %{x: %{propertyNames: false}}}

      assert [{"#/x/k", :boolean_schema, "properties are not allowed but found property 'k'"}] =
               findings(schema, %{"x" => %{"k" => 1}}, min_error_level: ErrorFormatter.level_cause())
    end

    test "one error per rejected key under the same pattern" do
      schema = %{patternProperties: %{"^f" => false}}

      assert [
               {"#/fob", :boolean_schema, "properties matching /^f/ are not allowed but found property 'fob'"},
               {"#/foo", :boolean_schema, "properties matching /^f/ are not allowed but found property 'foo'"}
             ] = findings(schema, %{"foo" => 1, "fob" => 2}, min_error_level: ErrorFormatter.level_cause())
    end

    test "the keyword message is only used for the direct subschema of the keyword" do
      plain = "value was rejected from boolean schema: false"

      cases = [
        {%{properties: %{a: false, b: %{"$ref": "#/properties/a"}}}, %{"b" => 1}, "#/b"},
        {%{properties: %{a: %{"$ref": "#/additionalProperties"}}, additionalProperties: false}, %{"a" => 1}, "#/a"},
        {%{properties: %{a: %{"$ref": "#/items"}}, items: false}, %{"a" => 1}, "#/a"},
        {%{items: %{"$ref": "#/properties/a"}, properties: %{a: false}}, [1], "#/0"},
        {%{"$ref": "#/properties/a", properties: %{a: false}}, %{}, "#"}
      ]

      for {schema, data, location} <- cases do
        assert [{^location, :boolean_schema, ^plain}] =
                 findings(schema, data, min_error_level: ErrorFormatter.level_cause()),
               "expected the plain boolean schema message for #{inspect(schema)}"
      end
    end

    # Keywords that do not report the rejected property themselves must keep the
    # boolean schema error, it is the only one describing the rejection.
    test "boolean schema errors are kept when no parent error restates them" do
      cases = [
        {%{prefixItems: [%{}], unevaluatedItems: false}, [1, 2], "#/1"},
        {%{properties: %{a: %{}}, unevaluatedProperties: false}, %{"a" => 1, "b" => 2}, "#/b"},
        {%{"$defs": %{f: false}, properties: %{a: %{"$ref": "#/$defs/f"}}}, %{"a" => 1}, "#/a"},
        {%{dependentSchemas: %{a: false}}, %{"a" => 1}, "#"},
        {false, 1, "#"}
      ]

      for {schema, data, location} <- cases do
        assert [{^location, :boolean_schema, _}] =
                 findings(schema, data, min_error_level: ErrorFormatter.level_cause()),
               "expected a boolean schema error for #{inspect(schema)}"
      end
    end
  end

  test "nested details are filtered too" do
    schema = %{properties: %{a: %{anyOf: [%{properties: %{b: %{type: :string}}}, %{type: :boolean}]}}}

    root = JSV.build!(schema)
    assert {:error, err} = JSV.validate(%{"a" => %{"b" => 1}}, root)

    assert %{details: [%{errors: [%{kind: :anyOf, details: details}]}]} =
             JSV.normalize_error(err, min_error_level: ErrorFormatter.level_cause())

    assert [
             %{instanceLocation: "#/a/b", errors: [%{kind: :type}]},
             %{instanceLocation: "#/a", errors: [%{kind: :type}]}
           ] = details
  end

  test "any integer is a valid level" do
    root = JSV.build!(%{type: :integer})
    assert {:error, err} = JSV.validate("nope", root)

    assert %{details: [_]} = JSV.normalize_error(err, min_error_level: -3)
    assert %{details: []} = JSV.normalize_error(err, min_error_level: 999)

    assert_raise ArgumentError, ~r/invalid value for option :min_error_level/, fn ->
      JSV.normalize_error(err, min_error_level: :high)
    end
  end
end
