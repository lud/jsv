defmodule JSV.Schema.HelpersTest do
  alias JSV.Schema.Helpers
  use ExUnit.Case, async: true

  doctest JSV.Schema.Helpers, import: true

  describe "presets helpers" do
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
      props_as_lists: %{
        fun: :props,
        args: [[prop1: %{type: :string}, prop2: %{type: :integer}]],
        valids: [%{"prop1" => "value"}, %{"prop2" => 123}, %{"prop1" => "value", "prop2" => 123}, %{}],
        invalids: [%{"prop1" => %{}}, %{"prop2" => %{}}, "not an object", 123, nil]
      },
      ref: %{
        args: ["#/$defs/an_int"],
        base: %{"$defs": %{an_int: %{type: :integer}}},
        valids: [1],
        invalids: ["not an int", nil]
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
      string_to_number: %{
        valids: ["1", "42", "-10", "0", "1.5", "42.0", "-10.3", "0.0", "1e5", "1.0e-3"],
        invalids: ["one", "abc", "1a", "", nil, 1, 1.5]
      },
      string_to_boolean: %{
        valids: ["true", "false"],
        invalids: ["True", "False", "1", "0", "yes", "no", 1, 0, true, false, nil]
      },
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
        valids: ["true", "false", "nil", "any_string#{:erlang.unique_integer()}", "hello world"],
        invalids: [123, true, false, :some_unexisting_atom, nil],
        post: &__MODULE__.assert_is_atom/1
      },
      const: %{
        args: [1],
        valids: [1],
        invalids: [2, :hello, "1", "HELLO", "null", :null]
      },
      enum: %{
        args: [_enum = [1, "hello", nil]],
        valids: [1, 1.0, "hello", nil],
        invalids: [2, :hello, "1", "HELLO", "null", :null]
      },
      string_enum_to_atom: %{
        # nil is encoded as "nil"
        args: [_enum = [:aaa, :bbb, :ccc, nil]],
        valids: ["aaa", "bbb", "ccc", "nil"],
        invalids: ["ddd", 123, true, false, :some_existing_atom, nil, "null", :aaa, :bbb, :ccc]
      },
      string_enum_to_atom_or_nil: %{
        # nil is encoded as "nil"
        args: [_enum = [:aaa, :bbb, :ccc]],
        valids: ["aaa", "bbb", "ccc", nil],
        invalids: ["ddd", 123, true, false, :some_existing_atom, "nil", "null", :aaa, :bbb, :ccc]
      }
    ]

    @spec assert_is_atom(term) :: boolean
    def assert_is_atom(value) do
      assert is_atom(value)
    end

    Enum.each(fun_cases, fn {fun, spec} ->
      test "#{fun} utility" do
        spec = unquote(Macro.escape(spec))

        fun = Map.get(spec, :fun, unquote(fun))

        %{valids: valids, invalids: invalids} = spec
        args = Map.get(spec, :args, [])
        post_check = Map.get(spec, :post, & &1)

        # If no mergeable base schema is set we call the arity-1 function
        # version to ensure that the merge is properly handled on top of a nil
        # value.
        schema =
          case Map.get(spec, :base, nil) do
            nil -> apply(Helpers, fun, args)
            base -> apply(Helpers, fun, args ++ [base])
          end

        assert is_map(schema)
        refute is_struct(schema)

        root = JSV.build!(schema, formats: true, atoms: true)

        Enum.each(valids, fn valid ->
          case JSV.validate(valid, root, cast_formats: true) do
            {:ok, v} ->
              post_check.(v)
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

    test "guard clauses are handled by the compiler helper - props" do
      # The properties helper accepts maps and lists
      assert %{properties: %{a: _}} = Helpers.props(a: true)
      assert %{properties: %{a: _}} = Helpers.props(%{a: true})

      # but no other kind
      assert_raise FunctionClauseError, fn ->
        assert %{properties: %{a: _}} = Helpers.props(1)
      end
    end

    test "guard clauses are handled by the compiler helper - all_of" do
      # The all_of helper accepts lists
      assert %{allOf: [%{type: :integer}]} = Helpers.all_of([%{type: :integer}])

      # but no other kind
      assert_raise FunctionClauseError, fn ->
        Helpers.all_of(%{type: :integer})
      end
    end

    test "guard clauses are handled by the compiler helper - any_of" do
      # The any_of helper accepts lists
      assert %{anyOf: [%{type: :integer}]} = Helpers.any_of([%{type: :integer}])

      # but no other kind
      assert_raise FunctionClauseError, fn ->
        Helpers.any_of(%{type: :integer})
      end
    end

    test "guard clauses are handled by the compiler helper - one_of" do
      # The one_of helper accepts lists
      assert %{oneOf: [%{type: :integer}]} = Helpers.one_of([%{type: :integer}])

      # but no other kind
      assert_raise FunctionClauseError, fn ->
        Helpers.one_of(%{type: :integer})
      end
    end
  end

  describe "the ~> operator" do
    test "mergin two schemas" do
      import Helpers

      schema =
        pos_integer(description: "old")
        ~> string_of("date", description: "new")
        ~> any_of([integer(), string()])

      assert %{
               # type and description are overriden
               type: :string,
               description: "new",

               # non-clashing values from all 3 schemas are kept
               minimum: 1,
               format: "date",
               anyOf: [%{type: :integer}, %{type: :string}]
             } = schema
    end
  end
end
