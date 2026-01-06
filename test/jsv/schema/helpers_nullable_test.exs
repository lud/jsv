defmodule JSV.Schema.HelpersNullableTest do
  alias JSV.Schema.Helpers
  use ExUnit.Case, async: true

  import JSV.Schema.Helpers

  describe "nullable/1" do
    nullable_cases = [
      nullable_string: %{
        args: [string()],
        valids: ["hello", "", nil],
        invalids: [123, true, false, %{}]
      },
      nullable_integer: %{
        args: [integer()],
        valids: [1, 42, -10, 0, nil],
        invalids: [1.5, "string", true]
      },
      nullable_boolean: %{
        args: [boolean()],
        valids: [true, false, nil],
        invalids: ["hello", 0, 1, %{}]
      },
      nullable_number: %{
        args: [number()],
        valids: [1, 1.5, -10.2, nil],
        invalids: ["string", true, []]
      },
      nullable_with_constraints: %{
        args: [integer() ~> %{minimum: 0}],
        valids: [0, 10, 100, nil],
        invalids: [-1, -10, "string"]
      },
      nullable_any_of: %{
        args: [any_of([%{minimum: 1}, %{maximum: -1}]) ~> integer()],
        valids: [5, -5, nil],
        invalids: [0]
      },
      nullable_one_of: %{
        args: [one_of([string(), integer()])],
        valids: ["hello", 42, nil],
        invalids: [true, %{}]
      }
    ]

    Enum.each(nullable_cases, fn {name, spec} ->
      test "#{name}" do
        spec = unquote(Macro.escape(spec))

        %{valids: valids, invalids: invalids} = spec
        args = Map.get(spec, :args, [])

        schema = apply(Helpers, :nullable, args)

        assert is_map(schema)
        refute is_struct(schema)

        root = JSV.build!(schema)

        Enum.each(valids, fn valid ->
          case JSV.validate(valid, root) do
            {:ok, _} ->
              :ok

            {:error, err} ->
              flunk(
                "Expected #{inspect(valid)} to be valid with nullable(#{Enum.map_join(args, ", ", &inspect/1)}), got: #{inspect(JSV.normalize_error(err), pretty: true)}"
              )
          end
        end)

        Enum.each(invalids, fn invalid ->
          case JSV.validate(invalid, root) do
            {:ok, casted} ->
              flunk("""
              Expected #{inspect(invalid)} to be invalid with nullable(#{Enum.map_join(args, ", ", &inspect/1)})

              CASTED TO
              #{inspect(casted)}

              SCHEMA
              #{inspect(schema, pretty: true)}
              """)

            {:error, validation_error} ->
              _ = JSV.normalize_error(validation_error)
              :ok
          end
        end)
      end
    end)

    test "nullable is idempotent" do
      schema = nullable(nullable(string()))
      root = JSV.build!(schema)

      assert {:ok, _} = JSV.validate(nil, root)
      assert {:ok, _} = JSV.validate("hello", root)
    end

    test "nullable preserves all schema properties" do
      schema = nullable(%{type: :integer, minimum: 0, maximum: 100, description: "A value"})

      assert schema.type == [:integer, :null]
      assert schema.minimum == 0
      assert schema.maximum == 100
      assert schema.description == "A value"
    end
  end

  describe "nullish/1" do
    # nullish returns {:__optional__, schema, opts} which is only processed by defschema
    # So we define test modules using defschema

    defmodule NullishStringSchema do
      use JSV.Schema
      defschema name: Helpers.string(), nickname: Helpers.nullish(Helpers.string())
    end

    defmodule NullishIntegerSchema do
      use JSV.Schema
      defschema value: Helpers.integer(), count: Helpers.nullish(Helpers.integer())
    end

    defmodule NullishWithConstraintsSchema do
      use JSV.Schema
      defschema name: Helpers.string(), age: Helpers.nullish(Helpers.integer() ~> %{minimum: 0})
    end

    nullish_cases = [
      nullish_string: %{
        module: NullishStringSchema,
        required_data: %{"name" => "Alice"},
        field: "nickname",
        valids: ["Ali", nil],
        invalids: [123, true]
      },
      nullish_integer: %{
        module: NullishIntegerSchema,
        required_data: %{"value" => 42},
        field: "count",
        valids: [10, 0, -5, nil],
        invalids: ["ten", true]
      },
      nullish_with_constraints: %{
        module: NullishWithConstraintsSchema,
        required_data: %{"name" => "Alice"},
        field: "age",
        valids: [0, 25, 100, nil],
        invalids: [-1, -10, "twenty"]
      }
    ]

    Enum.each(nullish_cases, fn {name, spec} ->
      test "#{name}" do
        spec = unquote(Macro.escape(spec))

        %{module: module, required_data: required_data, field: field, valids: valids, invalids: invalids} = spec

        root = JSV.build!(module)

        case JSV.validate(required_data, root) do
          {:ok, _} ->
            :ok

          {:error, err} ->
            flunk(
              "Expected #{inspect(required_data)} to be valid (#{field} should be optional), got: #{inspect(JSV.normalize_error(err), pretty: true)}"
            )
        end

        Enum.each(valids, fn valid ->
          data = Map.put(required_data, field, valid)

          case JSV.validate(data, root) do
            {:ok, _} ->
              :ok

            {:error, err} ->
              flunk("Expected #{inspect(data)} to be valid, got: #{inspect(JSV.normalize_error(err), pretty: true)}")
          end
        end)

        Enum.each(invalids, fn invalid ->
          data = Map.put(required_data, field, invalid)

          case JSV.validate(data, root) do
            {:ok, casted} ->
              flunk("""
              Expected #{inspect(data)} to be invalid

              CASTED TO
              #{inspect(casted)}
              """)

            {:error, validation_error} ->
              _ = JSV.normalize_error(validation_error)
              :ok
          end
        end)
      end
    end)
  end

  describe "nullable/1 with schema modules" do
    defmodule Position do
      use JSV.Schema

      defschema x: Helpers.integer(description: "X coordinate"),
                y: Helpers.integer(description: "Y coordinate")
    end

    defmodule Node do
      use JSV.Schema

      defschema id: Helpers.string(format: :uuid, description: "Node ID"),
                position: Helpers.nullable(Position)
    end

    test "nullable schema module accepts the schema value" do
      root = JSV.build!(Node)

      assert {:ok, _} =
               JSV.validate(
                 %{
                   "id" => "550e8400-e29b-41d4-a716-446655440000",
                   "position" => %{"x" => 10, "y" => 20}
                 },
                 root
               )
    end

    test "nullable schema module accepts null" do
      root = JSV.build!(Node)

      assert {:ok, _} =
               JSV.validate(
                 %{
                   "id" => "550e8400-e29b-41d4-a716-446655440000",
                   "position" => nil
                 },
                 root
               )
    end

    test "nullable schema module rejects invalid values" do
      root = JSV.build!(Node)

      assert {:error, _} =
               JSV.validate(
                 %{
                   "id" => "550e8400-e29b-41d4-a716-446655440000",
                   "position" => "invalid"
                 },
                 root
               )

      assert {:error, _} =
               JSV.validate(
                 %{
                   "id" => "550e8400-e29b-41d4-a716-446655440000",
                   "position" => %{"x" => 10}
                 },
                 root
               )
    end

    test "nullable returns anyOf schema for schema modules" do
      schema = Helpers.nullable(Position)

      assert %{anyOf: [%{type: :null}, Position]} = schema
    end

    test "nullish also works with schema modules" do
      defmodule NodeWithNullishPosition do
        use JSV.Schema

        defschema id: Helpers.string(format: :uuid, description: "Node ID"),
                  position: Helpers.nullish(Position)
      end

      root = JSV.build!(NodeWithNullishPosition)

      assert {:ok, _} =
               JSV.validate(
                 %{"id" => "550e8400-e29b-41d4-a716-446655440000"},
                 root
               )

      assert {:ok, _} =
               JSV.validate(
                 %{"id" => "550e8400-e29b-41d4-a716-446655440000", "position" => nil},
                 root
               )

      assert {:ok, _} =
               JSV.validate(
                 %{
                   "id" => "550e8400-e29b-41d4-a716-446655440000",
                   "position" => %{"x" => 10, "y" => 20}
                 },
                 root
               )
    end
  end

  describe "nullable vs optional vs nullish comparison" do
    defmodule OnlyOptionalSchema do
      use JSV.Schema
      defschema name: Helpers.string(), nickname: Helpers.optional(Helpers.string())
    end

    defmodule OnlyNullableSchema do
      use JSV.Schema
      defschema name: Helpers.string(), nickname: Helpers.nullable(Helpers.string())
    end

    defmodule BothNullishSchema do
      use JSV.Schema
      defschema name: Helpers.string(), nickname: Helpers.nullish(Helpers.string())
    end

    test "optional property: not required, but rejects nil when present" do
      root = JSV.build!(OnlyOptionalSchema)

      assert {:ok, _} = JSV.validate(%{"name" => "Alice"}, root)
      assert {:ok, _} = JSV.validate(%{"name" => "Alice", "nickname" => "Ali"}, root)
      assert {:error, _} = JSV.validate(%{"name" => "Alice", "nickname" => nil}, root)
    end

    test "nullable property: required, but accepts nil" do
      root = JSV.build!(OnlyNullableSchema)

      assert {:error, _} = JSV.validate(%{"name" => "Alice"}, root)
      assert {:ok, _} = JSV.validate(%{"name" => "Alice", "nickname" => nil}, root)
      assert {:ok, _} = JSV.validate(%{"name" => "Alice", "nickname" => "Ali"}, root)
    end

    test "nullish property: not required AND accepts nil" do
      root = JSV.build!(BothNullishSchema)

      assert {:ok, _} = JSV.validate(%{"name" => "Alice"}, root)
      assert {:ok, _} = JSV.validate(%{"name" => "Alice", "nickname" => nil}, root)
      assert {:ok, _} = JSV.validate(%{"name" => "Alice", "nickname" => "Ali"}, root)
    end
  end
end
