# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule JSV.BuilderTest do
  alias JSV.Ref
  alias JSV.Schema
  alias JSV.Schema.Helpers
  import JSV.TestHelpers
  import Mox
  require JSV
  use ExUnit.Case, async: true

  setup :verify_on_exit!

  describe "resolving base meta schemas" do
    test "the default resolver can resolve draft 7" do
      raw_schema = %{"$schema" => "http://json-schema.org/draft-07/schema#", "type" => "integer"}
      assert {:ok, root} = JSV.build(raw_schema)
      assert {:ok, 1} = JSV.validate(1, root)
    end

    test "the default resolver can resolve draft 7 without trailing #" do
      raw_schema = %{"$schema" => "http://json-schema.org/draft-07/schema", "type" => "integer"}
      assert {:ok, root} = JSV.build(raw_schema)
      assert {:ok, 1} = JSV.validate(1, root)
    end

    test "the default resolver can resolve draft 2020-12" do
      raw_schema = %{"$schema" => "https://json-schema.org/draft/2020-12/schema", "type" => "integer"}
      assert {:ok, root} = JSV.build(raw_schema)
      assert {:ok, 1} = JSV.validate(1, root)
    end

    test "returns a build error" do
      raw_schema = %{
        properties: %{foo: %{properties: %{bar: %{properties: %{baz: %{type: "bad type"}}}}}}
      }

      assert {:error, err} = JSV.build(raw_schema)

      assert %{
               build_path: "#/properties/foo/properties/bar/properties/baz",
               action: {JSV.Vocabulary.V202012.Validation, :valid_type, ["bad type"]},
               reason: {:invalid_type, "bad type"}
             } = err
    end

    test "returns a build error for an invalid properties value at the root" do
      raw_schema = %{
        properties: "badmap"
      }

      assert {:error, err} = JSV.build(raw_schema)

      assert %{
               reason: {:invalid_properties, "badmap"},
               action: :properties,
               build_path: "#"
             } = err
    end

    test "returns a build error for an invalid properties value deeply nested" do
      raw_schema = %{
        properties: %{
          foo: %{
            properties: %{
              bar: %{
                properties: "badmap"
              }
            }
          }
        }
      }

      assert {:error, err} = JSV.build(raw_schema)

      assert %{
               reason: {:invalid_properties, "badmap"},
               action: :properties,
               build_path: "#/properties/foo/properties/bar"
             } = err
    end

    # TODO this should be fixed so we get the actual build path for refs
    #
    # test "returns a correct build error for resolver errors" do
    #   raw_schema = %{
    #     properties: %{foo: %{properties: %{bar: %{properties: %{baz: %{"$ref": "http://some-unknown-ref"}}}}}}
    #   }

    #   assert {:error, err} = JSV.build(raw_schema)
    #   err |> dbg()

    #   assert %{
    #            action: {JSV.Resolver, :resolve, _},
    #            build_path: "#/properties/foo/properties/bar/properties/baz/$ref"
    #          } = err
    # end
  end

  describe "formats" do
    test "unknown formats do not raise on build if formats are not enabled" do
      raw_schema = %{type: :string, format: :some_unknown_format}

      # Formats disabled, unknown format is ignored
      assert {:ok, _} = JSV.build(raw_schema)

      # Formats assertion forced, error
      assert {:error, %JSV.BuildError{reason: {:unsupported_format, "some_unknown_format"}}} =
               JSV.build(raw_schema, formats: true)
    end
  end

  describe "building multi-entrypoint schemas" do
    test "can build a schema with an deep entrypoint" do
      document = %{
        some: "stuff",
        nested: %{map: %{with: %{schema: %{type: "integer"}}}}
      }

      expected_normal = Schema.normalize(document)

      assert {:ok, ctx} = JSV.build_init([])
      assert {:ok, :root, ^expected_normal, ctx} = JSV.build_add(ctx, document)
      assert {:ok, key, ctx} = JSV.build_key(ctx, Ref.parse!("#/nested/map/with/schema", :root))
      root = JSV.to_root!(ctx, :root)

      # The root does not have a build for the root schema
      refute is_map_key(root.validators, :root)
      # And so it is not possible to validate with the root
      assert_raise ArgumentError, "validators are not defined for key :root", fn ->
        JSV.validate("foo", root)
      end

      # But we can validate with the built key
      assert {:ok, 123} = JSV.validate(123, root, key: key)

      assert {
               :error,
               %JSV.ValidationError{
                 errors: [
                   %JSV.Validator.Error{
                     kind: :type,
                     data: "not an int",
                     args: [type: :integer]
                   }
                 ]
               } = err
             } = JSV.validate("not an int", root, key: key)

      assert %{
               valid: false,
               details: [
                 %{
                   errors: [%{message: "value is not of type integer", kind: :type}],
                   valid: false,
                   instanceLocation: "#",
                   evaluationPath: "#/nested/map/with/schema",
                   schemaLocation: "#/nested/map/with/schema"
                 }
               ]
             } =
               JSV.normalize_error(err, keys: :atoms)
    end

    test "can build a document with two nested schemas" do
      document = %{
        schema_int: %{type: :integer},
        schema_str: %{type: :string}
      }

      assert {:ok, ctx} = JSV.build_init([])
      assert {:ok, :root, _, ctx} = JSV.build_add(ctx, document)
      assert {:ok, key_int, ctx} = JSV.build_key(ctx, Ref.parse!("#/schema_int", :root))
      assert {:ok, key_str, ctx} = JSV.build_key(ctx, Ref.parse!("#/schema_str", :root))
      assert {:ok, root} = JSV.to_root(ctx, :root)

      assert {:ok, 123} = JSV.validate(123, root, key: key_int)
      assert {:ok, "hello"} = JSV.validate("hello", root, key: key_str)

      assert {:error, _} = JSV.validate(123, root, key: key_str)
      assert {:error, _} = JSV.validate("hello", root, key: key_int)
    end

    test "cannot build two documents without ids" do
      schema_int = %{type: :integer}
      schema_str = %{type: :string}
      assert {:ok, ctx} = JSV.build_init([])
      assert {:ok, :root, _, ctx} = JSV.build_add(ctx, schema_int)
      assert {:error, %JSV.BuildError{reason: {:key_exists, :root}}} = JSV.build_add(ctx, schema_str)
    end

    test "can build two documents" do
      # One of the two schemas has an id so it will be added without conflict
      schema_int = %{type: :integer}
      schema_str = %{"$id": "str", type: :string}
      assert {:ok, ctx} = JSV.build_init([])
      assert {:ok, :root, _, ctx} = JSV.build_add(ctx, schema_int)
      assert {:ok, "str", _, ctx} = JSV.build_add(ctx, schema_str)

      assert {:ok, key_int, ctx} = JSV.build_key(ctx, :root)
      assert {:ok, key_str, ctx} = JSV.build_key(ctx, "str")
      assert {:ok, root} = JSV.to_root(ctx, :root)

      assert {:ok, 123} = JSV.validate(123, root, key: key_int)
      assert {:ok, "hello"} = JSV.validate("hello", root, key: key_str)

      assert {:error, e} = JSV.validate(123, root, key: key_str)

      assert %{
               valid: false,
               details: [
                 %{
                   errors: [%{message: "value is not of type string", kind: :type}],
                   valid: false,
                   instanceLocation: "#",
                   evaluationPath: "#",
                   schemaLocation: "str#"
                 }
               ]
             } = JSV.normalize_error(e, keys: :atoms)

      assert {:error, e} = JSV.validate("hello", root, key: key_int)

      assert %{
               valid: false,
               details: [
                 %{
                   errors: [%{message: "value is not of type integer", kind: :type}],
                   valid: false,
                   instanceLocation: "#",
                   evaluationPath: "#",
                   schemaLocation: "#"
                 }
               ]
             } =
               JSV.normalize_error(e, keys: :atoms)
    end

    test "nested schema can reference another schema in the document" do
      document = %{
        "schemas" => %{
          "integer" => %{
            "$id" => "#integer",
            "type" => "integer"
          },
          "array" => %{
            "$id" => "#array",
            "type" => "array",
            "items" => %{
              "$ref" => "#integer"
            }
          }
        }
      }

      assert {:ok, ctx} = JSV.build_init([])
      assert {:ok, :root, _, ctx} = JSV.build_add(ctx, document)
      assert {:ok, key_array, ctx} = JSV.build_key(ctx, Ref.parse!("#/schemas/array", :root))
      assert {:ok, root} = JSV.to_root(ctx, :root)

      # Valid array of integers
      assert {:ok, [1, 2, 3]} = JSV.validate([1, 2, 3], root, key: key_array)

      # Invalid: array with non-integers
      assert {:error, error} = JSV.validate([1, "string", 3], root, key: key_array)

      assert %{
               valid: false,
               details: [
                 %{
                   errors: [%{message: "value is not of type integer", kind: :type}],
                   valid: false,
                   instanceLocation: "#/1",
                   evaluationPath: "#/schemas/array/items/$ref",
                   schemaLocation: "#/schemas/integer"
                 },
                 %{
                   errors: [
                     %{
                       message: "item at index 1 does not validate the 'items' schema",
                       kind: :items
                     }
                   ],
                   valid: false,
                   instanceLocation: "#",
                   evaluationPath: "#/schemas/array",
                   schemaLocation: "#/schemas/array"
                 }
               ]
             } =
               JSV.normalize_error(error, keys: :atoms)
    end

    test "two different documents can reference each other recursively" do
      # First schema: person with optional address
      person_schema = %{
        "$id" => "https://example.com/person.json",
        "type" => "object",
        "properties" => %{
          "name" => %{"type" => "string"},
          "age" => %{"type" => "integer"},
          "address" => %{"$ref" => "https://example.com/address.json"}
        },
        "required" => ["name", "age"]
      }

      # Second schema: address with person reference
      address_schema = %{
        "$id" => "https://example.com/address.json",
        "type" => "object",
        "properties" => %{
          "street" => %{"type" => "string"},
          "city" => %{"type" => "string"},
          "occupant" => %{"$ref" => "https://example.com/person.json"}
        },
        "required" => ["street", "city"]
      }

      assert {:ok, ctx} = JSV.build_init([])
      assert {:ok, "https://example.com/person.json", _, ctx} = JSV.build_add(ctx, person_schema)
      assert {:ok, "https://example.com/address.json", _, ctx} = JSV.build_add(ctx, address_schema)

      assert {:ok, person_key, ctx} = JSV.build_key(ctx, "https://example.com/person.json")
      assert {:ok, address_key, ctx} = JSV.build_key(ctx, "https://example.com/address.json")

      assert {:ok, root} = JSV.to_root(ctx, "https://example.com/person.json")

      # Valid person without address
      valid_person = %{"name" => "John", "age" => 30}
      assert {:ok, ^valid_person} = JSV.validate(valid_person, root, key: person_key)

      # Valid address without occupant
      valid_address = %{"street" => "Main St", "city" => "Anytown"}
      assert {:ok, ^valid_address} = JSV.validate(valid_address, root, key: address_key)

      # Valid recursive structure (person with address with occupant)
      recursive_structure = %{
        "name" => "Alice",
        "age" => 25,
        "address" => %{
          "street" => "Oak Avenue",
          "city" => "Someville",
          "occupant" => %{
            "name" => "Bob",
            "age" => 22
          }
        }
      }

      assert {:ok, ^recursive_structure} = JSV.validate(recursive_structure, root, key: person_key)

      # Invalid person (wrong age type)
      invalid_person = %{"name" => "Bob", "age" => "thirty"}
      assert {:error, _} = JSV.validate(invalid_person, root, key: person_key)

      # Invalid nested structure (invalid address city)
      invalid_nested = %{
        "name" => "Charlie",
        "age" => 40,
        "address" => %{
          "street" => "Pine Road",
          # should be a string
          "city" => 12_345
        }
      }

      assert {:error, e} = JSV.validate(invalid_nested, root, key: person_key)

      assert %{
               valid: false,
               details: [
                 %{
                   errors: [%{message: "value is not of type string", kind: :type}],
                   valid: false,
                   instanceLocation: "#/address/city",
                   evaluationPath: "#/properties/address/$ref/properties/city",
                   schemaLocation: "https://example.com/address.json#/properties/city"
                 },
                 %{
                   errors: [
                     %{
                       message: "property 'city' did not conform to the property schema",
                       kind: :properties
                     }
                   ],
                   valid: false,
                   instanceLocation: "#/address",
                   evaluationPath: "#/properties/address/$ref",
                   schemaLocation: "https://example.com/address.json#"
                 },
                 %{
                   errors: [
                     %{
                       message: "property 'address' did not conform to the property schema",
                       kind: :properties
                     }
                   ],
                   valid: false,
                   instanceLocation: "#",
                   evaluationPath: "#",
                   schemaLocation: "https://example.com/person.json#"
                 }
               ]
             } = JSV.normalize_error(e, keys: :atoms)
    end
  end

  describe "build_key error handling" do
    test "build_key with a raw fragment string fails (use Ref.parse!/2 instead)" do
      document = %{
        "schema_int" => %{"type" => "integer"},
        "schema_str" => %{"type" => "string"}
      }

      assert {:ok, ctx} = JSV.build_init([])
      assert {:ok, :root, _, ctx} = JSV.build_add(ctx, document)

      # A raw fragment string like "#/schema_int" is treated as a namespace URL,
      # not a JSON pointer. The resolver cannot fetch it as an external URL.
      # Use Ref.parse!("#/schema_int", :root) to create a proper ref instead.
      assert {:error, %JSV.BuildError{reason: {:resolver_error, _}}} =
               JSV.build_key(ctx, "#/schema_int")
    end

    test "build_key with a non-existent pointer ref returns an error" do
      schema = %{"type" => "integer"}

      assert {:ok, ctx} = JSV.build_init([])
      assert {:ok, :root, _, ctx} = JSV.build_add(ctx, schema)

      assert {:error, %JSV.BuildError{reason: {:invalid_docpath, ["nonexistent", "path"], _, _}}} =
               JSV.build_key(ctx, Ref.parse!("#/nonexistent/path", :root))
    end

    test "build_key with an unknown schema ID string returns an error" do
      schema = %{"type" => "integer"}

      assert {:ok, ctx} = JSV.build_init([])
      assert {:ok, :root, _, ctx} = JSV.build_add(ctx, schema)

      assert {:error, %JSV.BuildError{reason: {:resolver_error, _}}} =
               JSV.build_key(ctx, "https://unknown.example.com/schema")
    end
  end

  describe "building schema arrays with empty lists" do
    test "cannot build with oneOf: []" do
      assert {:error, %JSV.BuildError{reason: :empty_schema_array, action: :oneOf}} =
               JSV.build(%{"oneOf" => []})
    end

    test "cannot build with allOf: []" do
      assert {:error, %JSV.BuildError{reason: :empty_schema_array, action: :allOf}} =
               JSV.build(%{"allOf" => []})
    end

    test "cannot build with anyOf: []" do
      assert {:error, %JSV.BuildError{reason: :empty_schema_array, action: :anyOf}} =
               JSV.build(%{"anyOf" => []})
    end
  end

  describe "build warnings" do
    defmodule WarningCaster do
      def __jsv__({:cast, ["warn" | _rest]}, builder) do
        builder = JSV.Builder.warn(builder, :first_warning, "hello")
        {{__MODULE__, :identity, 1}, builder}
      end

      def __jsv__({:cast, ["warn2" | _rest]}, builder) do
        builder = JSV.Builder.warn(builder, :second_warning, "hello")
        {{__MODULE__, :identity, 1}, builder}
      end

      def __jsv__({:cast, ["plain" | _rest]}, builder) do
        {{__MODULE__, :identity, 1}, builder}
      end

      def identity(data) do
        {:ok, data}
      end
    end

    test "warning emitted by a cast is exposed on the built Root" do
      schema = %{
        type: :string,
        "x-jsv-cast": [[to_string(WarningCaster), "warn"]]
      }

      root = JSV.build!(schema, warnings: :silent)
      assert [%{key: :first_warning, message: "hello", rev_path: [:root]}] = root.warnings
    end

    test "builder is threaded across multiple x-jsv-cast entries so warnings are preserved" do
      schema = %{
        type: :string,
        "x-jsv-cast": [
          [to_string(WarningCaster), "warn"],
          [to_string(WarningCaster), "plain"],
          [to_string(WarningCaster), "warn2"]
        ]
      }

      root = JSV.build!(schema, warnings: :silent)

      assert [
               %{key: :first_warning, message: "hello", rev_path: [:root]},
               %{key: :second_warning, message: "hello", rev_path: [:root]}
             ] = root.warnings
    end

    test "jsv cast string_to_atom emits a warning when the :atoms option is not set" do
      schema = Helpers.string_to_atom()
      root = JSV.build!(schema, warnings: :silent)

      assert [
               %{
                 key: :unsafe_atoms,
                 message: "The :atoms option was not defined" <> _,
                 rev_path: [:root]
               }
             ] = root.warnings
    end

    test "jsv cast string_enum_to_atom emits a warning when the :atoms option is not set" do
      schema = Helpers.string_enum_to_atom([:foo, :bar])
      root = JSV.build!(schema, warnings: :silent)

      assert [
               %{
                 key: :unsafe_atoms,
                 message: "The :atoms option was not defined" <> _,
                 rev_path: [:root]
               }
             ] = root.warnings
    end

    test "jsv cast string_enum_to_atom_or_nil emits a warning when the :atoms option is not set" do
      schema = Helpers.string_enum_to_atom_or_nil([:foo, :bar])
      root = JSV.build!(schema, warnings: :silent)

      assert [
               %{
                 key: :unsafe_atoms,
                 message: "The :atoms option was not defined" <> _,
                 rev_path: [:root]
               }
             ] = root.warnings
    end

    test "warnings are located" do
      schema_remote = %{
        "properties" => %{
          "bar" => %{
            "type" => "array",
            "items" => %{
              "type" => "string",
              "x-jsv-cast" => [["jsv", "string_to_atom"]]
            }
          }
        }
      }

      schema_local = %{
        "properties" => %{
          "foo" => %{"$ref" => "https://bar.com/schema"},
          "top" => %{"type" => "string", "x-jsv-cast" => [["jsv", "string_to_atom"]]}
        }
      }

      resolver =
        JSV.Resolver
        |> mock_for()
        |> stub(:resolve, fn
          "https://bar.com/schema", _opts -> {:normal, schema_remote}
          _other, _opts -> {:error, :not_found}
        end)

      root = JSV.build!(schema_local, warnings: :silent, resolver: [resolver, JSV.Resolver.Embedded])

      assert [
               %{
                 key: :unsafe_atoms,
                 message: "The :atoms option was not defined" <> _,
                 # Path (in reverse) gives the location of the problem
                 rev_path: [{:properties, "top"}, :root]
               },
               %{
                 key: :unsafe_atoms,
                 message: "The :atoms option was not defined" <> _,
                 # Path (in reverse) gives the location of the problem
                 rev_path: [:items, {:properties, "bar"}, "https://bar.com/schema"]
               }
             ] = root.warnings
    end
  end
end
