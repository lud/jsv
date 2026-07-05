# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule JSV.MalformedSchemaTest do
  alias JSV.BuildError
  use ExUnit.Case, async: true

  # A malformed but syntactically-parseable schema must yield a structured
  # JSV.BuildError from JSV.build/2, never a raw crash (FunctionClauseError,
  # ArgumentError...). Messages should point at the offending keyword.

  defp assert_build_error(schema, mentions) do
    assert {:error, %BuildError{} = err} = JSV.build(schema)
    message = Exception.message(err)

    for fragment <- List.wrap(mentions) do
      assert message =~ fragment
    end

    err
  end

  test "$ref that is not a string" do
    assert_build_error(%{"$ref" => 123}, "invalid reference, expected a string, got: 123")
  end

  test "$dynamicRef that is not a string" do
    assert_build_error(%{"$dynamicRef" => 123}, "invalid reference, expected a string, got: 123")
  end

  test "$anchor that is not a string" do
    assert_build_error(%{"$anchor" => 123}, "invalid $anchor, expected a string, got: 123")
  end

  test "$dynamicAnchor that is not a string" do
    schema = %{
      "$defs" => %{"a" => %{"$dynamicAnchor" => 123}},
      "$ref" => "#/$defs/a"
    }

    assert_build_error(schema, "invalid $dynamicAnchor, expected a string, got: 123")
  end

  test "root $id that is not a string" do
    assert_build_error(%{"$id" => 123}, "invalid $id, expected a string, got: 123")
  end

  test "nested $id that is not a string" do
    schema = %{
      "$defs" => %{"a" => %{"$id" => 123}},
      "$ref" => "#/$defs/a"
    }

    assert_build_error(schema, "invalid $id, expected a string, got: 123")
  end

  test "$ref pointing to a value that is not a schema" do
    schema = %{
      "$defs" => %{"a" => "not a schema"},
      "$ref" => "#/$defs/a"
    }

    assert_build_error(schema, "not a schema")
  end

  test "$ref pointing to a missing definition" do
    assert_build_error(%{"$ref" => "#/$defs/missing"}, "missing")
  end
end
