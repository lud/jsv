# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule JSV.ResolverTest do
  alias JSV.Schema
  use ExUnit.Case, async: true

  defmodule ResolverRejectsFragments do
    alias JSV.Codec
    alias JSV.Resolver.Embedded

    def resolve(uri, _) do
      case URI.parse(uri) do
        %{fragment: nil} ->
          do_resolve(uri)

        %{fragment: frag} ->
          flunk("""
          resolver was called with fragment: #{inspect(frag)}

          URI
          #{uri}
          """)
      end
    end

    embedded = Embedded.embedded_normalized_ids()

    defp do_resolve(url) do
      case url do
        "jsv://test/local" ->
          {:ok, local()}

        "jsv://test/meta-format-assertion" ->
          {:ok, meta_format_assertion()}

        known when known in unquote(embedded) ->
          Embedded.resolve(known, [])

        _ ->
          flunk("unresolved: #{inspect(url)}")
      end
    end

    defp local do
      %{"$defs" => %{"string" => %{"type" => "string"}}, "type" => "integer"}
    end

    defp meta_format_assertion do
      Codec.decode!("""
      {
          "$id": "http://localhost:1234/draft2020-12/format-assertion-true.json",
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "$vocabulary": {
              "https://json-schema.org/draft/2020-12/vocab/core": true,
              "https://json-schema.org/draft/2020-12/vocab/format-assertion": true
          },
          "$dynamicAnchor": "meta",
          "allOf": [
              { "$ref": "https://json-schema.org/draft/2020-12/meta/core" },
              { "$ref": "https://json-schema.org/draft/2020-12/meta/format-assertion" }
          ]
      }
      """)
    end
  end

  describe "fragments are removed when resolver is called" do
    test "in meta schema" do
      # adding a fragment here should not have any effect
      raw_schema = %Schema{"$schema": "https://json-schema.org/draft/2020-12/schema#", type: :integer}
      assert {:ok, _} = JSV.build(raw_schema, resolver: ResolverRejectsFragments)
    end

    test "in refs" do
      raw_schema = %JSV.Schema{
        properties: %{
          a_string: %{"$ref": "jsv://test/local#/$defs/string"},
          an_int: %{"$ref": "jsv://test/local#"}
        }
      }

      assert {:ok, root} = JSV.build(raw_schema, resolver: ResolverRejectsFragments)
      assert {:ok, _} = JSV.validate(%{"a_string" => "hello", "an_int" => 123}, root)
    end

    test "meta schema as ref" do
      # Nothing special but this test was used to fill the embedded resolver by
      # failing on URLs whe should have embedded.
      raw_schema = %Schema{
        oneOf: [
          %{"$ref": "https://json-schema.org/draft/2020-12/schema#"},
          %{"$ref": "http://json-schema.org/draft-07/schema#"}
        ]
      }

      assert {:ok, _} = JSV.build(raw_schema, resolver: ResolverRejectsFragments)
    end

    test "meta schema as ref with format-assertion" do
      raw_schema = %Schema{
        "$schema": "jsv://test/meta-format-assertion",
        oneOf: [
          %{"$ref": "https://json-schema.org/draft/2020-12/schema#"},
          %{"$ref": "http://json-schema.org/draft-07/schema#"},
          %{"$ref": "jsv://test/meta-format-assertion#"}
        ]
      }

      assert {:ok, _} = JSV.build(raw_schema, resolver: ResolverRejectsFragments)
    end
  end

  describe "numeric string keys in JSON pointer paths" do
    test "resolves numeric string key in $defs map" do
      schema = %{"$ref" => "#/$defs/1", "$defs" => %{"1" => %{"type" => "object"}}}
      assert {:ok, root} = JSV.build(schema)
      assert {:ok, _} = JSV.validate(%{}, root)
      assert {:error, _} = JSV.validate(42, root)
    end

    test "resolves zero string key in $defs map" do
      schema = %{"$ref" => "#/$defs/0", "$defs" => %{"0" => %{"type" => "string"}}}
      assert {:ok, root} = JSV.build(schema)
      assert {:ok, _} = JSV.validate("hello", root)
      assert {:error, _} = JSV.validate(42, root)
    end

    test "resolves numeric string key with leading zeros in $defs map" do
      schema = %{"$ref" => "#/$defs/01", "$defs" => %{"01" => %{"type" => "string"}}}
      assert {:ok, root} = JSV.build(schema)
      assert {:ok, _} = JSV.validate("hello", root)
      assert {:error, _} = JSV.validate(42, root)
    end

    test "error when integer-looking key is absent from map" do
      schema = %{"$ref" => "#/$defs/1", "$defs" => %{"2" => %{"type" => "object"}}}
      assert {:error, %JSV.BuildError{reason: {:invalid_docpath, ["$defs", "1"], _, _}}} = JSV.build(schema)
    end

    test "error when list index is out of bounds" do
      # pointer 1 but allOf has only one item
      schema = %{"$ref" => "#/allOf/1", "allOf" => [%{"type" => "string"}]}
      assert {:error, %JSV.BuildError{reason: {:invalid_docpath, ["allOf", "1"], _, _}}} = JSV.build(schema)
    end

    test "error when list is empty" do
      schema = %{"$ref" => "#/allOf/0", "allOf" => []}
      assert {:error, %JSV.BuildError{reason: {:invalid_docpath, ["allOf", "0"], _, _}}} = JSV.build(schema)
    end

    test "error when list segment does not parse as an integer" do
      schema = %{"$ref" => "#/allOf/0foo", "allOf" => [%{"type" => "string"}]}
      assert {:error, %JSV.BuildError{reason: {:invalid_docpath, ["allOf", "0foo"], _, _}}} = JSV.build(schema)
    end

    test "integer index on list is not confused with string key on nested map" do
      # anyOf/0  -> list index 0 -> %{"0" => %{"type" => "string"}}  (the whole map)
      # anyOf/0/0 -> then map key "0" -> %{"type" => "string"}
      schema = %{
        "$ref" => "#/anyOf/0/0",
        "anyOf" => [%{"0" => %{"type" => "string"}}]
      }

      assert {:ok, root} = JSV.build(schema)
      assert {:ok, _} = JSV.validate("hello", root)
      assert {:error, _} = JSV.validate(42, root)
    end
  end
end
