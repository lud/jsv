# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule JSV.SchemaTest do
  alias JSV.Schema
  alias JSV.Schema.Composer
  use ExUnit.Case, async: true

  doctest JSV.Schema

  describe "definition helpers" do
    fun_cases = [
      boolean: %{
        valids: [true, false],
        invalids: ["hello", 0, 1, "", nil]
      },
      integer: %{
        valids: [1, 42, -10, 2.0, -2.0, +0.0, -0.0],
        invalids: [1.5, "string", true, nil]
      },
      pos_integer: %{
        valids: [1, 2, 42, 1000, 1.0],
        invalids: [0, -1, -42, 1.5, "string", true, nil]
      },
      non_neg_integer: %{
        valids: [0, 1, 2, 42, 1000, 1.0, +0.0, -0.0],
        invalids: [-1, -42, 1.5, "string", true, nil]
      },
      neg_integer: %{
        valids: [-1, -2, -42, -1000, -1.0],
        invalids: [0, 1, 42, -1.5, "string", true, nil]
      },
      items: %{
        args: [%{type: :string}],
        valids: [["a", "b", "c"], [], "not an array", nil, 123],
        invalids: [["a", 1, true]]
      },
      array_of: %{
        args: [%{type: :string}],
        valids: [["a", "b", "c"]],
        invalids: [["a", 1, true], "not an array"]
      },
      number: %{
        valids: [1, 1.5, -10.2, -0.0],
        invalids: ["string", true, nil, [], [0]]
      },
      object: %{
        valids: [%{"key" => "value"}, %{}],
        invalids: ["string", 1, nil]
      },
      properties: %{
        args: [
          # as map
          %{prop1: %{type: :string}, prop2: %{type: :integer}}
        ],
        valids: [
          %{"prop1" => "value"},
          %{"prop2" => 123},
          %{"prop1" => "value", "prop2" => 123},
          %{},
          "not an object",
          123,
          nil
        ],
        invalids: [%{"prop1" => %{}}, %{"prop2" => %{}}]
      },
      properties_as_list: %{
        fun: :properties,
        args: [
          # as list
          [prop1: %{type: :string}, prop2: %{type: :integer}]
        ],
        valids: [
          %{"prop1" => "value"},
          %{"prop2" => 123},
          %{"prop1" => "value", "prop2" => 123},
          %{},
          "not an object",
          123,
          nil
        ],
        invalids: [%{"prop1" => %{}}, %{"prop2" => %{}}]
      },
      props: %{
        args: [%{prop1: %{type: :string}, prop2: %{type: :integer}}],
        valids: [%{"prop1" => "value"}, %{"prop2" => 123}, %{"prop1" => "value", "prop2" => 123}, %{}],
        invalids: [%{"prop1" => %{}}, %{"prop2" => %{}}, "not an object", 123, nil]
      },
      ref: %{
        args: ["#/$defs/an_int"],
        base: %{"$defs": %{an_int: %{type: :integer}}},
        valids: [1],
        invalids: ["not an int", nil]
      },
      required: %{
        args: [[:some_key]],
        valids: [%{"some_key" => 1}, "not an object", 123],
        invalids: [%{}]
      },
      required_with_existing: %{
        fun: :required,
        args: [[:some_key]],
        base: %{required: [:already_required]},
        valids: [%{"some_key" => 1, "already_required" => 1}, "not an object", 123],
        invalids: [%{}, %{"some_key" => 1}, %{"already_required" => 1}]
      },
      string: %{
        valids: ["", "1234", "hello", " "],
        invalids: [true, false, 1, %{}]
      },
      format: %{
        args: ["date"],
        valids: ["2023-05-20", "1990-01-01", 123, true, nil],
        invalids: ["20-05-2023", "2023/05/20", "2023-05-20T12:30:00Z"]
      },
      string_of: %{
        args: ["date"],
        valids: ["2023-05-20", "1990-01-01"],
        invalids: ["20-05-2023", "2023/05/20", "2023-05-20T12:30:00Z", 123, true, nil]
      },
      date: %{
        valids: ["2023-05-20", "1990-01-01"],
        invalids: ["20-05-2023", "2023/05/20", "2023-05-20T12:30:00Z", 123, true, nil]
      },
      datetime: %{
        valids: ["2023-05-20T12:30:00Z", "2023-05-20T12:30:00+02:00", "2023-05-20T12:30:00.123Z"],
        invalids: ["2023-05-20", "12:30:00", "not a datetime", 123, true, nil]
      },
      uri: %{
        valids: ["https://example.com", "http://localhost:4000", "ftp://files.example.org"],
        invalids: ["example.com", "not a uri", 123, true, nil]
      },
      uuid: %{
        valids: ["550e8400-e29b-41d4-a716-446655440000", "123e4567-e89b-12d3-a456-426614174000"],
        invalids: ["not-a-uuid", "123", "123e4567e89b12d3a456426614174000", 123, true, nil]
      },
      email: %{
        valids: ["a@[IPv6:::1]", "te~st@example.com", "~test@example.com", "test~@example.com", "te.s.t@example.com"],
        invalids: ["bad email", "2962", ".test@example.com", "test.@example.com", "te..st@example.com", 123, true, nil]
      },
      non_empty_string: %{
        valids: ["a", "hello", " "],
        invalids: ["", true, false, 1, %{}, nil]
      },
      string_to_number: %{
        valids: ["1", "42", "-10", "0", "1.5", "42.0", "-10.3", "0.0", "1e5", "1.0e-3"],
        invalids: ["one", "abc", "1a", "", nil, 1, 1.5]
      },
      string_to_boolean: %{
        valids: ["true", "false"],
        invalids: ["True", "False", "1", "0", "yes", "no", 1, 0, true, false, nil]
      },
      all_of: %{
        args: [
          [
            %{type: :integer},
            %{minimum: 1, maximum: 10}
          ]
        ],
        valids: [1, 5, 10],
        invalids: [0, 11, "string", true, nil]
      },
      any_of: %{
        args: [
          [
            %{type: :string},
            %{type: :integer, minimum: 0}
          ]
        ],
        valids: ["hello", 0, 1, 42],
        invalids: [-1, true, nil, %{}]
      },
      one_of: %{
        args: [
          [
            %{type: :integer, maximum: 5},
            %{type: :integer, minimum: 10}
          ]
        ],
        valids: [1, 3, 5, 10, 15],
        invalids: [6, 7, 8, 9, "string", true, nil]
      },
      #
      # Casting cases
      string_to_integer: %{
        valids: ["1", "42", "-10", "0"],
        invalids: ["1.5", "one", "abc", "1a", "1e5", "", nil, 123]
      },
      string_to_float: %{
        valids: ["1.5", "42.0", "-10.3", "0.0", "1e5", "1.0e-3"],
        invalids: ["one", "abc", "1a", "", nil, 1.5]
      },
      string_to_existing_atom: %{
        _existing_atoms: [:some_existing_atom, :abcabcabcabc],
        valids: ["true", "false", "nil", "some_existing_atom", "abcabcabcabc"],
        invalids: ["some_atom_that_does_not_exist", 123, true, false, :some_existing_atom, nil]
      },
      string_to_atom: %{
        valids: ["true", "false", "nil", "any_string", "hello world"],
        invalids: [123, true, false, :any_string, nil]
      },
      string_to_atom_enum: %{
        args: [_enum = [:aaa, :bbb, :ccc, nil]],
        valids: ["aaa", "bbb", "ccc", "nil"],
        invalids: ["ddd", 123, true, false, :some_existing_atom, nil, "null", :aaa, :bbb, :ccc]
      }
    ]

    Enum.each(fun_cases, fn {fun, spec} ->
      test "#{fun} utility" do
        spec = unquote(Macro.escape(spec))

        fun = Map.get(spec, :fun, unquote(fun))

        %{valids: valids, invalids: invalids} = spec
        args = Map.get(spec, :args, [])

        # If no mergeable base schema is set we call the arity-1 function
        # version to ensure that the merge is properly handled on top of a nil
        # value.
        schema =
          case Map.get(spec, :base, nil) do
            nil -> apply(Schema, fun, args)
            base -> apply(Schema, fun, [base | args])
          end

        root = JSV.build!(schema, formats: true)

        Enum.each(valids, fn valid ->
          case JSV.validate(valid, root, cast_formats: true) do
            {:ok, _} ->
              :ok

            {:error, err} ->
              flunk(
                "Expected #{inspect(valid)} to be valid with #{fun}(#{Enum.map_join(args, ", ", &inspect/1)}), got: #{inspect(JSV.normalize_error(err), pretty: true)}"
              )
          end
        end)

        Enum.each(invalids, fn invalid ->
          case JSV.validate(invalid, root, cast_formats: true) do
            {:ok, casted} ->
              flunk("""
              Expected #{inspect(invalid)} to be invalid with #{fun}(#{Enum.map_join(args, ", ", &inspect/1)})

              CASTED TO
              #{inspect(casted)}

              SCHEMA
              #{inspect(schema, pretty: true)}
              """)

            {:error, validation_error} ->
              # no error on normalization
              _ = JSV.normalize_error(validation_error)
              :ok
          end
        end)
      end
    end)

    test "guard clauses are handled by the defcompose helper - properties" do
      # The properties helper accepts maps and lists
      assert %{properties: %{a: _}} = Schema.properties(a: true)
      assert %{properties: %{a: _}} = Schema.properties(%{a: true})

      # but no other kind
      assert_raise FunctionClauseError, fn ->
        assert %{properties: %{a: _}} = Schema.properties(1)
      end
    end

    test "guard clauses are handled by the defcompose helper - props" do
      # The properties helper accepts maps and lists
      assert %{properties: %{a: _}} = Schema.props(a: true)
      assert %{properties: %{a: _}} = Schema.props(%{a: true})

      # but no other kind
      assert_raise FunctionClauseError, fn ->
        assert %{properties: %{a: _}} = Schema.props(1)
      end
    end

    test "guard clauses are handled by the defcompose helper - all_of" do
      # The all_of helper accepts lists
      assert %{allOf: [%{type: :integer}]} = Schema.all_of([%{type: :integer}])

      # but no other kind
      assert_raise FunctionClauseError, fn ->
        Schema.all_of(%{type: :integer})
      end
    end

    test "guard clauses are handled by the defcompose helper - any_of" do
      # The any_of helper accepts lists
      assert %{anyOf: [%{type: :integer}]} = Schema.any_of([%{type: :integer}])

      # but no other kind
      assert_raise FunctionClauseError, fn ->
        Schema.any_of(%{type: :integer})
      end
    end

    test "guard clauses are handled by the defcompose helper - one_of" do
      # The one_of helper accepts lists
      assert %{oneOf: [%{type: :integer}]} = Schema.one_of([%{type: :integer}])

      # but no other kind
      assert_raise FunctionClauseError, fn ->
        Schema.one_of(%{type: :integer})
      end
    end
  end

  defmodule TestCustomStruct do
    defstruct [:properties, :foo, :required]
  end

  describe "merge/2" do
    test "merge accepts nil as base and returns a Schema struct" do
      result = Schema.merge(nil, %{type: :string})
      assert %Schema{type: :string} = result
    end

    test "merge accepts a map as base and keeps it as a map" do
      base = %{foo: "bar"}
      assert %{foo: "bar", type: :string} = result = Schema.merge(base, %{type: :string})
      refute is_struct(result)
    end

    test "merge accepts a Schema struct as base" do
      base = %Schema{description: "test"}
      result = Schema.merge(base, %{type: :string})
      assert %Schema{description: "test", type: :string} = result
    end

    test "merge fails if another struct is passed and doesn't have the keys" do
      base = %TestCustomStruct{foo: "bar"}

      # the struct accept properties

      assert %TestCustomStruct{foo: "bar", properties: %{a: %{type: :integer}}} =
               Schema.merge(base, properties: %{a: %{type: :integer}})

      # the struct does not have a :type key

      assert_raise KeyError, ~r/does not accept key :type/, fn ->
        Schema.merge(base, %{type: :string})
      end
    end

    test "merge does not add unknown keys in a Schema struct" do
      assert_raise KeyError, ~r/does not accept key :foo/, fn ->
        Schema.merge(%Schema{}, %{foo: :bar})
      end
    end

    test "merge accepts a keyword list as base and returns a Schema struct" do
      base = [description: "some description"]
      result = Schema.merge(base, %{type: :string})
      assert %Schema{description: "some description", type: :string} = result
      assert is_struct(result)
    end

    # Same tests but with a defcompose generated helper

    test "compose accepts nil as base and returns a Schema struct" do
      result = Composer.string(nil)
      assert %Schema{type: :string} = result
    end

    test "compose accepts a map as base and keeps it as a map" do
      base = %{foo: "bar"}
      assert %{foo: "bar", type: :string} = result = Composer.string(base)
      refute is_struct(result)
    end

    test "compose accepts a Schema struct as base" do
      base = %Schema{description: "test"}
      result = Composer.string(base)
      assert %Schema{description: "test", type: :string} = result
    end

    test "compose fails if another struct is passed and doesn't have the keys" do
      base = %TestCustomStruct{foo: "bar"}

      # the struct accept properties

      assert %TestCustomStruct{foo: "bar", properties: %{a: %{type: :integer}}} =
               Schema.properties(base, a: %{type: :integer})

      # the struct does not have a :type key

      assert_raise KeyError, ~r/does not accept key :type/, fn ->
        Composer.string(base)
      end
    end

    test "compose accepts a keyword list as base and returns a Schema struct" do
      base = [description: "some description"]
      result = Composer.string(base)
      assert %Schema{description: "some description", type: :string} = result
      assert is_struct(result)
    end
  end

  describe "xcast/1" do
    test "single atom module is stored as a string" do
      assert %{"x-jsv-cast": "Elixir.MyApp.Cast"} = Schema.xcast(MyApp.Cast)
    end

    test "single string module is stored as-is" do
      assert %{"x-jsv-cast": "Elixir.MyApp.Cast"} = Schema.xcast("Elixir.MyApp.Cast")
    end

    test "list with atom module and atom tag normalizes to list of strings" do
      assert %{"x-jsv-cast": [["Elixir.MyApp.Cast", "a_cast_function"]]} =
               Schema.xcast([MyApp.Cast, :a_cast_function])
    end

    test "list with erlang module atom and string tag" do
      assert %{"x-jsv-cast": [["some_erlang_module", "custom_tag"]]} =
               Schema.xcast([:some_erlang_module, "custom_tag"])
    end
  end

  describe "xcast/2" do
    test "appending a second atom module to an atom-created schema" do
      assert %{"x-jsv-cast": ["Elixir.MyApp.Foo", "Elixir.MyApp.Cast"]} =
               %{} |> Schema.xcast(MyApp.Foo) |> Schema.xcast(MyApp.Cast)
    end

    test "appending a list caster to a string base" do
      assert %{"x-jsv-cast": ["Elixir.MyApp.Foo", ["Elixir.MyApp.Cast", "some_function", %{"123" => "foo"}]]} =
               %{} |> Schema.xcast(MyApp.Foo) |> Schema.xcast([MyApp.Cast, "some_function", %{123 => :foo}])
    end

    test "binary key x-jsv-cast is converted to atom key" do
      assert %{"x-jsv-cast": ["Elixir.MyApp.Foo", "Elixir.MyApp.Cast"]} =
               Schema.xcast(%{"x-jsv-cast" => "Elixir.MyApp.Foo"}, MyApp.Cast)
    end

    test "appending to an existing list base" do
      base = %{"x-jsv-cast": ["Elixir.A", "Elixir.B"]}

      assert %{"x-jsv-cast": ["Elixir.A", "Elixir.B", "Elixir.MyApp.C"]} =
               Schema.xcast(base, MyApp.C)
    end

    test "appending a list caster to an existing list base" do
      base = %{"x-jsv-cast": ["Elixir.A"]}

      assert %{"x-jsv-cast": ["Elixir.A", ["Elixir.MyApp.B", "tag"]]} =
               Schema.xcast(base, [MyApp.B, "tag"])
    end

    test "raises on mixed atom and binary x-jsv-cast keys" do
      bad_schema = %{:"x-jsv-cast" => "Elixir.A", "x-jsv-cast" => "Elixir.B"}

      assert_raise ArgumentError, ~r/mixing/, fn ->
        Schema.xcast(bad_schema, MyApp.C)
      end
    end

    test "preserves other schema keys" do
      base = %{type: :object, properties: %{name: %{type: :string}}}
      result = Schema.xcast(base, MyApp.Cast)
      assert %{type: :object, properties: %{name: %{type: :string}}, "x-jsv-cast": "Elixir.MyApp.Cast"} = result
    end

    test "works with JSV.Schema struct as base - single caster" do
      base = %Schema{type: :object, "x-jsv-cast": nil}
      # Since Schema struct always has the key (as nil), xcast/2 sees the nil
      # value. We set it explicitly to confirm behavior matches plain maps
      # without the key by using Map.delete.
      base = Map.delete(base, :"x-jsv-cast")
      result = Schema.xcast(base, MyApp.Cast)
      assert %{type: :object, "x-jsv-cast": "Elixir.MyApp.Cast"} = result
    end

    test "works with JSV.Schema struct that already has x-jsv-cast" do
      base = %Schema{type: :string, "x-jsv-cast": "Elixir.MyApp.Existing"}
      result = Schema.xcast(base, MyApp.Another)
      assert %Schema{type: :string, "x-jsv-cast": ["Elixir.MyApp.Existing", "Elixir.MyApp.Another"]} = result
    end

    test "works with JSV.Schema struct that has x-jsv-cast as list" do
      base = %Schema{type: :string, "x-jsv-cast": ["Elixir.MyApp.First"]}
      result = Schema.xcast(base, MyApp.Second)
      assert %Schema{type: :string, "x-jsv-cast": ["Elixir.MyApp.First", "Elixir.MyApp.Second"]} = result
    end

    test "works with JSV.Schema struct where x-jsv-cast is nil (not set)" do
      # x-jsv-cast is nil in the struct, should be treated as absent
      base = %Schema{type: :object}

      result = Schema.xcast(base, MyApp.Cast)
      assert %Schema{type: :object, "x-jsv-cast": "Elixir.MyApp.Cast"} = result

      result = Schema.xcast(base, [MyApp.Cast, "foo"])
      assert %Schema{type: :object, "x-jsv-cast": [["Elixir.MyApp.Cast", "foo"]]} = result
    end

    test "works with JSV.Schema struct as base - multiple casters" do
      base = %Schema{type: :object}

      result =
        base
        |> Schema.xcast(MyApp.Foo)
        |> Schema.xcast([MyApp.Bar, "tag"])

      assert %{type: :object, "x-jsv-cast": ["Elixir.MyApp.Foo", ["Elixir.MyApp.Bar", "tag"]]} = result
    end
  end
end
