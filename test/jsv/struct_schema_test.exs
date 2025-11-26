defmodule JSV.StructSchemaTest do
  alias JSV.Schema
  require JSV
  use ExUnit.Case, async: true

  defmodule BasicDefine do
    JSV.defschema(%Schema{
      type: :object,
      properties: %{
        name: %{type: :string},
        age: %{type: :integer, default: 123}
      }
    })
  end

  defmodule BasicDefineRawMap do
    JSV.defschema(%Schema{
      type: :object,
      properties: %{
        name: %{type: :string},
        age: %{type: :integer, default: 123}
      }
    })
  end

  defmodule WithRequired do
    JSV.defschema(%Schema{
      type: :object,
      properties: %{
        name: %{type: :string},
        age: %{type: :integer, default: 123}
      },
      required: [:name]
    })
  end

  defmodule RefsAnother do
    JSV.defschema(%Schema{
      type: :object,
      properties: %{
        with_req: WithRequired
      },
      required: [:with_req]
    })
  end

  defmodule RecursiveA do
    JSV.defschema(%Schema{
      type: :object,
      properties: %{
        name: Schema.string(),
        sub_b: JSV.StructSchemaTest.RecursiveB
      },
      required: [:sub_b]
    })
  end

  defmodule RecursiveB do
    JSV.defschema(%Schema{
      type: :object,
      properties: %{
        name: Schema.string(),
        sub_a: RecursiveA
      },
      # Sub is not required otherwise this is infinite recursion
      required: []
    })
  end

  defmodule RecursiveSelf do
    JSV.defschema(%Schema{
      type: :object,
      properties: %{
        name: Schema.string(),
        sub_self: __MODULE__
      },
      # Sub is not required otherwise this is infinite recursion
      required: []
    })
  end

  defmodule RecursiveSelfWithCustomId do
    JSV.defschema(%Schema{
      "$id": "custom:my-custom-id",
      type: :object,
      properties: %{
        name: Schema.string(),
        sub_self: __MODULE__
      },
      # Sub is not required otherwise this is infinite recursion
      required: []
    })
  end

  defmodule NoAdditional do
    JSV.defschema(%Schema{
      type: :object,
      properties: %{
        name: %{type: :string},
        age: %{type: :integer, default: 123}
      },
      additionalProperties: false
    })
  end

  defmodule FromGenericData do
    schema = %{
      "$defs": %{
        user: %{
          type: "object",
          properties: %{
            age: %{default: 123, type: "integer"},
            name: %{type: "string"}
          }
        }
      }
    }

    # Schema should be defineable from a function call
    JSV.defschema(get_in(schema, [:"$defs", :user]))
  end

  defmodule WithKW do
    use JSV.Schema

    defschema foo: integer(),
              bar: string(default: "hello")
  end

  defmodule WithKWAllRequired do
    use JSV.Schema

    defschema name: string(),
              age: integer()
  end

  defmodule WithKWMixed do
    use JSV.Schema

    defschema id: integer(),
              name: string(default: "Anonymous"),
              active: boolean(default: true)
  end

  defmodule EmptyStruct do
    use JSV.Schema
    defschema []
  end

  # Recursive modules using property list syntax
  defmodule RecursiveAKW do
    use JSV.Schema

    defschema name: string(),
              sub_b: JSV.StructSchemaTest.RecursiveBKW
  end

  defmodule RecursiveBKW do
    use JSV.Schema

    defschema name: string(),
              sub_a: optional(RecursiveAKW)
  end

  defmodule RecursiveSelfKW do
    use JSV.Schema

    defschema name: Schema.string(),
              sub_self: optional(__MODULE__)
  end

  describe "generating modules from schemas" do
    defp call_mod(mod, data) do
      JSV.validate(data, JSV.build!(mod))
    end

    test "can define a struct with a schema" do
      assert %BasicDefine{name: nil, age: 123} == BasicDefine.__struct__()
      assert {:ok, %BasicDefine{name: "defined", age: -1}} == call_mod(BasicDefine, %{"name" => "defined", "age" => -1})
    end

    test "can define a struct with a raw atom schema" do
      assert %BasicDefineRawMap{name: nil, age: 123} == BasicDefineRawMap.__struct__()

      assert {:ok, %BasicDefineRawMap{name: "defined", age: -1}} ==
               call_mod(BasicDefineRawMap, %{"name" => "defined", "age" => -1})
    end

    test "binary keys are invalid" do
      assert_raise ArgumentError, ~r/must be defined with atom keys/, fn ->
        defmodule BasicDefineBinaryKeys do
          JSV.defschema(%{
            "type" => "object",
            "properties" => %{
              "name" => %{"type" => "string"},
              "age" => %{"type" => "integer", "default" => 123}
            }
          })
        end
      end
    end

    test "the required keys will be defined and enforced" do
      %WithRequired{} = struct!(WithRequired, name: "hello", age: 123)

      assert_raise ArgumentError, ~r/the following keys.+\[:name\]/, fn ->
        struct!(WithRequired, age: 123)
      end
    end

    test "a module can reference another module in its properties" do
      %RefsAnother{} = struct!(RefsAnother, with_req: :stuff)

      assert_raise ArgumentError, ~r/the following keys.+\[:with_req\]/, fn ->
        struct!(RefsAnother, [])
      end
    end

    test "mutually recursive modules" do
      %RecursiveA{} = struct!(RecursiveA, sub_b: :stuff)
      %RecursiveB{} = struct!(RecursiveB, sub_a: :stuff)

      assert_raise ArgumentError, ~r/the following keys.+\[:sub_b\]/, fn ->
        struct!(RecursiveA, [])
      end
    end

    test "self recursive module" do
      %RecursiveSelf{} = struct!(RecursiveSelf, sub_self: :stuff)
    end

    test "can define a struct with a schema from a quoted function call" do
      assert %FromGenericData{name: nil, age: 123} == FromGenericData.__struct__()

      assert {:ok, %FromGenericData{name: "defined", age: -1}} ==
               call_mod(FromGenericData, %{"name" => "defined", "age" => -1})
    end

    test "required keys are exported" do
      assert [:with_req] == RefsAnother.__jsv__(:required)
      assert [:sub_b] == RecursiveA.__jsv__(:required)
      assert [] == RecursiveB.__jsv__(:required)
    end
  end

  describe "building and validating schemas" do
    test "with unknown module" do
      assert {:error, %JSV.BuildError{reason: %UndefinedFunctionError{}}} = JSV.build(UnknownModule)
    end

    test "with basic schema" do
      valid_data = %{"name" => "hello"}
      invalid_data = %{"name" => "hello", "age" => "not an int"}

      # Can build the root

      assert {:ok, root} = JSV.build(BasicDefine)

      # Will reject invalid data

      assert {:error, _} = JSV.validate(invalid_data, root)

      # Casting to struct works

      assert {:ok, s} = JSV.validate(valid_data, root)
      assert is_struct(s, BasicDefine)

      # Default values are applied (not by JSV but by default structs
      # mechanisms).

      assert %BasicDefine{name: "hello", age: 123} = s

      # Disabled struct casting

      assert {:ok, ^valid_data} = JSV.validate(valid_data, root, cast: false)
    end

    test "with basic as sub schema" do
      schema = %{type: :object, properties: %{basic_define: BasicDefine}}
      valid_data = %{"basic_define" => %{"name" => "hello"}}
      invalid_data = %{"basic_define" => %{"name" => "hello", "age" => "not an int"}}

      # Can build the root

      assert {:ok, root} = JSV.build(schema)

      # Will reject invalid data

      assert {:error, _} = JSV.validate(invalid_data, root)

      # Casting to struct works
      #
      # Default values are applied (not by JSV but by default structs
      # mechanisms).

      assert {:ok, %{"basic_define" => %BasicDefine{name: "hello", age: 123}}} = JSV.validate(valid_data, root)

      # Disabled struct casting

      assert {:ok, ^valid_data} = JSV.validate(valid_data, root, cast: false)
    end

    test "with required data" do
      valid_data = %{"name" => "hello", "age" => 456}
      invalid_data = %{}

      # Can build the root

      assert {:ok, root} = JSV.build(WithRequired)

      # Will reject invalid data

      assert {:error, _} = JSV.validate(invalid_data, root)

      # Casting to struct works

      assert {:ok, s} = JSV.validate(valid_data, root)
      assert is_struct(s, WithRequired)

      # Default values are applied (not by JSV but by default structs
      # mechanisms).

      assert %WithRequired{name: "hello", age: 456} = s

      # Disabled struct casting

      assert {:ok, ^valid_data} = JSV.validate(valid_data, root, cast: false)
    end

    test "with required data as sub schema" do
      valid_data = %{"with_req" => %{"name" => "hello", "age" => 456}}
      invalid_data = %{"with_req" => %{}}

      # Can build the root

      schema = %{type: :object, properties: %{with_req: WithRequired}}
      assert {:ok, root} = JSV.build(schema)

      # Will reject invalid data

      assert {:error, _} = JSV.validate(invalid_data, root)

      # Casting to struct works
      #
      # Default values are applied (not by JSV but by default structs
      # mechanisms).

      assert {:ok, %{"with_req" => %WithRequired{name: "hello", age: 456}}} = JSV.validate(valid_data, root)

      # Disabled struct casting

      assert {:ok, ^valid_data} = JSV.validate(valid_data, root, cast: false)
    end

    test "with another module reference" do
      schema = %{properties: %{refs_another: RefsAnother}}
      valid_data = %{"refs_another" => %{"with_req" => %{"name" => "hello"}}}
      invalid_data_no_sub = %{"refs_another" => %{}}
      invalid_data_bad_sub = %{"refs_another" => %{"with_req" => %{}}}

      # Can build the root

      assert {:ok, root} = JSV.build(schema)

      # Will reject invalid data

      assert {:error, _} = JSV.validate(invalid_data_no_sub, root)
      assert {:error, _} = JSV.validate(invalid_data_bad_sub, root)

      # Validate and casts sub structs

      assert {:ok, %{"refs_another" => %RefsAnother{with_req: %WithRequired{name: "hello", age: 123}}}} =
               JSV.validate(valid_data, root)

      # Disabled struct casting

      assert {:ok, ^valid_data} = JSV.validate(valid_data, root, cast: false)
    end

    test "two recursive schemas" do
      schema = %{properties: %{top: RecursiveA}}

      valid_data = %{
        "top" => %{
          "name" => "a1",
          "sub_b" => %{
            "name" => "b1",
            "sub_a" => %{
              "name" => "a2",
              "sub_b" => %{"name" => "b2", "sub_a" => %{"name" => "a3", "sub_b" => %{"name" => "b3"}}}
            }
          }
        }
      }

      invalid_data = %{
        "top" => %{
          "name" => "a1",
          "sub_b" => %{
            "name" => "b1",
            "sub_a" => %{
              "name" => "a2",
              "sub_b" => %{"name" => "b2", "sub_a" => %{"name" => "a3", "sub_b" => "not an object"}}
            }
          }
        }
      }

      # Can build the root

      assert {:ok, root} = JSV.build(schema)

      # Will reject invalid data

      assert {:error, _} = JSV.validate(invalid_data, root)

      # Casts everything
      assert {:ok,
              %{
                "top" => %RecursiveA{
                  name: "a1",
                  sub_b: %RecursiveB{
                    name: "b1",
                    sub_a: %RecursiveA{
                      name: "a2",
                      sub_b: %RecursiveB{
                        name: "b2",
                        sub_a: %RecursiveA{name: "a3", sub_b: %RecursiveB{name: "b3", sub_a: nil}}
                      }
                    }
                  }
                }
              }} == JSV.validate(valid_data, root)
    end

    test "with recursive self" do
      valid_data = %{
        "name" => "s1",
        "sub_self" => %{
          "name" => "s2",
          "sub_self" => %{
            "name" => "s3",
            "sub_self" => %{"name" => "s4", "sub_self" => %{"name" => "s5"}}
          }
        }
      }

      invalid_data = %{
        "name" => "s1",
        "sub_self" => %{
          "name" => "s2",
          "sub_self" => %{
            "name" => "s3",
            "sub_self" => %{"name" => "s4", "sub_self" => %{"name" => 1235}}
          }
        }
      }

      # Can build the root

      assert {:ok, root} = JSV.build(RecursiveSelf)
      # There should be only one entry in the validators
      assert [:root, "jsv:module:Elixir.JSV.StructSchemaTest.RecursiveSelf"] == Enum.sort(Map.keys(root.validators))

      # Will reject invalid data

      assert {:error, _} = JSV.validate(invalid_data, root)

      # Casts everything
      assert {:ok,
              %RecursiveSelf{
                name: "s1",
                sub_self: %RecursiveSelf{
                  name: "s2",
                  sub_self: %RecursiveSelf{
                    name: "s3",
                    sub_self: %RecursiveSelf{
                      name: "s4",
                      sub_self: %RecursiveSelf{name: "s5", sub_self: nil}
                    }
                  }
                }
              }} == JSV.validate(valid_data, root)

      # Disabled struct casting

      assert {:ok, ^valid_data} = JSV.validate(valid_data, root, cast: false)
    end

    test "with recursive self as sub" do
      schema = %{properties: %{top: RecursiveSelf}}

      valid_data = %{
        "top" => %{
          "name" => "s1",
          "sub_self" => %{
            "name" => "s2",
            "sub_self" => %{
              "name" => "s3",
              "sub_self" => %{"name" => "s4", "sub_self" => %{"name" => "s5"}}
            }
          }
        }
      }

      invalid_data = %{
        "top" => %{
          "name" => "s1",
          "sub_self" => %{
            "name" => "s2",
            "sub_self" => %{
              "name" => "s3",
              "sub_self" => %{"name" => "s4", "sub_self" => %{"name" => 1235}}
            }
          }
        }
      }

      # Can build the root

      assert {:ok, root} = JSV.build(schema)

      # Will reject invalid data

      assert {:error, _} = JSV.validate(invalid_data, root)

      # Casts everything
      assert {:ok,
              %{
                "top" => %RecursiveSelf{
                  name: "s1",
                  sub_self: %RecursiveSelf{
                    name: "s2",
                    sub_self: %RecursiveSelf{
                      name: "s3",
                      sub_self: %RecursiveSelf{
                        name: "s4",
                        sub_self: %RecursiveSelf{name: "s5", sub_self: nil}
                      }
                    }
                  }
                }
              }} == JSV.validate(valid_data, root)

      # Disabled struct casting

      assert {:ok, ^valid_data} = JSV.validate(valid_data, root, cast: false)
    end

    test "additional properties" do
      valid_data = %{"name" => "hello", "some_other_prop" => "goodbye"}

      # Can build the root

      assert {:ok, root_basic} = JSV.build(BasicDefine)
      assert {:ok, root_noadd} = JSV.build(NoAdditional)

      # Module allowing addition properties will not have them in the struct
      assert {:ok, %BasicDefine{} = casted} = JSV.validate(valid_data, root_basic)
      refute is_map_key(casted, "some_other_prop")
      refute is_map_key(casted, :some_other_prop)

      # Module rejecting additional properties will return an error
      assert {:error, _} = JSV.validate(valid_data, root_noadd)

      # When casting is disabled, additional properties are present
      assert {:ok, ^valid_data} = JSV.validate(valid_data, root_basic, cast: false)
    end
  end

  describe "resolver concerns" do
    test "with recursive self with custom id" do
      # The root will contain the definition of the schema only once, with the
      # given $id.
      #
      # The external id, jsv:module:... will be present as the schema is
      # referenced like so in its $ref to self. So we should find that key too.

      assert {:ok, root} = JSV.build(RecursiveSelfWithCustomId)

      assert [RecursiveSelfWithCustomId.json_schema()."$id", "jsv:module:#{Atom.to_string(RecursiveSelfWithCustomId)}"] ==
               Enum.sort(Map.keys(root.validators))

      assert {:alias_of, RecursiveSelfWithCustomId.json_schema()."$id"} ==
               root.validators["jsv:module:#{Atom.to_string(RecursiveSelfWithCustomId)}"]
    end
  end

  describe "optional schemas" do
    test "schema can be given in oneOf" do
      schema = %{oneOf: [%{type: :null}, BasicDefine]}
      root = JSV.build!(schema)
      assert {:ok, nil} == JSV.validate(nil, root)

      assert {:ok, %BasicDefine{name: "Alice", age: 456}} ==
               JSV.validate(%{"name" => "Alice", "age" => 456}, root)
    end
  end

  describe "deserializing into another module with defschema_for" do
    defmodule OriginalStruct do
      @enforce_keys [:some_integer]
      defstruct some_integer: 100, some_bool: true, some_string: "hello"
    end

    defmodule DenormToStruct do
      JSV.defschema_for(OriginalStruct, %{
        type: :object,
        properties: %{
          # Orginal default is 100, but we override it
          some_integer: %{type: :integer, default: 1},
          # Default is :true
          some_bool: %{type: :boolean}
          # we do not declare :some_string
        }
      })
    end

    test "can deserialize to an existing struct" do
      assert {:ok, root} = JSV.build(DenormToStruct)

      # When deserializing, the declared default apply. So we will have
      # some_integer:1 by default.
      #
      # :some_bool does not declare a default, so it should use the default from
      # the original struct and not `nil`.
      #
      # Fields not declared like :some_string should have their original defaults
      # too.

      assert {:ok, %OriginalStruct{some_integer: 1, some_bool: true, some_string: "hello"}} =
               JSV.validate(%{}, root)

      # We can define the values

      assert {:ok, %OriginalStruct{some_integer: 1234, some_bool: false, some_string: "hello"}} =
               JSV.validate(%{"some_integer" => 1234, "some_bool" => false}, root)

      # We cannot pass extra keys that are defined in the struct but not in the schema
      assert {:ok, %OriginalStruct{some_string: "hello"}} =
               JSV.validate(%{"some_string" => "ignored"}, root)
    end

    test "requires the schema to correspond to the struct" do
      # The schema can be defined
      defmodule DenormToStructWithLessKeys do
        JSV.defschema_for(OriginalStruct, %{
          type: :object,
          properties: %{}
        })
      end

      # The root can be built
      assert {:ok, root} = JSV.build(DenormToStructWithLessKeys)

      # But it will fail here
      assert_raise ArgumentError, fn -> JSV.validate(%{}, root) end
    end

    test "cannot provide extra keys" do
      assert_raise ArgumentError, ~r/ does not define keys given in defschema_for\//, fn ->
        defmodule DenormToStructWithExtraKeys do
          JSV.defschema_for(OriginalStruct, %{
            type: :object,
            properties: %{
              some_unknown_key: %{}
            }
          })
        end
      end
    end
  end

  describe "defschema with property list syntax" do
    test "can define a struct with property list syntax" do
      assert %WithKW{foo: nil, bar: "hello"} == WithKW.__struct__()

      %WithKW{} = struct!(WithKW, foo: 123)

      assert_raise ArgumentError, ~r/the following keys.+\[:foo\]/, fn ->
        struct!(WithKW, bar: "world")
      end
    end

    test "exported schema has correct structure" do
      assert %{
               title: "WithKW",
               type: :object,
               properties: %{
                 foo: %{type: :integer},
                 bar: %{type: :string, default: "hello"}
               },
               required: [:foo],
               "jsv-cast": [to_string(WithKW), 0]
             } == WithKW.json_schema()
    end

    test "validation works with property list syntax" do
      valid_data = %{"foo" => 42}
      invalid_data = %{"foo" => "not an integer"}
      assert {:ok, root} = JSV.build(WithKW)
      assert {:ok, %WithKW{foo: 42, bar: "hello"}} = JSV.validate(valid_data, root)
      assert {:error, _} = JSV.validate(invalid_data, root)
    end

    test "all properties without defaults are required" do
      assert %{
               title: "WithKWAllRequired",
               type: :object,
               properties: %{
                 name: %{type: :string},
                 age: %{type: :integer}
               },
               required: [:name, :age],
               "jsv-cast": [to_string(WithKWAllRequired), 0]
             } == WithKWAllRequired.json_schema()

      assert_raise ArgumentError, ~r/the following keys.+\[:age\]/, fn ->
        struct!(WithKWAllRequired, name: "Alice")
      end

      assert_raise ArgumentError, ~r/the following keys.+\[:name\]/, fn ->
        struct!(WithKWAllRequired, age: 30)
      end

      %WithKWAllRequired{} = struct!(WithKWAllRequired, name: "Alice", age: 30)
    end

    test "mixed properties with some defaults" do
      assert %{
               title: "WithKWMixed",
               type: :object,
               properties: %{
                 id: %{type: :integer},
                 name: %{type: :string, default: "Anonymous"},
                 active: %{type: :boolean, default: true}
               },
               required: [:id],
               "jsv-cast": [to_string(WithKWMixed), 0]
             } == WithKWMixed.json_schema()

      %WithKWMixed{} = struct!(WithKWMixed, id: 1)

      assert_raise ArgumentError, ~r/the following keys.+\[:id\]/, fn ->
        struct!(WithKWMixed, name: "Alice", active: false)
      end
    end

    test "validation with mixed properties" do
      assert {:ok, root} = JSV.build(WithKWMixed)

      assert {:ok, %WithKWMixed{id: 1, name: "Anonymous", active: true}} =
               JSV.validate(%{"id" => 1}, root)

      assert {:ok, %WithKWMixed{id: 2, name: "Alice", active: false}} =
               JSV.validate(%{"id" => 2, "name" => "Alice", "active" => false}, root)

      assert {:error, _} = JSV.validate(%{"name" => "Alice"}, root)
    end

    test "empty property list creates empty struct" do
      assert %EmptyStruct{} == EmptyStruct.__struct__()

      assert %{
               title: "EmptyStruct",
               type: :object,
               properties: %{},
               required: [],
               "jsv-cast": [to_string(EmptyStruct), 0]
             } == EmptyStruct.json_schema()

      assert {:ok, root} = JSV.build(EmptyStruct)
      assert {:ok, %EmptyStruct{}} = JSV.validate(%{}, root)

      assert {:ok, %EmptyStruct{}} = JSV.validate(%{"ignored" => "value"}, root)
    end

    test "property list with non-atom keys should fail" do
      assert_raise ArgumentError, ~r/properties must be defined with atom keys/, fn ->
        defmodule BadKW do
          JSV.defschema([{"string_key", %{type: :string}}])
        end
      end
    end

    test "recursive modules with property list syntax" do
      # Test mutual recursion - recursive fields are optional
      assert %RecursiveBKW{} = b = struct!(RecursiveBKW, name: "B")
      assert %RecursiveAKW{} = struct!(RecursiveAKW, name: "A", sub_b: b)

      # Test self recursion
      assert %RecursiveSelfKW{} = struct!(RecursiveSelfKW, name: "Self")

      # Test schema generation
      assert %{
               type: :object,
               title: "RecursiveAKW",
               required: [:name, :sub_b],
               properties: %{
                 name: %{type: :string},
                 sub_b: JSV.StructSchemaTest.RecursiveBKW
               },
               "jsv-cast": ["Elixir.JSV.StructSchemaTest.RecursiveAKW", 0]
             } ==
               RecursiveAKW.json_schema()

      assert %{
               type: :object,
               title: "RecursiveBKW",
               required: [:name],
               properties: %{
                 name: %{type: :string},
                 sub_a: JSV.StructSchemaTest.RecursiveAKW
               },
               "jsv-cast": ["Elixir.JSV.StructSchemaTest.RecursiveBKW", 0]
             } ==
               RecursiveBKW.json_schema()
    end

    test "validation with recursive modules using property list syntax" do
      # Test mutual recursion validation
      valid_data_a = %{
        "name" => "A1",
        "sub_b" => %{
          "name" => "B1",
          "sub_a" => %{
            "name" => "A2",
            "sub_b" => %{"name" => "B2"}
          }
        }
      }

      assert {:ok, root_a} = JSV.build(RecursiveAKW)
      assert {:ok, result_a} = JSV.validate(valid_data_a, root_a)

      assert %RecursiveAKW{
               name: "A1",
               sub_b: %RecursiveBKW{
                 name: "B1",
                 sub_a: %RecursiveAKW{
                   name: "A2",
                   sub_b: %RecursiveBKW{name: "B2", sub_a: nil}
                 }
               }
             } = result_a

      # Test self recursion validation
      valid_data_self = %{
        "name" => "Self1",
        "sub_self" => %{
          "name" => "Self2",
          "sub_self" => %{"name" => "Self3"}
        }
      }

      assert {:ok, root_self} = JSV.build(RecursiveSelfKW)
      assert {:ok, result_self} = JSV.validate(valid_data_self, root_self)

      assert %RecursiveSelfKW{
               name: "Self1",
               sub_self: %RecursiveSelfKW{
                 name: "Self2",
                 sub_self: %RecursiveSelfKW{name: "Self3", sub_self: nil}
               }
             } = result_self

      # Test validation with disabled casting
      assert {:ok, ^valid_data_a} = JSV.validate(valid_data_a, root_a, cast: false)
      assert {:ok, ^valid_data_self} = JSV.validate(valid_data_self, root_self, cast: false)
    end
  end

  import JSV

  defschema SubMod,
    age: integer(),
    name: string(default: "alice")

  defschema SubMod.Wrapper,
            ~SD"""
            A submodule embedded in another one
            """,
            user: SubMod

  # Recursive schemas using defschema/3 syntax
  defschema RecursiveSubA,
            ~SD"""
            Recursive schema A that references B
            """,
            name: string(),
            sub_b: JSV.StructSchemaTest.RecursiveSubB

  defschema RecursiveSubB,
            ~SD"""
            Recursive schema B that references A
            """,
            name: string(),
            sub_a: optional(RecursiveSubA)

  defschema SelfRecursiveSub,
            ~SD"""
            Schema that recursively references itself
            """,
            name: string(),
            sub_self: optional(__MODULE__)

  # Test module using defschema/3 with full schema map
  defschema FullSchemaUser,
            "User defined with full schema map",
            %{
              type: :object,
              properties: %{
                id: %{type: :integer},
                name: %{type: :string, default: "Anonymous"},
                email: %{type: :string},
                active: %{type: :boolean, default: true}
              },
              required: [:id, :email],
              additionalProperties: false
            }

  describe "defschema/3 that defines modules" do
    test "module is defined as an alias when defined as a nested module" do
      assert "Elixir.#{inspect(__MODULE__)}.SubMod" == to_string(SubMod)
    end

    test "module is defined with a struct and handles defauts" do
      assert "alice" == %SubMod{age: 123}.name
    end

    test "the title and description are defined" do
      assert nil == SubMod.json_schema().description
      assert "A submodule embedded in another one" == SubMod.Wrapper.json_schema().description

      assert "SubMod" == SubMod.json_schema().title
      assert "SubMod.Wrapper" == SubMod.Wrapper.json_schema().title
    end

    test "recursive schemas using defschema/3 - mutual recursion A/B" do
      # Test struct creation
      assert %RecursiveSubA{} = struct!(RecursiveSubA, name: "A1", sub_b: %RecursiveSubB{name: "B1"})
      assert %RecursiveSubB{} = struct!(RecursiveSubB, name: "B1")

      # Test that required fields are enforced
      assert_raise ArgumentError, ~r/the following keys.+\[:name, :sub_b\]/, fn ->
        struct!(RecursiveSubA, [])
      end

      assert_raise ArgumentError, ~r/the following keys.+\[:name\]/, fn ->
        struct!(RecursiveSubB, [])
      end

      # Test schema generation
      assert %{
               type: :object,
               title: "RecursiveSubA",
               description: "Recursive schema A that references B",
               required: [:name, :sub_b],
               properties: %{
                 name: %{type: :string},
                 sub_b: RecursiveSubB
               },
               "jsv-cast": [to_string(RecursiveSubA), 0]
             } == RecursiveSubA.json_schema()

      assert %{
               type: :object,
               title: "RecursiveSubB",
               description: "Recursive schema B that references A",
               required: [:name],
               properties: %{
                 name: %{type: :string},
                 sub_a: RecursiveSubA
               },
               "jsv-cast": [to_string(RecursiveSubB), 0]
             } == RecursiveSubB.json_schema()

      # Test validation
      valid_data = %{
        "name" => "A1",
        "sub_b" => %{
          "name" => "B1",
          "sub_a" => %{
            "name" => "A2",
            "sub_b" => %{"name" => "B2"}
          }
        }
      }

      invalid_data = %{
        "name" => "A1",
        "sub_b" => %{
          "name" => "B1",
          "sub_a" => %{
            "name" => "A2",
            "sub_b" => "not an object"
          }
        }
      }

      assert {:ok, root} = JSV.build(RecursiveSubA)
      assert {:error, _} = JSV.validate(invalid_data, root)

      assert {:ok, result} = JSV.validate(valid_data, root)

      assert %RecursiveSubA{
               name: "A1",
               sub_b: %RecursiveSubB{
                 name: "B1",
                 sub_a: %RecursiveSubA{
                   name: "A2",
                   sub_b: %RecursiveSubB{name: "B2", sub_a: nil}
                 }
               }
             } = result

      # Test with casting disabled
      assert {:ok, ^valid_data} = JSV.validate(valid_data, root, cast: false)
    end

    test "recursive schemas using defschema/3 - self recursion" do
      # Test struct creation
      assert %SelfRecursiveSub{} = struct!(SelfRecursiveSub, name: "Self1")

      # Test that required fields are enforced
      assert_raise ArgumentError, ~r/the following keys.+\[:name\]/, fn ->
        struct!(SelfRecursiveSub, [])
      end

      # Test schema generation
      assert %{
               type: :object,
               title: "SelfRecursiveSub",
               description: "Schema that recursively references itself",
               required: [:name],
               properties: %{
                 name: %{type: :string},
                 sub_self: SelfRecursiveSub
               },
               "jsv-cast": [to_string(SelfRecursiveSub), 0]
             } == SelfRecursiveSub.json_schema()

      # Test validation
      valid_data = %{
        "name" => "Self1",
        "sub_self" => %{
          "name" => "Self2",
          "sub_self" => %{
            "name" => "Self3"
          }
        }
      }

      invalid_data = %{
        "name" => "Self1",
        "sub_self" => %{
          # Should be string
          "name" => 123
        }
      }

      assert {:ok, root} = JSV.build(SelfRecursiveSub)

      # Test that there's only one entry in validators for self-recursion
      # (should be similar to the other self-recursive test)
      assert [:root, "jsv:module:Elixir.JSV.StructSchemaTest.SelfRecursiveSub"] == Enum.sort(Map.keys(root.validators))

      assert {:error, _} = JSV.validate(invalid_data, root)
      assert {:ok, result} = JSV.validate(valid_data, root)

      assert %SelfRecursiveSub{
               name: "Self1",
               sub_self: %SelfRecursiveSub{
                 name: "Self2",
                 sub_self: %SelfRecursiveSub{
                   name: "Self3",
                   sub_self: nil
                 }
               }
             } = result

      # Test with casting disabled
      assert {:ok, ^valid_data} = JSV.validate(valid_data, root, cast: false)
    end

    test "recursive schemas as sub-schemas in other structures" do
      # Test using recursive schemas as properties in other schemas
      wrapper_schema = %{
        type: :object,
        properties: %{
          recursive_a: RecursiveSubA,
          recursive_self: SelfRecursiveSub
        }
      }

      valid_data = %{
        "recursive_a" => %{
          "name" => "A1",
          "sub_b" => %{"name" => "B1"}
        },
        "recursive_self" => %{
          "name" => "Self1",
          "sub_self" => %{"name" => "Self2"}
        }
      }

      assert {:ok, root} = JSV.build(wrapper_schema)
      assert {:ok, result} = JSV.validate(valid_data, root)

      assert %{
               "recursive_a" => %RecursiveSubA{
                 name: "A1",
                 sub_b: %RecursiveSubB{name: "B1", sub_a: nil}
               },
               "recursive_self" => %SelfRecursiveSub{
                 name: "Self1",
                 sub_self: %SelfRecursiveSub{name: "Self2", sub_self: nil}
               }
             } = result

      # Test with casting disabled
      assert {:ok, ^valid_data} = JSV.validate(valid_data, root, cast: false)
    end

    test "defschema/3 with full schema map instead of property list" do
      # Test that the module was created properly with full schema map
      assert %FullSchemaUser{} = struct!(FullSchemaUser, id: 1, email: "test@example.com")

      # Test defaults are applied
      assert %JSV.StructSchemaTest.FullSchemaUser{
               active: true,
               id: 1,
               name: "Anonymous",
               email: "test@example.com"
             } == %FullSchemaUser{id: 1, email: "test@example.com"}

      # Test that required fields are enforced
      assert_raise ArgumentError, ~r/the following keys.+\[:id, :email\]/, fn ->
        struct!(FullSchemaUser, [])
      end

      assert_raise ArgumentError, ~r/the following keys.+\[:email\]/, fn ->
        struct!(FullSchemaUser, id: 1)
      end

      assert %{
               type: :object,
               properties: %{
                 active: %{default: true, type: :boolean},
                 id: %{type: :integer},
                 name: %{default: "Anonymous", type: :string},
                 email: %{type: :string}
               },
               additionalProperties: false,
               required: [:id, :email],
               "jsv-cast": ["Elixir.JSV.StructSchemaTest.FullSchemaUser", 0]
             } == FullSchemaUser.json_schema()

      valid_data = %{"id" => 123, "email" => "user@example.com"}
      invalid_data_missing_req = %{"id" => 123}
      invalid_data_extra_prop = %{"id" => 123, "email" => "user@example.com", "extra" => "value"}

      assert {:ok, root} = JSV.build(FullSchemaUser)

      assert {:ok, result} = JSV.validate(valid_data, root)
      assert %FullSchemaUser{id: 123, email: "user@example.com", name: "Anonymous", active: true} = result

      assert {:error, _} = JSV.validate(invalid_data_missing_req, root)
      assert {:error, _} = JSV.validate(invalid_data_extra_prop, root)

      assert {:ok, ^valid_data} = JSV.validate(valid_data, root, cast: false)
    end

    test "modules created this way automatically derive JSON encoders - libraries" do
      data = %RecursiveSubA{name: "hello", sub_b: %RecursiveSubB{name: "world"}}

      assert is_binary(Jason.encode!(data))
      assert is_binary(Poison.encode!(data))
    end

    if {:module, JSON} == Code.ensure_compiled(JSON) do
      test "modules created this way automatically derive JSON encoders - native codec" do
        data = %RecursiveSubA{name: "hello", sub_b: %RecursiveSubB{name: "world"}}

        assert is_binary(JSON.encode!(data))
      end
    end
  end

  describe "defschema with additional properties" do
    defmodule WithAdditionals do
      use JSV.Schema

      @additional_properties :ext
      defschema %{type: :object, additionalProperties: string(), properties: %{name: string()}}
    end

    test "single additional properties" do
      assert {:ok, root} = JSV.build(WithAdditionals)
      assert {:ok, %WithAdditionals{name: "alice", ext: %{}}} = JSV.validate(%{"name" => "alice"}, root)

      assert {:ok, %WithAdditionals{name: "alice", ext: %{"foo" => "bar"}}} =
               JSV.validate(%{"name" => "alice", "foo" => "bar"}, root)
    end

    test "multiple additional properties" do
      assert {:ok, root} = JSV.build(WithAdditionals)

      assert {:ok, %WithAdditionals{name: "alice", ext: %{"bar" => "bar", "foo" => "foo"}}} =
               JSV.validate(%{"foo" => "foo", "bar" => "bar", "name" => "alice"}, root)
    end
  end

  describe "defschema with skip keys" do
    defmodule WithSkip do
      use JSV.Schema

      @skip_keys [:some_const]
      defschema %{type: :object, properties: %{name: string(), some_const: const("foo")}}
    end

    test "@skip_keys keys are not defined in the struct" do
      assert [%{default: nil, field: :name}] = WithSkip.__info__(:struct)
    end

    test "valid keys are not defined in the struct (as the field does not exist)" do
      assert {:ok, root} = JSV.build(WithSkip)

      # without the skipped key
      assert {:ok, %WithSkip{name: "alice"}} == JSV.validate(%{"name" => "alice"}, root)

      # with the skipped key
      assert {:ok, %WithSkip{name: "alice"}} == JSV.validate(%{"name" => "alice", "some_const" => "foo"}, root)
    end

    test "invalid keys are still validated" do
      assert {:ok, root} = JSV.build(WithSkip)

      assert {
               :error,
               %JSV.ValidationError{
                 errors: [
                   %JSV.Validator.Error{
                     kind: :properties,
                     args: [key: "some_const"]
                   },
                   %JSV.Validator.Error{
                     kind: :const
                   }
                 ]
               }
             } = JSV.validate(%{"name" => "alice", "some_const" => "not_foo"}, root)
    end

    defmodule WithSkipRequired do
      use JSV.Schema

      @skip_keys [:some_const]
      defschema %{type: :object, properties: %{name: string(), some_const: const("foo")}, required: [:some_const]}
    end

    test "required keys can be skipped" do
      assert {:ok, root} = JSV.build(WithSkipRequired)

      # without the required skipped key, it is an error
      assert {
               :error,
               %JSV.ValidationError{
                 errors: [
                   %JSV.Validator.Error{
                     args: [required: ["some_const"]],
                     kind: :required,
                     data: %{"name" => "alice"}
                   }
                 ]
               }
             } = JSV.validate(%{"name" => "alice"}, root)

      # with the skipped key
      assert {:ok, %WithSkipRequired{name: "alice"}} == JSV.validate(%{"name" => "alice", "some_const" => "foo"}, root)

      # with an invalid skipped, error
      assert {
               :error,
               %JSV.ValidationError{
                 errors: [
                   %JSV.Validator.Error{
                     kind: :properties,
                     args: [key: "some_const"]
                   },
                   %JSV.Validator.Error{
                     kind: :const
                   }
                 ]
               }
             } = JSV.validate(%{"name" => "alice", "some_const" => "not_foo"}, root)
    end

    defmodule WithSkipKV do
      use JSV.Schema

      @skip_keys [:some_const]
      defschema name: string(), some_const: const("foo")
    end

    test "(kv schema) @skip_keys keys are not defined in the struct" do
      # K/V schemas are always required by default

      assert {:ok, root} = JSV.build(WithSkipKV)

      # without the required skipped key, it is an error
      assert {
               :error,
               %JSV.ValidationError{
                 errors: [
                   %JSV.Validator.Error{
                     args: [required: ["some_const"]],
                     kind: :required,
                     data: %{"name" => "alice"}
                   }
                 ]
               }
             } = JSV.validate(%{"name" => "alice"}, root)

      # with the skipped key
      assert {:ok, %WithSkipKV{name: "alice"}} == JSV.validate(%{"name" => "alice", "some_const" => "foo"}, root)

      # with an invalid skipped, error
      assert {
               :error,
               %JSV.ValidationError{
                 errors: [
                   %JSV.Validator.Error{
                     kind: :properties,
                     args: [key: "some_const"]
                   },
                   %JSV.Validator.Error{
                     kind: :const
                   }
                 ]
               }
             } = JSV.validate(%{"name" => "alice", "some_const" => "not_foo"}, root)
    end

    defmodule WithSkipKVOpt do
      use JSV.Schema

      @skip_keys [:some_const]
      defschema name: string(), some_const: optional(const("foo"))
    end

    test "(kv schema with optional) @skip_keys keys are not defined in the struct" do
      # K/V schemas are always required by default

      assert {:ok, root} = JSV.build(WithSkipKVOpt)

      # without the required skipped key, it is an error
      assert {:ok, %JSV.StructSchemaTest.WithSkipKVOpt{name: "alice"}} = JSV.validate(%{"name" => "alice"}, root)

      # with the skipped key
      assert {:ok, %WithSkipKVOpt{name: "alice"}} == JSV.validate(%{"name" => "alice", "some_const" => "foo"}, root)

      # with an invalid skipped, error
      assert {
               :error,
               %JSV.ValidationError{
                 errors: [
                   %JSV.Validator.Error{
                     kind: :properties,
                     args: [key: "some_const"]
                   },
                   %JSV.Validator.Error{
                     kind: :const
                   }
                 ]
               }
             } = JSV.validate(%{"name" => "alice", "some_const" => "not_foo"}, root)
    end
  end
end
