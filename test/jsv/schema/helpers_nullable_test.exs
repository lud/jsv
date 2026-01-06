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
  end
end
