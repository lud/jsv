defmodule JSV.CustomVocabulariesTest do
  require JSV.Validator
  alias JSV.Validator
  import JSV.TestHelpers
  import Mox
  use ExUnit.Case, async: true

  setup :verify_on_exit!

  describe "custom implemenations" do
    test "can be remapped" do
      # We have a schema with the `type` keyword

      # The meta schema https://json-schema.org/draft/2020-12/schema uses
      # https://json-schema.org/draft/2020-12/vocab/validation to validate types.

      schema = %{
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        type: :integer
      }

      # We will define a vocabulary that consumes the `type` keyword but allows
      # numeric strings to be valid.

      custom =
        JSV.Vocabulary
        |> mock_for()
        |> expect(:priority, fn -> 50 end)
        |> expect(:init_validators, fn [some_opt: 123] -> :some_state end)
        # priority is 50 so very high (lower figure is is higher priority) so we
        # will be called with both keywords
        |> expect(:handle_keyword, 2, fn
          {"type", "integer"}, :some_state, builder, _schema -> {:ok, :some_new_state, builder}
          {"$schema", _}, _state, _builder, _schema -> :ignore
        end)
        |> expect(:finalize_validators, fn :some_new_state -> :some_final_state end)

      # We should be able to build

      assert {:ok, root} =
               JSV.build(schema,
                 vocabularies: %{
                   "https://json-schema.org/draft/2020-12/vocab/validation" => {custom, [some_opt: 123]}
                 }
               )

      # Now the data will be validated according to our implementation that
      # accepts numerical strings.

      expect(custom, :validate, 2, fn data, :some_final_state = _collection, context ->
        case Integer.parse(data) do
          {int, ""} -> {:ok, int, context}
          _ -> {:error, Validator.__with_error__(custom, context, :type, data, cause: :non_numerical)}
        end
      end)

      # With a numerical string everything is fine
      assert {:ok, 1234} = JSV.validate("1234", root)

      # With a non-numerical value we should have an error
      assert {:error, err} = JSV.validate("not numerical", root)

      # And our module should be called to format the error
      expect(custom, :format_error, fn :type = _kind, %{cause: :non_numerical}, "not numerical" ->
        "returned string for error"
      end)

      assert %{
               valid: false,
               details: [
                 %{
                   errors: [%{message: "returned string for error", kind: :type}],
                   valid: false
                 }
               ]
             } = JSV.normalize_error(err)
    end
  end
end
