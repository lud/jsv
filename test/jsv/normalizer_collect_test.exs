defmodule JSV.NormalizerCollectTest do
  alias JSV.Schema
  use ExUnit.Case, async: true

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
    alias JSV.NormalizerCollectTest.NestedMutualB

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

  describe "self contained normalization" do
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
                   "jsv-cast" => ["Elixir.JSV.NormalizerCollectTest.NoNestedSchema", 0]
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
                   "jsv-cast" => ["Elixir.JSV.NormalizerCollectTest.NoNestedSchema", 0]
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
                   "jsv-cast" => ["Elixir.JSV.NormalizerCollectTest.NestedChild", 0],
                   "properties" => %{
                     "age" => %{"type" => "integer"},
                     "name" => %{"type" => "string"}
                   },
                   "required" => ["name", "age"],
                   "title" => "NestedChild",
                   "type" => "object"
                 },
                 "NestedParent" => %{
                   "jsv-cast" => ["Elixir.JSV.NormalizerCollectTest.NestedParent", 0],
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
                   "jsv-cast" => ["Elixir.JSV.NormalizerCollectTest.NestedSelf", 0],
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
                   "jsv-cast" => ["Elixir.JSV.NormalizerCollectTest.NestedMutualA", 0],
                   "properties" => %{
                     "a" => %{"type" => "string"},
                     "sub" => %{"$ref" => "#/$defs/NestedMutualB"}
                   },
                   "required" => ["sub", "a"],
                   "title" => "NestedMutualA",
                   "type" => "object"
                 },
                 "NestedMutualB" => %{
                   "jsv-cast" => ["Elixir.JSV.NormalizerCollectTest.NestedMutualB", 0],
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
                   "jsv-cast" => ["Elixir.JSV.NormalizerCollectTest.CommonTitlesParent", 0],
                   "properties" => %{
                     "orga" => %{"$ref" => "#/$defs/Common"},
                     "user" => %{"$ref" => "#/$defs/Common_1"}
                   },
                   "required" => ["user", "orga"],
                   "title" => "CommonTitlesParent",
                   "type" => "object"
                 },
                 "Common" => %{
                   "jsv-cast" => ["Elixir.JSV.NormalizerCollectTest.WithCommonTitleOrga", 0],
                   "properties" => %{
                     "size" => %{"type" => "integer"},
                     "url" => %{"type" => "string"}
                   },
                   "required" => ["url"],
                   "title" => "Common",
                   "type" => "object"
                 },
                 "Common_1" => %{
                   "jsv-cast" => ["Elixir.JSV.NormalizerCollectTest.WithCommonTitleUser", 0],
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
                   "jsv-cast" => ["Elixir.JSV.NormalizerCollectTest.ChildWithoutId", 0],
                   "properties" => %{
                     "grandchild" => %{"$ref" => "#/$defs/GrandChildWithoutId"},
                     "childname" => %{"type" => "string"}
                   },
                   "required" => ["childname", "grandchild"],
                   "title" => "ChildWithoutId",
                   "type" => "object"
                 },
                 "JSV.NormalizerCollectTest.ParentWithId" => %{
                   "id" => "some://id",
                   "jsv-cast" => ["Elixir.JSV.NormalizerCollectTest.ParentWithId", 0],
                   "properties" => %{
                     "child" => %{"$ref" => "#/$defs/ChildWithoutId"},
                     "parentname" => %{"type" => "string"}
                   },
                   "required" => ["child", "parentname"],
                   "type" => "object"
                 },
                 "GrandChildWithoutId" => %{
                   "jsv-cast" => ["Elixir.JSV.NormalizerCollectTest.GrandChildWithoutId", 0],
                   "properties" => %{"grandchildname" => %{"type" => "string"}},
                   "required" => ["grandchildname"],
                   "title" => "GrandChildWithoutId",
                   "type" => "object"
                 }
               },
               "$ref" => "#/$defs/JSV.NormalizerCollectTest.ParentWithId"
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
                 "JSV.NormalizerCollectTest.NaiveWithDefs" => %{
                   # pre-existing $defs are not extracted
                   "$defs" => %{"language" => %{"enum" => ["Elixir", "Erlang"]}},
                   "jsv-cast" => ["Elixir.JSV.NormalizerCollectTest.NaiveWithDefs", 0],
                   "properties" => %{
                     "language" => %{"$ref" => "#/language"},
                     "name" => %{"type" => "string"}
                   },
                   "required" => ["name", "language"],
                   "type" => "object"
                 }
               },
               "$ref" => "#/$defs/JSV.NormalizerCollectTest.NaiveWithDefs"
             } = schema

      assert {:error, e} = JSV.build(schema)

      assert "could not build JSON schema at #/$defs/JSV.NormalizerCollectTest.NaiveWithDefs/properties/language" <> _ =
               Exception.message(e)

      assert {:invalid_docpath, ["language"], _, {:pointer_error, "language", _}} = e.reason
    end

    test "using $id for nested refs" do
      schema = Schema.normalize_collect(IDWithDefs)

      assert %{
               "$defs" => %{
                 "JSV.NormalizerCollectTest.IDWithDefs" => %{
                   "$defs" => %{"language" => %{"enum" => ["Elixir", "Erlang"]}},
                   "jsv-cast" => ["Elixir.JSV.NormalizerCollectTest.IDWithDefs", 0],
                   "properties" => %{
                     "language" => %{"$ref" => "test://idwithrefs#/$defs/language"},
                     "name" => %{"type" => "string"}
                   },
                   "required" => ["name", "language"],
                   "type" => "object",
                   "$id" => "test://idwithrefs"
                 }
               },
               "$ref" => "#/$defs/JSV.NormalizerCollectTest.IDWithDefs"
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
                   "jsv-cast" => ["Elixir.JSV.NormalizerCollectTest.NestedChild", 0],
                   "properties" => %{
                     "age" => %{"type" => "integer"},
                     "name" => %{"type" => "string"}
                   },
                   "required" => ["name", "age"],
                   "title" => "NestedChild",
                   "type" => "object"
                 },
                 "NestedParent" => %{
                   "jsv-cast" => ["Elixir.JSV.NormalizerCollectTest.NestedParent", 0],
                   "properties" => %{
                     "role" => %{"enum" => ["admin", "user"]},
                     "user" => %{"$ref" => "#/$defs/NestedChild"}
                   },
                   "required" => ["user", "role"],
                   "title" => "NestedParent",
                   "type" => "object"
                 },
                 "ListNesting" => %{
                   "jsv-cast" => ["Elixir.JSV.NormalizerCollectTest.ListNesting", 0],
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
                   "jsv-cast" => ["Elixir.JSV.NormalizerCollectTest.NestedMutualA", 0],
                   "properties" => %{
                     "a" => %{"type" => "string"},
                     "sub" => %{"$ref" => "#/$defs/NestedMutualB"}
                   },
                   "required" => ["sub", "a"],
                   "title" => "NestedMutualA",
                   "type" => "object"
                 },
                 "NestedMutualB" => %{
                   "jsv-cast" => ["Elixir.JSV.NormalizerCollectTest.NestedMutualB", 0],
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

  # The :as_root transforms a module-based schema as the root schema, instead of
  # making it a dependency
  describe "self contained :as_root" do
    test "wrapped into a raw schema, this will use a definition" do
      schema = Schema.normalize_collect(%{properties: %{foo: NoNestedSchema}}, as_root: true)

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
                   "jsv-cast" => ["Elixir.JSV.NormalizerCollectTest.NoNestedSchema", 0]
                 }
               },
               "properties" => %{"foo" => %{"$ref" => "#/$defs/NoNestedSchema"}}
             } == schema

      root = JSV.build!(schema)

      assert %{"foo" => %NoNestedSchema{age: 123, name: "alice"}} =
               JSV.validate!(%{"foo" => %{"age" => 123, "name" => "alice"}}, root)
    end

    test "unwrapped, the raw schema is the root" do
      schema = Schema.normalize_collect(NoNestedSchema, as_root: true)

      # Schema does not have $defs
      assert %{
               "title" => "NoNestedSchema",
               "type" => "object",
               "properties" => %{
                 "age" => %{"type" => "integer"},
                 "name" => %{"type" => "string"}
               },
               "required" => ["name", "age"],
               "jsv-cast" => ["Elixir.JSV.NormalizerCollectTest.NoNestedSchema", 0]
             } == schema

      root = JSV.build!(schema)

      assert %NoNestedSchema{age: 123, name: "alice"} = JSV.validate!(%{"age" => 123, "name" => "alice"}, root)
    end

    test "nested module schema" do
      schema = Schema.normalize_collect(NestedParent, as_root: true)

      # The parent is the root schema, the child is a $def

      assert %{
               "$defs" => %{
                 "NestedChild" => %{
                   "jsv-cast" => [
                     "Elixir.JSV.NormalizerCollectTest.NestedChild",
                     0
                   ],
                   "properties" => %{
                     "age" => %{"type" => "integer"},
                     "name" => %{"type" => "string"}
                   },
                   "required" => ["name", "age"],
                   "title" => "NestedChild",
                   "type" => "object"
                 }
               },
               "properties" => %{
                 "role" => %{"enum" => ["admin", "user"]},
                 "user" => %{"$ref" => "#/$defs/NestedChild"}
               },
               "jsv-cast" => ["Elixir.JSV.NormalizerCollectTest.NestedParent", 0],
               "required" => ["user", "role"],
               "title" => "NestedParent",
               "type" => "object"
             } == schema

      root = JSV.build!(schema)

      assert %NestedParent{
               role: "admin",
               user: %NestedChild{age: 123, name: "alice"}
             } =
               JSV.validate!(%{"user" => %{"age" => 123, "name" => "alice"}, "role" => "admin"}, root)
    end

    test "self nested module schema" do
      schema = Schema.normalize_collect(NestedSelf, as_root: true)

      # The self schema must be duplicated in the $defs

      assert %{
               "$defs" => %{
                 "NestedSelf" => %{
                   "jsv-cast" => ["Elixir.JSV.NormalizerCollectTest.NestedSelf", 0],
                   "properties" => %{
                     "level" => %{"type" => "integer"},
                     "sub" => %{"$ref" => "#/$defs/NestedSelf"}
                   },
                   "required" => ["level"],
                   "title" => "NestedSelf",
                   "type" => "object"
                 }
               },
               "jsv-cast" => ["Elixir.JSV.NormalizerCollectTest.NestedSelf", 0],
               "properties" => %{
                 "level" => %{"type" => "integer"},
                 "sub" => %{"$ref" => "#/$defs/NestedSelf"}
               },
               "required" => ["level"],
               "title" => "NestedSelf",
               "type" => "object"
             } == schema

      root = JSV.build!(schema)

      assert %NestedSelf{level: 0, sub: nil} = JSV.validate!(%{"level" => 0}, root)

      assert %NestedSelf{level: 0, sub: %NestedSelf{level: 1, sub: nil}} =
               JSV.validate!(%{"level" => 0, "sub" => %{"level" => 1}}, root)

      assert %NestedSelf{level: 0, sub: %NestedSelf{level: 1, sub: %NestedSelf{level: 2, sub: nil}}} =
               JSV.validate!(%{"level" => 0, "sub" => %{"level" => 1, "sub" => %{"level" => 2}}}, root)
    end

    test "mutually recursive schemas" do
      schema = Schema.normalize_collect(NestedMutualA, as_root: true)

      # The parent (mutual A) needs to be duplicated in the defs

      assert %{
               "$defs" => %{
                 "NestedMutualA" => %{
                   "jsv-cast" => ["Elixir.JSV.NormalizerCollectTest.NestedMutualA", 0],
                   "properties" => %{
                     "a" => %{"type" => "string"},
                     "sub" => %{"$ref" => "#/$defs/NestedMutualB"}
                   },
                   "required" => ["sub", "a"],
                   "title" => "NestedMutualA",
                   "type" => "object"
                 },
                 "NestedMutualB" => %{
                   "jsv-cast" => ["Elixir.JSV.NormalizerCollectTest.NestedMutualB", 0],
                   "properties" => %{
                     "b" => %{"type" => "string"},
                     "sub" => %{"$ref" => "#/$defs/NestedMutualA"}
                   },
                   "required" => ["b"],
                   "title" => "NestedMutualB",
                   "type" => "object"
                 }
               },
               "jsv-cast" => ["Elixir.JSV.NormalizerCollectTest.NestedMutualA", 0],
               "properties" => %{
                 "a" => %{"type" => "string"},
                 "sub" => %{"$ref" => "#/$defs/NestedMutualB"}
               },
               "required" => ["sub", "a"],
               "title" => "NestedMutualA",
               "type" => "object"
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
  end
end
