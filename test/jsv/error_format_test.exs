defmodule JSV.ErrorFormatTest do
  alias JSV
  use ExUnit.Case, async: true

  defp build_schema!(json_schema, opts \\ []) do
    {:ok, schema} = JSV.build(json_schema, [resolver: JSV.Test.TestResolver] ++ opts)
    schema
  end

  test "sample example from json-schema.org blog" do
    schema =
      build_schema!(
        Jason.decode!(~S"""
        {
          "$id": "https://example.com/polygon",
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "$defs": {
            "point": {
              "$id": "pointSchema",
              "type": "object",
              "properties": {
                "x": { "type": "number" },
                "y": { "type": "number" }
              },
              "additionalProperties": false,
              "required": [ "x", "y" ]
            }
          },
          "type": "array",
          "items": { "$ref": "#/$defs/point" },
          "prefixItems": [
          {"type": "number"}
          ],
          "minItems": 3
        }
        """)
      )

    invalid_data = [
      %{
        "x" => 2.5,
        "y" => 1.3
      },
      %{
        "x" => 1,
        "z" => 6.7
      }
    ]

    assert {:error, {:schema_validation, errors}} = JSV.validate(invalid_data, schema)
    formatted_errors = JSV.format_errors(errors)

    assert [
             %{
               valid: false,
               errors: [
                 %{kind: :minItems},
                 %{kind: :items},
                 %{kind: :prefixItems}
               ],
               schemaLocation: "",
               evaluationPath: "",
               instanceLocation: ""
             },
             %{
               valid: false,
               errors: [%{kind: :type}],
               schemaLocation: "/prefixItems/0",
               evaluationPath: "/prefixItems/0",
               instanceLocation: "/0"
             },
             %{
               valid: false,
               errors: [
                 %{kind: :required},
                 %{kind: :additionalProperties}
               ],
               schemaLocation: "https://example.com/pointSchema",
               evaluationPath: "/items/$ref",
               instanceLocation: "/1"
             },
             %{
               valid: false,
               errors: [
                 %{kind: :boolean_schema}
               ],
               schemaLocation: "https://example.com/pointSchema/additionalProperties",
               evaluationPath: "/items/$ref/additionalProperties",
               instanceLocation: "/1/z"
             }
           ] = formatted_errors
  end

  test "error formatting for none of anyOf" do
    schema =
      build_schema!(
        Jason.decode!(~S"""
        {
          "$id": "https://example.com/anyOfExample",
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "properties": {
            "foo": {
              "anyOf": [
                {"type": "number"},
                {
                  "properties": {"bar": {"type": "number"}},
                  "required": ["bar"]
                }
              ]
            }
          },
          "required": ["foo"]
        }
        """)
      )

    invalid_data = %{"foo" => %{"bar" => "baz"}}

    assert {:error, {:schema_validation, errors}} = JSV.validate(invalid_data, schema)
    formatted_errors = JSV.format_errors(errors)

    assert [
             %{
               valid: false,
               errors: [
                 %{
                   kind: :properties
                 }
               ],
               schemaLocation: "",
               evaluationPath: "",
               instanceLocation: ""
             },
             %{
               valid: false,
               errors: [
                 %{
                   kind: :anyOf,
                   invalidated: [
                     %{
                       valid: false,
                       schemaLocation: "/properties/foo/anyOf/0",
                       errors: [
                         %{
                           valid: false,
                           errors: [%{kind: :type}],
                           schemaLocation: "/properties/foo/anyOf/0",
                           evaluationPath: "/properties/foo/anyOf/0",
                           instanceLocation: "/foo"
                         }
                       ]
                     },
                     %{
                       valid: false,
                       schemaLocation: "/properties/foo/anyOf/1",
                       errors: [
                         %{
                           valid: false,
                           errors: [
                             %{
                               kind: :properties
                             }
                           ],
                           schemaLocation: "/properties/foo/anyOf/1",
                           evaluationPath: "/properties/foo/anyOf/1",
                           instanceLocation: "/foo"
                         },
                         %{
                           valid: false,
                           errors: [%{kind: :type}],
                           schemaLocation: "/properties/foo/anyOf/1/properties/bar",
                           evaluationPath: "/properties/foo/anyOf/1/properties/bar",
                           instanceLocation: "/foo/bar"
                         }
                       ]
                     }
                   ]
                 }
               ],
               schemaLocation: "/properties/foo",
               evaluationPath: "/properties/foo",
               instanceLocation: "/foo"
             }
           ] = formatted_errors
  end

  test "error formatting for not all of allOf" do
    schema =
      build_schema!(
        Jason.decode!(~S"""
        {
          "$id": "https://example.com/anyOfExample",
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "properties": {
            "foo": {
              "allOf": [
                {
                  "properties": {"bar": {"type": "number"}},
                  "required": ["bar"]
                },
                {
                  "properties": {"baz": {"type": "number"}},
                  "required": ["baz"]
                },
                {
                  "properties": {"qux": {"type": "number"}},
                  "required": ["qux"]
                }
              ]
            }
          },
          "required": ["foo"]
        }
        """)
      )

    invalid_data = %{"foo" => %{"bar" => 1, "baz" => "a string"}}

    assert {:error, {:schema_validation, errors}} = JSV.validate(invalid_data, schema)
    formatted_errors = JSV.format_errors(errors)

    assert [
             %{
               valid: false,
               errors: [
                 %{
                   kind: :properties
                 }
               ],
               schemaLocation: "",
               evaluationPath: "",
               instanceLocation: ""
             },
             %{
               valid: false,
               errors: [
                 %{
                   kind: :allOf,
                   invalidated: [
                     %{
                       valid: false,
                       schemaLocation: "/properties/foo/allOf/1",
                       errors: [
                         %{
                           valid: false,
                           errors: [
                             %{kind: :properties}
                           ],
                           schemaLocation: "/properties/foo/allOf/1",
                           evaluationPath: "/properties/foo/allOf/1",
                           instanceLocation: "/foo"
                         },
                         %{
                           valid: false,
                           errors: [%{kind: :type}],
                           schemaLocation: "/properties/foo/allOf/1/properties/baz",
                           evaluationPath: "/properties/foo/allOf/1/properties/baz",
                           instanceLocation: "/foo/baz"
                         }
                       ]
                     },
                     %{
                       valid: false,
                       schemaLocation: "/properties/foo/allOf/2",
                       errors: [
                         %{
                           valid: false,
                           errors: [%{kind: :required}],
                           schemaLocation: "/properties/foo/allOf/2",
                           evaluationPath: "/properties/foo/allOf/2",
                           instanceLocation: "/foo"
                         }
                       ]
                     }
                   ]
                 }
               ],
               schemaLocation: "/properties/foo",
               evaluationPath: "/properties/foo",
               instanceLocation: "/foo"
             }
           ] = formatted_errors
  end

  test "error formatting for more than one of oneOf" do
    schema =
      build_schema!(
        Jason.decode!(~S"""
        {
          "$id": "https://example.com/anyOfExample",
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "properties": {
            "foo": {
              "oneOf": [
                {
                  "properties": {"bar": {"type": "number"}},
                  "required": ["bar"]
                },
                {
                  "properties": {"baz": {"type": "number"}},
                  "required": ["baz"]
                },
                {
                  "properties": {"qux": {"type": "number"}},
                  "required": ["qux"]
                }
              ]
            }
          },
          "required": ["foo"]
        }
        """)
      )

    # validates only schemas of index 0 and 2, not 1
    invalid_data = %{"foo" => %{"bar" => 1, "qux" => 1}}

    assert {:error, {:schema_validation, errors}} = JSV.validate(invalid_data, schema)
    formatted_errors = JSV.format_errors(errors)

    assert [
             _,
             %{
               valid: false,
               errors: [
                 %{
                   validated: [
                     %{valid: true, schemaLocation: "/properties/foo/oneOf/0"},
                     %{valid: true, schemaLocation: "/properties/foo/oneOf/2"}
                   ]
                 }
               ]
             }
           ] = formatted_errors
  end
end
