defmodule JSV.ErrorFormatter.KeywordErrorSchema do
  use JSV.Schema

  @moduledoc false

  # @kinds ~w(
  #     additionalItems additionalProperties allOf anyOf arithmetic_error boolean_schema
  #     const dependentRequired enum exclusiveMaximum exclusiveMinimum format
  #     if/else if/then items items_as_prefix maxContains maximum
  #     maxItems maxLength maxProperties minContains minimum minItems
  #     minLength minProperties multipleOf not oneOf pattern
  #     patternProperties prefixItems properties required type uniqueItems
  #   )

  defschema %{
    type: :object,
    title: "JSV:KeywordError",
    description: ~SD"""
    Represents an returned by a single keyword like `type` or `required`, or
    a combination of keywords like `if` and `else`.

    Such annotations can contain nested error units, for instance `oneOf`
    may contain errors units for all subschemas when no subschema listed in
    `oneOf` did match the input value.

    The list of possible values includes
    """,
    properties: %{
      kind:
        string(
          description: ~SD"""
          The keyword or internal operation that invalidated the data,
          like "type", or a combination like "if/else".

          Custom vocabularies can create their own kinds over the built-in ones.
          """
        ),
      message: string(description: "An error message related to the invalidating keyword"),
      details: array_of(JSV.ErrorFormatter.ValidationUnitSchema)
    },
    additionalProperties: false,
    required: [:kind, :message]
  }
end
