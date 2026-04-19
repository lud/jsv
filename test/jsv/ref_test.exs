# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule JSV.RefTest do
  alias JSV.Ref
  alias JSV.Resolver.Embedded
  use ExUnit.Case, async: true

  doctest JSV.Ref

  describe "parse/2" do
    test "parses a reference to the root" do
      {:ok, ref} = Ref.parse("", :root)

      assert %Ref{
               ns: :root,
               kind: :top,
               arg: [],
               dynamic?: false
             } = ref
    end

    test "parses a reference with just a fragment" do
      {:ok, ref} = Ref.parse("#/properties/name", :root)

      assert %Ref{
               ns: :root,
               kind: :pointer,
               arg: ["properties", "name"],
               dynamic?: false
             } = ref
    end

    test "parses a reference with an anchor" do
      {:ok, ref} = Ref.parse("#foo", :root)

      assert %Ref{
               ns: :root,
               kind: :anchor,
               arg: "foo",
               dynamic?: false
             } = ref
    end

    test "parses references with a different namespace" do
      {:ok, ref} = Ref.parse("http://example.com/schema.json", :root)

      assert %Ref{
               ns: "http://example.com/schema.json",
               kind: :top,
               arg: [],
               dynamic?: false
             } = ref
    end

    test "parses references with a different namespace and fragment" do
      {:ok, ref} = Ref.parse("http://example.com/schema.json#/properties/name", :root)

      assert %Ref{
               ns: "http://example.com/schema.json",
               kind: :pointer,
               arg: ["properties", "name"],
               dynamic?: false
             } = ref
    end

    test "handles relative paths" do
      current_ns = "http://example.com/schema/"
      {:ok, ref} = Ref.parse("user.json", current_ns)

      assert %Ref{
               ns: "http://example.com/schema/user.json",
               kind: :top,
               arg: [],
               dynamic?: false
             } = ref
    end
  end

  describe "parse_dynamic/2" do
    test "parses a dynamic reference" do
      {:ok, ref} = Ref.parse_dynamic("#foo", :root)

      assert %Ref{
               ns: :root,
               kind: :anchor,
               arg: "foo",
               dynamic?: true
             } = ref
    end

    test "only sets dynamic flag for anchors" do
      {:ok, ref} = Ref.parse_dynamic("#/properties/name", :root)

      assert %Ref{
               ns: :root,
               kind: :pointer,
               arg: ["properties", "name"],
               dynamic?: false
             } = ref
    end
  end

  describe "forced creation of pointer" do
    test "creates a pointer reference from string segments" do
      assert %Ref{
               ns: :root,
               kind: :pointer,
               arg: ["properties", "name"],
               dynamic?: false
             } = Ref.pointer!(["properties", "name"], :root)
    end

    test "creates a pointer reference from mixed string and integer segments" do
      assert %Ref{
               ns: :root,
               kind: :pointer,
               arg: ["items", 0, "name"],
               dynamic?: false
             } = Ref.pointer!(["items", 0, "name"], :root)
    end

    test "creates a pointer reference from empty segments list" do
      assert %Ref{
               ns: :root,
               kind: :pointer,
               arg: [],
               dynamic?: false
             } = Ref.pointer!([], :root)
    end

    test "creates a pointer reference with a custom namespace" do
      assert %Ref{
               ns: "http://example.com/schema.json",
               kind: :pointer,
               arg: ["properties", "user"],
               dynamic?: false
             } = Ref.pointer!(["properties", "user"], "http://example.com/schema.json")
    end
  end

  describe "escape_json_pointer/1" do
    test "escapes ~ as ~0" do
      assert "property~0name" == Ref.escape_json_pointer("property~name")
    end

    test "escapes / as ~1" do
      assert "property~1name" == Ref.escape_json_pointer("property/name")
    end

    test "escapes both ~ and / characters" do
      assert "~0~1property~1~0name~1" == Ref.escape_json_pointer("~/property/~name/")
    end

    test "handles strings without special characters" do
      assert "normal" == Ref.escape_json_pointer("normal")
    end
  end

  describe "JSON pointer parsing" do
    test "parses / as root" do
      {:ok, ref} = Ref.parse("#/", :root)

      assert %Ref{
               ns: :root,
               kind: :top,
               arg: [],
               dynamic?: false
             } = ref
    end

    test "parses numeric segments as integers" do
      {:ok, ref} = Ref.parse("#/items/0", :root)

      assert %Ref{
               ns: :root,
               kind: :pointer,
               arg: ["items", 0],
               dynamic?: false
             } = ref
    end

    test "handles URI encoded characters" do
      {:ok, ref} = Ref.parse("#/properties/user%20name", :root)

      assert %Ref{
               ns: :root,
               kind: :pointer,
               arg: ["properties", "user name"],
               dynamic?: false
             } = ref
    end

    test "decodes escaped sequences in JSON pointers" do
      {:ok, ref} = Ref.parse("#/properties/path~1name~0tilde", :root)

      assert %Ref{
               ns: :root,
               kind: :pointer,
               arg: ["properties", "path/name~tilde"],
               dynamic?: false
             } = ref
    end
  end

  describe "draft-07 top-level $id with sibling $ref" do
    test "builds and validates against a definition resolved via root $id" do
      schema = %{
        "$schema" => "http://json-schema.org/draft-07/schema#",
        "$id" => "http://example.com/schema.json",
        "$ref" => "#/definitions/foo",
        "definitions" => %{"foo" => %{"type" => "object"}}
      }

      root = JSV.build!(schema)

      assert {:ok, %{}} = JSV.validate(%{}, root)
      assert {:error, _} = JSV.validate("not an object", root)
    end

    test "$ref can target :root in Draft 7 when using local pointer" do
      schema = %{
        "$schema" => "http://json-schema.org/draft-07/schema#",
        "properties" => %{
          "age" => %{"$ref" => "#/definitions/some_int"}
        },
        "definitions" => %{"some_int" => %{"type" => "integer"}}
      }

      root = JSV.build!(schema)

      assert {:ok, %{"age" => 123}} = JSV.validate(%{"age" => 123}, root)
      assert {:error, _} = JSV.validate(%{"age" => "not an int"}, root)
    end

    test "top-level $ref to a relative file without a sibling $id" do
      schema = %{
        "$schema" => "http://json-schema.org/draft-07/schema#",
        "$ref" => "foo.json"
      }

      assert_raise JSV.BuildError, ~r{"foo.json" against base :root}, fn ->
        JSV.build!(schema)
      end
    end
  end

  # Expected outcomes verified against python-jsonschema 4.26 (and Ajv for
  # cases 1-4 — Ajv diverges from the spec on cases 5 & 6).
  describe "draft-07 $id and $ref edge cases" do
    defmodule RemoteRefResolver do
      def resolve("http://example.com/remote.json", _) do
        {:ok,
         %{
           "$schema" => "http://json-schema.org/draft-07/schema#",
           "$id" => "http://example.com/remote.json",
           "type" => "boolean"
         }}
      end

      def resolve(uri, opts) do
        Embedded.resolve(uri, opts)
      end
    end

    test "1. top-level $id + self-ref '#' (recursive)" do
      schema = %{
        "$schema" => "http://json-schema.org/draft-07/schema#",
        "$id" => "http://example.com/recursive.json",
        "type" => "object",
        "properties" => %{"child" => %{"$ref" => "#"}}
      }

      root = JSV.build!(schema)

      assert {:ok, _} = JSV.validate(%{"child" => %{"child" => %{}}}, root)
      assert {:error, _} = JSV.validate(%{"child" => "not-an-object"}, root)
    end

    test "2. top-level $id + anchor $ref '#foo'" do
      schema = %{
        "$schema" => "http://json-schema.org/draft-07/schema#",
        "$id" => "http://example.com/anchor.json",
        "$ref" => "#foo",
        "definitions" => %{"tag" => %{"$id" => "#foo", "type" => "integer"}}
      }

      root = JSV.build!(schema)

      assert {:ok, 42} = JSV.validate(42, root)
      assert {:error, _} = JSV.validate("nope", root)
    end

    test "3. top-level $id + absolute remote $ref (pre-registered)" do
      schema = %{
        "$schema" => "http://json-schema.org/draft-07/schema#",
        "$id" => "http://example.com/host.json",
        "$ref" => "http://example.com/remote.json"
      }

      root = JSV.build!(schema, resolver: RemoteRefResolver)

      assert {:ok, true} = JSV.validate(true, root)
      assert {:error, _} = JSV.validate(0, root)
    end

    test "4. relative top-level $id with sibling $ref (no external base)" do
      schema = %{
        "$schema" => "http://json-schema.org/draft-07/schema#",
        "$id" => "schema.json",
        "$ref" => "#/definitions/foo",
        "definitions" => %{"foo" => %{"type" => "object"}}
      }

      root = JSV.build!(schema)

      assert {:ok, %{}} = JSV.validate(%{}, root)
      assert {:error, _} = JSV.validate("no", root)
    end

    test "5. nested $id + $ref where parent $id is relative to outer $id" do
      schema = %{
        "$schema" => "http://json-schema.org/draft-07/schema#",
        "$id" => "http://example.com/outer/",
        "$ref" => "#/definitions/inner",
        "definitions" => %{
          "inner" => %{
            "$id" => "inner/",
            "allOf" => [
              %{
                "$id" => "more/",
                "$ref" => "thing.json"
              }
            ]
          },
          "thing" => %{
            "$id" => "inner/thing.json",
            "type" => "number"
          }
        }
      }

      root = JSV.build!(schema)

      assert {:ok, 3.14} = JSV.validate(3.14, root)
      assert {:error, _} = JSV.validate("nope", root)
    end

    test "6. $ref sibling to $id inside definitions (not under an applicator)" do
      schema = %{
        "$schema" => "http://json-schema.org/draft-07/schema#",
        "$id" => "http://example.com/defs.json",
        "$ref" => "#/definitions/wrapper",
        "definitions" => %{
          "wrapper" => %{
            "$id" => "wrapper.json",
            "$ref" => "#/definitions/payload"
          },
          "payload" => %{"type" => "string"}
        }
      }

      root = JSV.build!(schema)

      assert {:ok, "hi"} = JSV.validate("hi", root)
      assert {:error, _} = JSV.validate(1, root)
    end
  end
end
