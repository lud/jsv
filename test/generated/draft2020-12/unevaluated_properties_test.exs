# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
# credo:disable-for-this-file Credo.Check.Readability.StringSigils

defmodule JSV.Generated.Draft202012.UnevaluatedPropertiesTest do
  alias JSV.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/unevaluatedProperties.json
  """

  describe "unevaluatedProperties true:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "type": "object",
          "unevaluatedProperties": true
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "with no unevaluated properties", c do
      data = %{}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "with unevaluated properties", c do
      data = %{"foo" => "foo"}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "unevaluatedProperties schema:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "type": "object",
          "unevaluatedProperties": {
            "type": "string",
            "minLength": 3
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "with no unevaluated properties", c do
      data = %{}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "with valid unevaluated properties", c do
      data = %{"foo" => "foo"}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "with invalid unevaluated properties", c do
      data = %{"foo" => "fo"}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "unevaluatedProperties false:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "type": "object",
          "unevaluatedProperties": false
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "with no unevaluated properties", c do
      data = %{}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "with unevaluated properties", c do
      data = %{"foo" => "foo"}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "unevaluatedProperties with adjacent properties:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "type": "object",
          "properties": {
            "foo": {
              "type": "string"
            }
          },
          "unevaluatedProperties": false
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "with no unevaluated properties", c do
      data = %{"foo" => "foo"}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "with unevaluated properties", c do
      data = %{"bar" => "bar", "foo" => "foo"}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "unevaluatedProperties with adjacent patternProperties:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "type": "object",
          "patternProperties": {
            "^foo": {
              "type": "string"
            }
          },
          "unevaluatedProperties": false
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "with no unevaluated properties", c do
      data = %{"foo" => "foo"}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "with unevaluated properties", c do
      data = %{"bar" => "bar", "foo" => "foo"}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "unevaluatedProperties with adjacent additionalProperties:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "type": "object",
          "additionalProperties": true,
          "properties": {
            "foo": {
              "type": "string"
            }
          },
          "unevaluatedProperties": false
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "with no additional properties", c do
      data = %{"foo" => "foo"}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "with additional properties", c do
      data = %{"bar" => "bar", "foo" => "foo"}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "unevaluatedProperties with nested properties:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "type": "object",
          "allOf": [
            {
              "properties": {
                "bar": {
                  "type": "string"
                }
              }
            }
          ],
          "properties": {
            "foo": {
              "type": "string"
            }
          },
          "unevaluatedProperties": false
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "with no additional properties", c do
      data = %{"bar" => "bar", "foo" => "foo"}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "with additional properties", c do
      data = %{"bar" => "bar", "baz" => "baz", "foo" => "foo"}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "unevaluatedProperties with nested patternProperties:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "type": "object",
          "allOf": [
            {
              "patternProperties": {
                "^bar": {
                  "type": "string"
                }
              }
            }
          ],
          "properties": {
            "foo": {
              "type": "string"
            }
          },
          "unevaluatedProperties": false
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "with no additional properties", c do
      data = %{"bar" => "bar", "foo" => "foo"}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "with additional properties", c do
      data = %{"bar" => "bar", "baz" => "baz", "foo" => "foo"}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "unevaluatedProperties with nested additionalProperties:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "type": "object",
          "allOf": [
            {
              "additionalProperties": true
            }
          ],
          "properties": {
            "foo": {
              "type": "string"
            }
          },
          "unevaluatedProperties": false
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "with no additional properties", c do
      data = %{"foo" => "foo"}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "with additional properties", c do
      data = %{"bar" => "bar", "foo" => "foo"}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "unevaluatedProperties with nested unevaluatedProperties:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "type": "object",
          "allOf": [
            {
              "unevaluatedProperties": true
            }
          ],
          "properties": {
            "foo": {
              "type": "string"
            }
          },
          "unevaluatedProperties": {
            "type": "string",
            "maxLength": 2
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "with no nested unevaluated properties", c do
      data = %{"foo" => "foo"}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "with nested unevaluated properties", c do
      data = %{"bar" => "bar", "foo" => "foo"}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "unevaluatedProperties with anyOf:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "type": "object",
          "anyOf": [
            {
              "properties": {
                "bar": {
                  "const": "bar"
                }
              },
              "required": [
                "bar"
              ]
            },
            {
              "properties": {
                "baz": {
                  "const": "baz"
                }
              },
              "required": [
                "baz"
              ]
            },
            {
              "properties": {
                "quux": {
                  "const": "quux"
                }
              },
              "required": [
                "quux"
              ]
            }
          ],
          "properties": {
            "foo": {
              "type": "string"
            }
          },
          "unevaluatedProperties": false
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "when one matches and has no unevaluated properties", c do
      data = %{"bar" => "bar", "foo" => "foo"}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "when one matches and has unevaluated properties", c do
      data = %{"bar" => "bar", "baz" => "not-baz", "foo" => "foo"}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "when two match and has no unevaluated properties", c do
      data = %{"bar" => "bar", "baz" => "baz", "foo" => "foo"}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "when two match and has unevaluated properties", c do
      data = %{"bar" => "bar", "baz" => "baz", "foo" => "foo", "quux" => "not-quux"}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "unevaluatedProperties with oneOf:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "type": "object",
          "oneOf": [
            {
              "properties": {
                "bar": {
                  "const": "bar"
                }
              },
              "required": [
                "bar"
              ]
            },
            {
              "properties": {
                "baz": {
                  "const": "baz"
                }
              },
              "required": [
                "baz"
              ]
            }
          ],
          "properties": {
            "foo": {
              "type": "string"
            }
          },
          "unevaluatedProperties": false
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "with no unevaluated properties", c do
      data = %{"bar" => "bar", "foo" => "foo"}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "with unevaluated properties", c do
      data = %{"bar" => "bar", "foo" => "foo", "quux" => "quux"}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "unevaluatedProperties with not:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "type": "object",
          "not": {
            "not": {
              "properties": {
                "bar": {
                  "const": "bar"
                }
              },
              "required": [
                "bar"
              ]
            }
          },
          "properties": {
            "foo": {
              "type": "string"
            }
          },
          "unevaluatedProperties": false
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "with unevaluated properties", c do
      data = %{"bar" => "bar", "foo" => "foo"}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "unevaluatedProperties with if/then/else:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "type": "object",
          "else": {
            "properties": {
              "baz": {
                "type": "string"
              }
            },
            "required": [
              "baz"
            ]
          },
          "if": {
            "properties": {
              "foo": {
                "const": "then"
              }
            },
            "required": [
              "foo"
            ]
          },
          "then": {
            "properties": {
              "bar": {
                "type": "string"
              }
            },
            "required": [
              "bar"
            ]
          },
          "unevaluatedProperties": false
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "when if is true and has no unevaluated properties", c do
      data = %{"bar" => "bar", "foo" => "then"}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "when if is true and has unevaluated properties", c do
      data = %{"bar" => "bar", "baz" => "baz", "foo" => "then"}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "when if is false and has no unevaluated properties", c do
      data = %{"baz" => "baz"}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "when if is false and has unevaluated properties", c do
      data = %{"baz" => "baz", "foo" => "else"}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "unevaluatedProperties with if/then/else, then not defined:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "type": "object",
          "else": {
            "properties": {
              "baz": {
                "type": "string"
              }
            },
            "required": [
              "baz"
            ]
          },
          "if": {
            "properties": {
              "foo": {
                "const": "then"
              }
            },
            "required": [
              "foo"
            ]
          },
          "unevaluatedProperties": false
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "when if is true and has no unevaluated properties", c do
      data = %{"bar" => "bar", "foo" => "then"}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "when if is true and has unevaluated properties", c do
      data = %{"bar" => "bar", "baz" => "baz", "foo" => "then"}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "when if is false and has no unevaluated properties", c do
      data = %{"baz" => "baz"}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "when if is false and has unevaluated properties", c do
      data = %{"baz" => "baz", "foo" => "else"}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "unevaluatedProperties with if/then/else, else not defined:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "type": "object",
          "if": {
            "properties": {
              "foo": {
                "const": "then"
              }
            },
            "required": [
              "foo"
            ]
          },
          "then": {
            "properties": {
              "bar": {
                "type": "string"
              }
            },
            "required": [
              "bar"
            ]
          },
          "unevaluatedProperties": false
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "when if is true and has no unevaluated properties", c do
      data = %{"bar" => "bar", "foo" => "then"}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "when if is true and has unevaluated properties", c do
      data = %{"bar" => "bar", "baz" => "baz", "foo" => "then"}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "when if is false and has no unevaluated properties", c do
      data = %{"baz" => "baz"}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "when if is false and has unevaluated properties", c do
      data = %{"baz" => "baz", "foo" => "else"}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "unevaluatedProperties with dependentSchemas:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "type": "object",
          "dependentSchemas": {
            "foo": {
              "properties": {
                "bar": {
                  "const": "bar"
                }
              },
              "required": [
                "bar"
              ]
            }
          },
          "properties": {
            "foo": {
              "type": "string"
            }
          },
          "unevaluatedProperties": false
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "with no unevaluated properties", c do
      data = %{"bar" => "bar", "foo" => "foo"}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "with unevaluated properties", c do
      data = %{"bar" => "bar"}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "unevaluatedProperties with boolean schemas:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "type": "object",
          "allOf": [
            true
          ],
          "properties": {
            "foo": {
              "type": "string"
            }
          },
          "unevaluatedProperties": false
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "with no unevaluated properties", c do
      data = %{"foo" => "foo"}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "with unevaluated properties", c do
      data = %{"bar" => "bar"}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "unevaluatedProperties with $ref:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "$defs": {
            "bar": {
              "properties": {
                "bar": {
                  "type": "string"
                }
              }
            }
          },
          "type": "object",
          "$ref": "#/$defs/bar",
          "properties": {
            "foo": {
              "type": "string"
            }
          },
          "unevaluatedProperties": false
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "with no unevaluated properties", c do
      data = %{"bar" => "bar", "foo" => "foo"}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "with unevaluated properties", c do
      data = %{"bar" => "bar", "baz" => "baz", "foo" => "foo"}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "unevaluatedProperties before $ref:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "$defs": {
            "bar": {
              "properties": {
                "bar": {
                  "type": "string"
                }
              }
            }
          },
          "type": "object",
          "$ref": "#/$defs/bar",
          "properties": {
            "foo": {
              "type": "string"
            }
          },
          "unevaluatedProperties": false
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "with no unevaluated properties", c do
      data = %{"bar" => "bar", "foo" => "foo"}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "with unevaluated properties", c do
      data = %{"bar" => "bar", "baz" => "baz", "foo" => "foo"}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "unevaluatedProperties with $dynamicRef:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "$id": "https://example.com/unevaluated-properties-with-dynamic-ref/derived",
          "$defs": {
            "baseSchema": {
              "$id": "./baseSchema",
              "$defs": {
                "defaultAddons": {
                  "$comment": "Needed to satisfy the bookending requirement",
                  "$dynamicAnchor": "addons"
                }
              },
              "type": "object",
              "$comment": "unevaluatedProperties comes first so it's more likely to catch bugs with implementations that are sensitive to keyword ordering",
              "$dynamicRef": "#addons",
              "properties": {
                "foo": {
                  "type": "string"
                }
              },
              "unevaluatedProperties": false
            },
            "derived": {
              "$dynamicAnchor": "addons",
              "properties": {
                "bar": {
                  "type": "string"
                }
              }
            }
          },
          "$ref": "./baseSchema"
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "with no unevaluated properties", c do
      data = %{"bar" => "bar", "foo" => "foo"}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "with unevaluated properties", c do
      data = %{"bar" => "bar", "baz" => "baz", "foo" => "foo"}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "unevaluatedProperties can't see inside cousins:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "allOf": [
            {
              "properties": {
                "foo": true
              }
            },
            {
              "unevaluatedProperties": false
            }
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "always fails", c do
      data = %{"foo" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "unevaluatedProperties can't see inside cousins (reverse order):" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "allOf": [
            {
              "unevaluatedProperties": false
            },
            {
              "properties": {
                "foo": true
              }
            }
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "always fails", c do
      data = %{"foo" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "nested unevaluatedProperties, outer false, inner true, properties outside:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "type": "object",
          "allOf": [
            {
              "unevaluatedProperties": true
            }
          ],
          "properties": {
            "foo": {
              "type": "string"
            }
          },
          "unevaluatedProperties": false
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "with no nested unevaluated properties", c do
      data = %{"foo" => "foo"}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "with nested unevaluated properties", c do
      data = %{"bar" => "bar", "foo" => "foo"}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "nested unevaluatedProperties, outer false, inner true, properties inside:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "type": "object",
          "allOf": [
            {
              "properties": {
                "foo": {
                  "type": "string"
                }
              },
              "unevaluatedProperties": true
            }
          ],
          "unevaluatedProperties": false
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "with no nested unevaluated properties", c do
      data = %{"foo" => "foo"}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "with nested unevaluated properties", c do
      data = %{"bar" => "bar", "foo" => "foo"}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "nested unevaluatedProperties, outer true, inner false, properties outside:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "type": "object",
          "allOf": [
            {
              "unevaluatedProperties": false
            }
          ],
          "properties": {
            "foo": {
              "type": "string"
            }
          },
          "unevaluatedProperties": true
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "with no nested unevaluated properties", c do
      data = %{"foo" => "foo"}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "with nested unevaluated properties", c do
      data = %{"bar" => "bar", "foo" => "foo"}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "nested unevaluatedProperties, outer true, inner false, properties inside:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "type": "object",
          "allOf": [
            {
              "properties": {
                "foo": {
                  "type": "string"
                }
              },
              "unevaluatedProperties": false
            }
          ],
          "unevaluatedProperties": true
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "with no nested unevaluated properties", c do
      data = %{"foo" => "foo"}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "with nested unevaluated properties", c do
      data = %{"bar" => "bar", "foo" => "foo"}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "cousin unevaluatedProperties, true and false, true with properties:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "type": "object",
          "allOf": [
            {
              "properties": {
                "foo": {
                  "type": "string"
                }
              },
              "unevaluatedProperties": true
            },
            {
              "unevaluatedProperties": false
            }
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "with no nested unevaluated properties", c do
      data = %{"foo" => "foo"}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "with nested unevaluated properties", c do
      data = %{"bar" => "bar", "foo" => "foo"}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "cousin unevaluatedProperties, true and false, false with properties:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "type": "object",
          "allOf": [
            {
              "unevaluatedProperties": true
            },
            {
              "properties": {
                "foo": {
                  "type": "string"
                }
              },
              "unevaluatedProperties": false
            }
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "with no nested unevaluated properties", c do
      data = %{"foo" => "foo"}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "with nested unevaluated properties", c do
      data = %{"bar" => "bar", "foo" => "foo"}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "property is evaluated in an uncle schema to unevaluatedProperties:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "type": "object",
          "anyOf": [
            {
              "properties": {
                "foo": {
                  "properties": {
                    "faz": {
                      "type": "string"
                    }
                  }
                }
              }
            }
          ],
          "properties": {
            "foo": {
              "type": "object",
              "properties": {
                "bar": {
                  "type": "string"
                }
              },
              "unevaluatedProperties": false
            }
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "no extra properties", c do
      data = %{"foo" => %{"bar" => "test"}}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "uncle keyword evaluation is not significant", c do
      data = %{"foo" => %{"bar" => "test", "faz" => "test"}}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "in-place applicator siblings, allOf has unevaluated:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "type": "object",
          "allOf": [
            {
              "properties": {
                "foo": true
              },
              "unevaluatedProperties": false
            }
          ],
          "anyOf": [
            {
              "properties": {
                "bar": true
              }
            }
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "base case: both properties present", c do
      data = %{"bar" => 1, "foo" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "in place applicator siblings, bar is missing", c do
      data = %{"foo" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "in place applicator siblings, foo is missing", c do
      data = %{"bar" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "in-place applicator siblings, anyOf has unevaluated:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "type": "object",
          "allOf": [
            {
              "properties": {
                "foo": true
              }
            }
          ],
          "anyOf": [
            {
              "properties": {
                "bar": true
              },
              "unevaluatedProperties": false
            }
          ]
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "base case: both properties present", c do
      data = %{"bar" => 1, "foo" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "in place applicator siblings, bar is missing", c do
      data = %{"foo" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "in place applicator siblings, foo is missing", c do
      data = %{"bar" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "unevaluatedProperties + single cyclic ref:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "type": "object",
          "properties": {
            "x": {
              "$ref": "#"
            }
          },
          "unevaluatedProperties": false
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "Empty is valid", c do
      data = %{}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "Single is valid", c do
      data = %{"x" => %{}}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "Unevaluated on 1st level is invalid", c do
      data = %{"x" => %{}, "y" => %{}}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "Nested is valid", c do
      data = %{"x" => %{"x" => %{}}}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "Unevaluated on 2nd level is invalid", c do
      data = %{"x" => %{"x" => %{}, "y" => %{}}}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "Deep nested is valid", c do
      data = %{"x" => %{"x" => %{"x" => %{}}}}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "Unevaluated on 3rd level is invalid", c do
      data = %{"x" => %{"x" => %{"x" => %{}, "y" => %{}}}}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "unevaluatedProperties + ref inside allOf / oneOf:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "$defs": {
            "one": {
              "properties": {
                "a": true
              }
            },
            "two": {
              "properties": {
                "x": true
              },
              "required": [
                "x"
              ]
            }
          },
          "allOf": [
            {
              "$ref": "#/$defs/one"
            },
            {
              "properties": {
                "b": true
              }
            },
            {
              "oneOf": [
                {
                  "$ref": "#/$defs/two"
                },
                {
                  "properties": {
                    "y": true
                  },
                  "required": [
                    "y"
                  ]
                }
              ]
            }
          ],
          "unevaluatedProperties": false
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "Empty is invalid (no x or y)", c do
      data = %{}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "a and b are invalid (no x or y)", c do
      data = %{"a" => 1, "b" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "x and y are invalid", c do
      data = %{"x" => 1, "y" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "a and x are valid", c do
      data = %{"a" => 1, "x" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "a and y are valid", c do
      data = %{"a" => 1, "y" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "a and b and x are valid", c do
      data = %{"a" => 1, "b" => 1, "x" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "a and b and y are valid", c do
      data = %{"a" => 1, "b" => 1, "y" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "a and b and x and y are invalid", c do
      data = %{"a" => 1, "b" => 1, "x" => 1, "y" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "dynamic evalation inside nested refs:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "$defs": {
            "one": {
              "oneOf": [
                {
                  "$ref": "#/$defs/two"
                },
                {
                  "properties": {
                    "b": true
                  },
                  "required": [
                    "b"
                  ]
                },
                {
                  "patternProperties": {
                    "x": true
                  },
                  "required": [
                    "xx"
                  ]
                },
                {
                  "required": [
                    "all"
                  ],
                  "unevaluatedProperties": true
                }
              ]
            },
            "two": {
              "oneOf": [
                {
                  "properties": {
                    "c": true
                  },
                  "required": [
                    "c"
                  ]
                },
                {
                  "properties": {
                    "d": true
                  },
                  "required": [
                    "d"
                  ]
                }
              ]
            }
          },
          "oneOf": [
            {
              "$ref": "#/$defs/one"
            },
            {
              "properties": {
                "a": true
              },
              "required": [
                "a"
              ]
            }
          ],
          "unevaluatedProperties": false
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "Empty is invalid", c do
      data = %{}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "a is valid", c do
      data = %{"a" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "b is valid", c do
      data = %{"b" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "c is valid", c do
      data = %{"c" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "d is valid", c do
      data = %{"d" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "a + b is invalid", c do
      data = %{"a" => 1, "b" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "a + c is invalid", c do
      data = %{"a" => 1, "c" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "a + d is invalid", c do
      data = %{"a" => 1, "d" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "b + c is invalid", c do
      data = %{"b" => 1, "c" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "b + d is invalid", c do
      data = %{"b" => 1, "d" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "c + d is invalid", c do
      data = %{"c" => 1, "d" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "xx is valid", c do
      data = %{"xx" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "xx + foox is valid", c do
      data = %{"foox" => 1, "xx" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "xx + foo is invalid", c do
      data = %{"foo" => 1, "xx" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "xx + a is invalid", c do
      data = %{"a" => 1, "xx" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "xx + b is invalid", c do
      data = %{"b" => 1, "xx" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "xx + c is invalid", c do
      data = %{"c" => 1, "xx" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "xx + d is invalid", c do
      data = %{"d" => 1, "xx" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "all is valid", c do
      data = %{"all" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "all + foo is valid", c do
      data = %{"all" => 1, "foo" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "all + a is invalid", c do
      data = %{"a" => 1, "all" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "non-object instances are valid:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "unevaluatedProperties": false
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "ignores booleans", c do
      data = true
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "ignores integers", c do
      data = 123
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "ignores floats", c do
      data = 1.0
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "ignores arrays", c do
      data = []
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "ignores strings", c do
      data = "foo"
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "ignores null", c do
      data = nil
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "unevaluatedProperties with null valued instance properties:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "unevaluatedProperties": {
            "type": "null"
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "allows null valued properties", c do
      data = %{"foo" => nil}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "unevaluatedProperties not affected by propertyNames:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "propertyNames": {
            "maxLength": 1
          },
          "unevaluatedProperties": {
            "type": "number"
          }
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "allows only number properties", c do
      data = %{"a" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "string property is invalid", c do
      data = %{"a" => "b"}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "unevaluatedProperties can see annotations from if without then and else:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "if": {
            "patternProperties": {
              "foo": {
                "type": "string"
              }
            }
          },
          "unevaluatedProperties": false
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "valid in case if is evaluated", c do
      data = %{"foo" => "a"}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "invalid in case if is evaluated", c do
      data = %{"bar" => "a"}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end

  describe "dependentSchemas with unevaluatedProperties:" do
    setup do
      json_schema =
        Jason.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "dependentSchemas": {
            "foo": {},
            "foo2": {
              "properties": {
                "bar": {}
              }
            }
          },
          "properties": {
            "foo2": {}
          },
          "unevaluatedProperties": false
        }
        """)

      schema = JsonSchemaSuite.build_schema(json_schema, default_meta: "https://json-schema.org/draft/2020-12/schema")
      {:ok, json_schema: json_schema, schema: schema}
    end

    test "unevaluatedProperties doesn't consider dependentSchemas", c do
      data = %{"foo" => ""}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "unevaluatedProperties doesn't see bar when foo2 is absent", c do
      data = %{"bar" => ""}
      expected_valid = false
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end

    test "unevaluatedProperties sees bar when foo2 is present", c do
      data = %{"bar" => "", "foo2" => ""}
      expected_valid = true
      JsonSchemaSuite.run_test(c.json_schema, c.schema, data, expected_valid)
    end
  end
end
