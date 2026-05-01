# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule JSV.ResolverTest do
  alias JSV.Ref
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

  describe "$id and $anchor inside examples are treated as literals" do
    test "duplicate $id values inside examples do not cause an error" do
      schema = %{
        "examples" => [
          %{"$id" => "foo", "name" => "Alice"},
          %{"$id" => "foo", "name" => "Bob"}
        ],
        "type" => "object"
      }

      assert {:ok, _} = JSV.build(schema)
    end

    test "duplicate $anchor values inside examples do not cause an error" do
      schema = %{
        "examples" => [
          %{"$anchor" => "my-anchor", "name" => "Alice"},
          %{"$anchor" => "my-anchor", "name" => "Bob"}
        ],
        "type" => "object"
      }

      assert {:ok, _} = JSV.build(schema)
    end

    test "$id in examples does not conflict with the schema's own $id" do
      schema = %{
        "$id" => "https://example.com/my-schema",
        "examples" => [%{"$id" => "https://example.com/my-schema", "name" => "Alice"}],
        "type" => "object"
      }

      assert {:ok, _} = JSV.build(schema)
    end

    test "$anchor in examples does not conflict with the schema's own $anchor" do
      schema = %{
        "$anchor" => "my-anchor",
        "examples" => [
          %{"$anchor" => "my-anchor", "name" => "Alice"},
          %{"$anchor" => "my-anchor", "name" => "Bob"}
        ],
        "type" => "object"
      }

      assert {:ok, _} = JSV.build(schema)
    end

    test "$ref into examples via JSON pointer still resolves correctly" do
      schema = %{
        "examples" => [%{"type" => "string"}],
        "properties" => %{"value" => %{"$ref" => "#/examples/0"}},
        "type" => "object"
      }

      assert {:ok, root} = JSV.build(schema)
      assert {:ok, _} = JSV.validate(%{"value" => "hello"}, root)
      assert {:error, _} = JSV.validate(%{"value" => 123}, root)
    end
  end

  describe "$id and $anchor in $defs/definitions/properties named 'examples'" do
    test "$defs entry named 'examples' with $id is resolvable via build_key" do
      schema = %{
        "$defs" => %{
          "examples" => %{
            "$id" => "https://example.com/from-defs",
            "type" => "string"
          }
        },
        "type" => "object",
        "examples" => [%{"$id" => "https://example.com/from-defs"}]
      }

      assert {:ok, ctx} = JSV.build_init([])
      assert {:ok, :root, _, ctx} = JSV.build_add(ctx, schema)
      assert {:ok, key, ctx} = JSV.build_key(ctx, Ref.parse!("#/$defs/examples", :root))
      assert {:ok, root} = JSV.to_root(ctx, :root)
      assert {:ok, _} = JSV.validate("hello", root, key: key)
      assert {:error, _} = JSV.validate(123, root, key: key)
    end

    test "definitions entry named 'examples' with $id is resolvable via build_key" do
      schema = %{
        "definitions" => %{
          "examples" => %{
            "$id" => "https://example.com/from-definitions",
            "type" => "integer"
          }
        },
        "type" => "object",
        "examples" => [%{"$id" => "https://example.com/from-definitions"}]
      }

      assert {:ok, ctx} = JSV.build_init([])
      assert {:ok, :root, _, ctx} = JSV.build_add(ctx, schema)
      assert {:ok, key, ctx} = JSV.build_key(ctx, Ref.parse!("#/definitions/examples", :root))
      assert {:ok, root} = JSV.to_root(ctx, :root)
      assert {:ok, _} = JSV.validate(42, root, key: key)
      assert {:error, _} = JSV.validate("hello", root, key: key)
    end

    test "properties entry named 'examples' with $id is resolvable via build_key" do
      schema = %{
        "properties" => %{
          "examples" => %{
            "$id" => "https://example.com/from-properties",
            "type" => "array"
          }
        },
        "type" => "object",
        "examples" => [
          %{"examples" => ["foo"]}
        ]
      }

      assert {:ok, ctx} = JSV.build_init([])
      assert {:ok, :root, _, ctx} = JSV.build_add(ctx, schema)
      assert {:ok, key, ctx} = JSV.build_key(ctx, Ref.parse!("#/properties/examples", :root))
      assert {:ok, root} = JSV.to_root(ctx, :root)
      assert {:ok, _} = JSV.validate([], root, key: key)
      assert {:error, _} = JSV.validate("hello", root, key: key)
    end

    test "$defs entry named 'examples' with $anchor is resolvable via build_key" do
      schema = %{
        "$defs" => %{
          "examples" => %{
            "$anchor" => "my-def-anchor",
            "type" => "boolean"
          }
        },
        "examples" => [%{"$anchor" => "my-def-anchor"}]
      }

      assert {:ok, ctx} = JSV.build_init([])
      assert {:ok, :root, _, ctx} = JSV.build_add(ctx, schema)
      assert {:ok, key, ctx} = JSV.build_key(ctx, Ref.parse!("#my-def-anchor", :root))
      assert {:ok, root} = JSV.to_root(ctx, :root)
      assert {:ok, _} = JSV.validate(true, root, key: key)
      assert {:error, _} = JSV.validate("hello", root, key: key)
    end
  end

  describe "$defs and properties with keys literally named '$id' or '$anchor'" do
    test "property schema named '$id' builds and validates correctly" do
      schema = %{
        "$id" => "foo",
        "properties" => %{
          "$id" => %{"type" => "string"},
          "$anchor" => %{"type" => "integer"}
        },
        "type" => "object",
        "examples" => [
          %{"$id" => "foo"}
        ]
      }

      assert {:ok, root} = JSV.build(schema)
      assert {:ok, _} = JSV.validate(%{"$id" => "hello", "$anchor" => 42}, root)
      assert {:error, _} = JSV.validate(%{"$id" => 123}, root)
      assert {:error, _} = JSV.validate(%{"$anchor" => "not-an-int"}, root)
    end

    test "$defs entry named '$id' builds without error" do
      schema = %{
        "$defs" => %{
          "$id" => %{"type" => "string"},
          "$anchor" => %{"type" => "integer"}
        }
      }

      assert {:ok, _} = JSV.build(schema)
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
