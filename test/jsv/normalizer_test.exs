defmodule JSV.NormalizerTest do
  alias JSV.Resolver.Internal
  alias JSV.Schema
  use ExUnit.Case, async: true

  doctest JSV.Normalizer

  describe "normalize" do
    test "remove all atoms from map" do
      # handles maps with atom keys
      assert %{"hello" => "world"} == Schema.normalize(%{hello: "world"})

      # handles maps with numeric keys
      assert %{"1" => "one", "-0.0" => "zero"} == Schema.normalize(%{1 => "one", -0.0 => "zero"})

      # handles maps with atom values
      assert %{"hello" => "world"} == Schema.normalize(%{hello: :world})

      # keeps booleans and nil as values but not keys
      assert %{"true" => true} == Schema.normalize(%{true: true})
      assert %{"false" => false} == Schema.normalize(%{false: false})
      assert %{"nil" => nil} == Schema.normalize(%{nil: nil})

      # keeps basic types
      assert %{"i" => 1, "f" => 2.3, "l" => [4]} == Schema.normalize(%{i: 1, f: 2.3, l: [4]})
    end

    test "removes all atoms and nil values from Schema struct" do
      # handles structs with a special treatment for the schema struct, it removes
      # all nil values.

      assert %{"title" => "stuff"} == Schema.normalize(%Schema{title: "stuff"})

      assert %{"anyOf" => [%{"properties" => %{"foo" => 1}}]} ==
               Schema.normalize(%Schema{anyOf: [%Schema{properties: %{foo: 1}}]})
    end

    defmodule MyStruct do
      defstruct a: nil, b: nil
    end

    test "calls the normalizer for other structs" do
      defimpl JSV.Normalizer.Normalize, for: MyStruct do
        @impl true
        def normalize(s) do
          send(self(), {:called_protocol, s.a})
          %{"some_other_key" => s.a, "b" => s.b}
        end
      end

      # It will be called on the struct
      assert %{"some_other_key" => "hello", "b" => nil} == Schema.normalize(%MyStruct{a: "hello"})
      assert_receive {:called_protocol, "hello"}

      # It will be called on both structs, and should be called on the parent
      # struct first, despite being postwalk
      assert %{"some_other_key" => "parent", "b" => %{"some_other_key" => "child", "b" => nil}} ==
               Schema.normalize(%MyStruct{a: "parent", b: %MyStruct{a: "child"}})

      assert "parent" ==
               (receive do
                  {:called_protocol, who} -> who
                end)

      assert "child" ==
               (receive do
                  {:called_protocol, who} -> who
                end)
    end

    test "incompatible values: tuple keys" do
      assert_raise ArgumentError, fn ->
        Schema.normalize(%{{:a, :b} => "value"})
      end
    end

    test "incompatible values: tuple values" do
      assert_raise ArgumentError, fn ->
        Schema.normalize(%{key: {:a, :b}})
      end
    end

    test "incompatible values: pid keys" do
      assert_raise ArgumentError, fn ->
        Schema.normalize(%{self() => "value"})
      end
    end

    test "incompatible values: pid values" do
      assert_raise ArgumentError, fn ->
        Schema.normalize(%{key: self()})
      end
    end

    test "incompatible values: ref keys" do
      assert_raise ArgumentError, fn ->
        Schema.normalize(%{make_ref() => "value"})
      end
    end

    test "incompatible values: ref values" do
      assert_raise ArgumentError, fn ->
        Schema.normalize(%{key: make_ref()})
      end
    end

    test "converts modules that export json_schema/0 to refs" do
      defmodule ExportsSchema do
        @spec schema :: no_return()
        def schema do
          raise "will not be called"
        end
      end

      assert %{"$ref" => Internal.module_to_uri(ExportsSchema)} == Schema.normalize(ExportsSchema)
    end

    test "converts Elixir modules that do not export json_schema/0 to string" do
      # This is enforced because we expect the atom to be a valid module
      defmodule DoesNotExportSchema do
      end

      assert to_string(DoesNotExportSchema) == Schema.normalize(DoesNotExportSchema)
    end

    test "converts Erlang modules that do not export json_schema/0 to string" do
      # This is not an Elixir module, so we cannot know if it's a custom type, format, etc.
      defmodule unquote(:test_schema_module_to_ref) do
      end

      # So it's just stringified
      assert "test_schema_module_to_ref" == Schema.normalize(:test_schema_module_to_ref)
    end

    test "converts Erlang modules that export schema_schema/0 to $ref" do
      # This is not an Elixir module, so we cannot know if it's a custom type, format, etc.
      defmodule unquote(:test_schema_module_to_ref_with_schema) do
        @spec schema :: no_return()
        def schema do
          raise "will not be called"
        end
      end

      # Since we can find the function it's a $ref
      assert %{"$ref" => Internal.module_to_uri(:test_schema_module_to_ref_with_schema)} ==
               Schema.normalize(:test_schema_module_to_ref_with_schema)
    end

    defmodule NormalizeTo do
      defstruct [:value]
    end

    defimpl JSV.Normalizer.Normalize, for: NormalizeTo do
      def normalize(%{value: value}) do
        value
      end
    end

    test "can replace struct with non-map values" do
      assert "hello" = Schema.normalize(%NormalizeTo{value: "hello"})
      assert [1, 2, "hello"] = Schema.normalize(%NormalizeTo{value: [1, 2, :hello]})

      assert %{"some_key" => "some_val"} =
               Schema.normalize(%NormalizeTo{
                 value: %{some_key: %NormalizeTo{value: :some_val}}
               })

      # It is not supported to use struct as keys (yet?) because maps are not
      # re-normalized when the traverse function operates on a {:struct, _, _}
      # tuple. When the normalizer implementation for a struct returns a map,
      # the keys must be correctly encoded.
      assert_raise ArgumentError, ~r"invalid key", fn ->
        Schema.normalize(%{%NormalizeTo{value: :some_key} => %NormalizeTo{value: :some_val}})
      end

      assert [1, 2, %{"k" => [%{"k2" => "sub"}]}] =
               Schema.normalize([
                 %NormalizeTo{value: 1},
                 %NormalizeTo{value: 2},
                 %NormalizeTo{
                   value: %{
                     k: %NormalizeTo{
                       value: [
                         %NormalizeTo{
                           value: %{
                             k2: %NormalizeTo{value: :sub}
                           }
                         }
                       ]
                     }
                   }
                 }
               ])

      # Tuples are not supported by the Schema normalizer but the general
      # normalizer does accept them
      assert_raise ArgumentError, ~r"invalid value in JSON data", fn ->
        Schema.normalize(%NormalizeTo{value: {1, 2, :hello}})
      end

      # Returning a struct is invalid
      assert_raise ArgumentError, ~r"continuation function does not accept structs", fn ->
        Schema.normalize(%NormalizeTo{value: %MyStruct{}})
      end
    end
  end

  describe "self contained normalization" do
    # self contained normalization means that we will return a schema that
    # contains definitions for all nested module-based schemas instead of just
    # transforming them into a reference for the internal resolver

    defmodule NoNestedSchema do
      use JSV.Schema

      defschema name: string(), age: integer()
    end

    defmodule NestedChild do
      use JSV.Schema

      defschema name: string(), age: integer()
    end

    defmodule NestedParent do
      use JSV.Schema

      defschema user: NestedChild, role: enum(["admin", "user"])
    end

    defmodule NestedSelf do
      use JSV.Schema

      defschema sub: optional(__MODULE__), level: integer()
    end

    defmodule NestedMutualA do
      use JSV.Schema
      alias JSV.NormalizerTest.NestedMutualB

      defschema sub: NestedMutualB, a: string()
    end

    defmodule NestedMutualB do
      use JSV.Schema

      defschema sub: optional(NestedMutualA), b: string()
    end

    defmodule WithCommonTitleUser do
      use JSV.Schema

      defschema %{
        type: :object,
        title: "Common",
        properties: %{
          name: string(),
          age: integer()
        },
        required: [:name]
      }
    end

    defmodule WithCommonTitleOrga do
      use JSV.Schema

      defschema %{
        type: :object,
        title: "Common",
        properties: %{
          url: string(),
          size: integer()
        },
        required: [:url]
      }
    end

    defmodule CommonTitlesParent do
      use JSV.Schema

      defschema user: WithCommonTitleUser, orga: WithCommonTitleOrga
    end

    # With the following schemas:
    #
    #     - ParentWithId
    #     \-- ChildWithoutId
    #        \-- GrandChildWithoutId
    #
    # As we use "#/" prefix for refs, it will always search from the root so it
    # works.

    defmodule GrandChildWithoutId do
      use JSV.Schema

      defschema grandchildname: string()
    end

    defmodule ChildWithoutId do
      use JSV.Schema

      defschema childname: string(), grandchild: GrandChildWithoutId
    end

    defmodule ParentWithId do
      use JSV.Schema

      defschema %{
        type: :object,
        id: "some://id",
        properties: %{
          child: ChildWithoutId,
          parentname: string()
        },
        required: [:child, :parentname]
      }
    end

    # This schema does not use an $id, and for now the nested $defs are not
    # merged in the root result of normalize_collect, so this schema will not
    # be buildable when collected.
    defmodule NaiveWithDefs do
      use JSV.Schema

      defschema %{
        type: :object,
        "$defs": %{
          "language" => enum(["Elixir", "Erlang"])
        },
        properties: %{
          name: string(),
          language: ref("#/language")
        },
        required: [:name, :language]
      }
    end

    # This schema defines a $id and can use refs to its own definitions
    defmodule IDWithDefs do
      use JSV.Schema

      defschema %{
        type: :object,
        "$id": "test://idwithrefs",
        "$defs": %{
          "language" => enum(["Elixir", "Erlang"])
        },
        properties: %{
          name: string(),
          language: ref("test://idwithrefs#/$defs/language")
        },
        required: [:name, :language]
      }
    end

    defmodule ListNesting do
      use JSV.Schema

      defschema foo: string(), subs: array_of(one_of([NestedParent, NestedMutualA]))
    end

    test "no nested schema" do
      # instead of returning a ref, if the top schema is module-based it is
      # returned directly

      schema = Schema.normalize_collect(NoNestedSchema)

      assert %{
               "$defs" => %{
                 "NoNestedSchema" => %{
                   "title" => "NoNestedSchema",
                   "type" => "object",
                   "properties" => %{
                     "age" => %{"type" => "integer"},
                     "name" => %{"type" => "string"}
                   },
                   "required" => ["name", "age"],
                   "jsv-cast" => ["Elixir.JSV.NormalizerTest.NoNestedSchema", 0]
                 }
               },
               "$ref" => "#/$defs/NoNestedSchema"
             } == schema

      root = JSV.build!(schema)
      assert %NoNestedSchema{age: 123, name: "alice"} = JSV.validate!(%{"age" => 123, "name" => "alice"}, root)
    end

    test "wrapped into a raw schema" do
      schema = Schema.normalize_collect(%{properties: %{foo: NoNestedSchema}})

      assert %{
               "$defs" => %{
                 "NoNestedSchema" => %{
                   "title" => "NoNestedSchema",
                   "type" => "object",
                   "properties" => %{
                     "age" => %{"type" => "integer"},
                     "name" => %{"type" => "string"}
                   },
                   "required" => ["name", "age"],
                   "jsv-cast" => ["Elixir.JSV.NormalizerTest.NoNestedSchema", 0]
                 }
               },
               "properties" => %{"foo" => %{"$ref" => "#/$defs/NoNestedSchema"}}
             } == schema

      root = JSV.build!(schema)

      assert %{"foo" => %NoNestedSchema{age: 123, name: "alice"}} =
               JSV.validate!(%{"foo" => %{"age" => 123, "name" => "alice"}}, root)
    end

    test "nested module schema" do
      schema = Schema.normalize_collect(%{properties: %{foo: NestedParent}})

      assert %{
               "$defs" => %{
                 "NestedChild" => %{
                   "jsv-cast" => ["Elixir.JSV.NormalizerTest.NestedChild", 0],
                   "properties" => %{
                     "age" => %{"type" => "integer"},
                     "name" => %{"type" => "string"}
                   },
                   "required" => ["name", "age"],
                   "title" => "NestedChild",
                   "type" => "object"
                 },
                 "NestedParent" => %{
                   "jsv-cast" => ["Elixir.JSV.NormalizerTest.NestedParent", 0],
                   "properties" => %{
                     "role" => %{"enum" => ["admin", "user"]},
                     "user" => %{"$ref" => "#/$defs/NestedChild"}
                   },
                   "required" => ["user", "role"],
                   "title" => "NestedParent",
                   "type" => "object"
                 }
               },
               "properties" => %{"foo" => %{"$ref" => "#/$defs/NestedParent"}}
             } == schema

      root = JSV.build!(schema)

      assert %{
               "foo" => %NestedParent{
                 role: "admin",
                 user: %NestedChild{age: 123, name: "alice"}
               }
             } =
               JSV.validate!(%{"foo" => %{"user" => %{"age" => 123, "name" => "alice"}, "role" => "admin"}}, root)
    end

    test "self nested module schema" do
      schema = Schema.normalize_collect(NestedSelf)

      assert %{
               "$defs" => %{
                 "NestedSelf" => %{
                   "jsv-cast" => ["Elixir.JSV.NormalizerTest.NestedSelf", 0],
                   "properties" => %{
                     "level" => %{"type" => "integer"},
                     "sub" => %{"$ref" => "#/$defs/NestedSelf"}
                   },
                   "required" => ["level"],
                   "title" => "NestedSelf",
                   "type" => "object"
                 }
               },
               "$ref" => "#/$defs/NestedSelf"
             } == schema

      root = JSV.build!(schema)

      assert %NestedSelf{level: 0, sub: nil} = JSV.validate!(%{"level" => 0}, root)

      assert %NestedSelf{level: 0, sub: %NestedSelf{level: 1, sub: nil}} =
               JSV.validate!(%{"level" => 0, "sub" => %{"level" => 1}}, root)

      assert %NestedSelf{level: 0, sub: %NestedSelf{level: 1, sub: %NestedSelf{level: 2, sub: nil}}} =
               JSV.validate!(%{"level" => 0, "sub" => %{"level" => 1, "sub" => %{"level" => 2}}}, root)
    end

    test "mutually recursive schemas" do
      schema = Schema.normalize_collect(NestedMutualA)

      assert %{
               "$defs" => %{
                 "NestedMutualA" => %{
                   "jsv-cast" => ["Elixir.JSV.NormalizerTest.NestedMutualA", 0],
                   "properties" => %{
                     "a" => %{"type" => "string"},
                     "sub" => %{"$ref" => "#/$defs/NestedMutualB"}
                   },
                   "required" => ["sub", "a"],
                   "title" => "NestedMutualA",
                   "type" => "object"
                 },
                 "NestedMutualB" => %{
                   "jsv-cast" => ["Elixir.JSV.NormalizerTest.NestedMutualB", 0],
                   "properties" => %{
                     "b" => %{"type" => "string"},
                     "sub" => %{"$ref" => "#/$defs/NestedMutualA"}
                   },
                   "required" => ["b"],
                   "title" => "NestedMutualB",
                   "type" => "object"
                 }
               },
               "$ref" => "#/$defs/NestedMutualA"
             } == schema

      root = JSV.build!(schema)

      data = %{
        "a" => "hello",
        "sub" => %{
          "b" => "world",
          "sub" => %{
            "a" => "how are",
            "sub" => %{"b" => "you?"}
          }
        }
      }

      assert %NestedMutualA{
               a: "hello",
               sub: %NestedMutualB{
                 b: "world",
                 sub: %NestedMutualA{
                   a: "how are",
                   sub: %NestedMutualB{b: "you?", sub: nil}
                 }
               }
             } = JSV.validate!(data, root)
    end

    test "schemas with same title" do
      schema = Schema.normalize_collect(CommonTitlesParent)

      # Traverse.postwalk is deterministic with map order, and "orga"<"user" so
      # the "Common" ref is taken by the Orga schema

      assert %{
               "$defs" => %{
                 "CommonTitlesParent" => %{
                   "jsv-cast" => ["Elixir.JSV.NormalizerTest.CommonTitlesParent", 0],
                   "properties" => %{
                     "orga" => %{"$ref" => "#/$defs/Common"},
                     "user" => %{"$ref" => "#/$defs/Common_1"}
                   },
                   "required" => ["user", "orga"],
                   "title" => "CommonTitlesParent",
                   "type" => "object"
                 },
                 "Common" => %{
                   "jsv-cast" => ["Elixir.JSV.NormalizerTest.WithCommonTitleOrga", 0],
                   "properties" => %{
                     "size" => %{"type" => "integer"},
                     "url" => %{"type" => "string"}
                   },
                   "required" => ["url"],
                   "title" => "Common",
                   "type" => "object"
                 },
                 "Common_1" => %{
                   "jsv-cast" => ["Elixir.JSV.NormalizerTest.WithCommonTitleUser", 0],
                   "properties" => %{
                     "age" => %{"type" => "integer"},
                     "name" => %{"type" => "string"}
                   },
                   "required" => ["name"],
                   "title" => "Common",
                   "type" => "object"
                 }
               },
               "$ref" => "#/$defs/CommonTitlesParent"
             } = schema

      root = JSV.build!(schema)

      data = %{
        "user" => %{"name" => "alice", "age" => 123},
        "orga" => %{"url" => "https://example.com", "size" => 456}
      }

      assert %CommonTitlesParent{
               orga: %WithCommonTitleOrga{size: 456, url: "https://example.com"},
               user: %WithCommonTitleUser{age: 123, name: "alice"}
             } = JSV.validate!(data, root)
    end

    test "references work from schemas using $id" do
      schema = Schema.normalize_collect(ParentWithId)

      assert %{
               "$defs" => %{
                 "ChildWithoutId" => %{
                   "jsv-cast" => ["Elixir.JSV.NormalizerTest.ChildWithoutId", 0],
                   "properties" => %{
                     "grandchild" => %{"$ref" => "#/$defs/GrandChildWithoutId"},
                     "childname" => %{"type" => "string"}
                   },
                   "required" => ["childname", "grandchild"],
                   "title" => "ChildWithoutId",
                   "type" => "object"
                 },
                 "JSV.NormalizerTest.ParentWithId" => %{
                   "id" => "some://id",
                   "jsv-cast" => ["Elixir.JSV.NormalizerTest.ParentWithId", 0],
                   "properties" => %{
                     "child" => %{"$ref" => "#/$defs/ChildWithoutId"},
                     "parentname" => %{"type" => "string"}
                   },
                   "required" => ["child", "parentname"],
                   "type" => "object"
                 },
                 "GrandChildWithoutId" => %{
                   "jsv-cast" => ["Elixir.JSV.NormalizerTest.GrandChildWithoutId", 0],
                   "properties" => %{"grandchildname" => %{"type" => "string"}},
                   "required" => ["grandchildname"],
                   "title" => "GrandChildWithoutId",
                   "type" => "object"
                 }
               },
               "$ref" => "#/$defs/JSV.NormalizerTest.ParentWithId"
             } = schema

      root = JSV.build!(schema)

      data = %{
        "parentname" => "A",
        "child" => %{
          "childname" => "B",
          "grandchild" => %{
            "grandchildname" => "C"
          }
        }
      }

      assert %ParentWithId{
               child: %ChildWithoutId{
                 childname: "B",
                 grandchild: %GrandChildWithoutId{grandchildname: "C"}
               },
               parentname: "A"
             } = JSV.validate!(data, root)
    end

    test "naive schema with $defs" do
      schema = Schema.normalize_collect(NaiveWithDefs)

      assert %{
               "$defs" => %{
                 "JSV.NormalizerTest.NaiveWithDefs" => %{
                   # pre-existing $defs are not extracted
                   "$defs" => %{"language" => %{"enum" => ["Elixir", "Erlang"]}},
                   "jsv-cast" => ["Elixir.JSV.NormalizerTest.NaiveWithDefs", 0],
                   "properties" => %{
                     "language" => %{"$ref" => "#/language"},
                     "name" => %{"type" => "string"}
                   },
                   "required" => ["name", "language"],
                   "type" => "object"
                 }
               },
               "$ref" => "#/$defs/JSV.NormalizerTest.NaiveWithDefs"
             } = schema

      assert {:error, e} = JSV.build(schema)

      assert "could not build JSON schema at #/$defs/JSV.NormalizerTest.NaiveWithDefs/properties/language" <> _ =
               Exception.message(e)

      assert {:invalid_docpath, ["language"], _, {:pointer_error, "language", _}} = e.reason
    end

    test "using $id for nested refs" do
      schema = Schema.normalize_collect(IDWithDefs)

      assert %{
               "$defs" => %{
                 "JSV.NormalizerTest.IDWithDefs" => %{
                   "$defs" => %{"language" => %{"enum" => ["Elixir", "Erlang"]}},
                   "jsv-cast" => ["Elixir.JSV.NormalizerTest.IDWithDefs", 0],
                   "properties" => %{
                     "language" => %{"$ref" => "test://idwithrefs#/$defs/language"},
                     "name" => %{"type" => "string"}
                   },
                   "required" => ["name", "language"],
                   "type" => "object",
                   "$id" => "test://idwithrefs"
                 }
               },
               "$ref" => "#/$defs/JSV.NormalizerTest.IDWithDefs"
             } = schema

      root = JSV.build!(schema)

      data = %{"name" => "Joe", "language" => "Erlang"}

      assert %IDWithDefs{language: "Erlang", name: "Joe"} = JSV.validate!(data, root)
    end

    test "supports normalization of atoms" do
      # Since we support module, we must support atoms
      assert false == Schema.normalize_collect(false)
      assert nil == Schema.normalize_collect(nil)
      assert "nope" == Schema.normalize_collect(:nope)
      assert "Elixir.NotAModule" == Schema.normalize_collect(NotAModule)
    end

    test "supports schemas in lists" do
      schema = Schema.normalize_collect(ListNesting)

      assert %{
               "$defs" => %{
                 "NestedChild" => %{
                   "jsv-cast" => ["Elixir.JSV.NormalizerTest.NestedChild", 0],
                   "properties" => %{
                     "age" => %{"type" => "integer"},
                     "name" => %{"type" => "string"}
                   },
                   "required" => ["name", "age"],
                   "title" => "NestedChild",
                   "type" => "object"
                 },
                 "NestedParent" => %{
                   "jsv-cast" => ["Elixir.JSV.NormalizerTest.NestedParent", 0],
                   "properties" => %{
                     "role" => %{"enum" => ["admin", "user"]},
                     "user" => %{"$ref" => "#/$defs/NestedChild"}
                   },
                   "required" => ["user", "role"],
                   "title" => "NestedParent",
                   "type" => "object"
                 },
                 "ListNesting" => %{
                   "jsv-cast" => ["Elixir.JSV.NormalizerTest.ListNesting", 0],
                   "properties" => %{
                     "foo" => %{"type" => "string"},
                     "subs" => %{
                       "items" => %{
                         "oneOf" => [%{"$ref" => "#/$defs/NestedParent"}, %{"$ref" => "#/$defs/NestedMutualA"}]
                       },
                       "type" => "array"
                     }
                   },
                   "required" => ["foo", "subs"],
                   "title" => "ListNesting",
                   "type" => "object"
                 },
                 "NestedMutualA" => %{
                   "jsv-cast" => ["Elixir.JSV.NormalizerTest.NestedMutualA", 0],
                   "properties" => %{
                     "a" => %{"type" => "string"},
                     "sub" => %{"$ref" => "#/$defs/NestedMutualB"}
                   },
                   "required" => ["sub", "a"],
                   "title" => "NestedMutualA",
                   "type" => "object"
                 },
                 "NestedMutualB" => %{
                   "jsv-cast" => ["Elixir.JSV.NormalizerTest.NestedMutualB", 0],
                   "properties" => %{
                     "b" => %{"type" => "string"},
                     "sub" => %{"$ref" => "#/$defs/NestedMutualA"}
                   },
                   "required" => ["b"],
                   "title" => "NestedMutualB",
                   "type" => "object"
                 }
               },
               "$ref" => "#/$defs/ListNesting"
             } == schema

      root = JSV.build!(schema)

      data = %{
        "foo" => "hello",
        "subs" => [
          %{
            "a" => "hello",
            "sub" => %{
              "b" => "world",
              "sub" => %{
                "a" => "how are",
                "sub" => %{"b" => "you?"}
              }
            }
          },
          %{"user" => %{"age" => 123, "name" => "alice"}, "role" => "admin"},
          %{"user" => %{"age" => 123, "name" => "alice"}, "role" => "admin"}
        ]
      }

      assert %ListNesting{
               foo: "hello",
               subs: [
                 %NestedMutualA{
                   a: "hello",
                   sub: %NestedMutualB{
                     b: "world",
                     sub: %NestedMutualA{
                       a: "how are",
                       sub: %NestedMutualB{b: "you?", sub: nil}
                     }
                   }
                 },
                 %NestedParent{
                   role: "admin",
                   user: %NestedChild{age: 123, name: "alice"}
                 },
                 %NestedParent{
                   role: "admin",
                   user: %NestedChild{age: 123, name: "alice"}
                 }
               ]
             } =
               JSV.validate!(data, root)
    end
  end
end
