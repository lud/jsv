defmodule JSV.ErrorFormatTest do
  alias JSV
  alias JSV.Codec
  alias JSV.Schema
  use ExUnit.Case, async: true

  defp build_schema!(json_schema, opts \\ []) do
    {:ok, schema} = JSV.build(json_schema, [resolver: JSV.Test.TestResolver] ++ opts)
    schema
  end

  defp valid_message(exception) do
    case Exception.message(exception) do
      "got " <> _ = bad_msg ->
        ["got " <> _, rest] = String.split(bad_msg, "with message ")

        flunk("""
        Exception could not produce a message:

        #{rest}
        """)

      v ->
        v
    end
  end

  defmacrop assert_match_error(err, pattern) do
    as_string = Macro.to_string(pattern)

    quote do
      try do
        matcher = &match?(unquote(pattern), &1)
        err = unquote(err)

        deep_match_error(err, matcher)

        raise """
        could not find matching error

        PATTERN
        #{unquote(as_string)}

        ERRORS
        #{inspect(err, pretty: true)}
        """
      catch
        :throw, {:found_error, e} -> e
      end
    end
  end

  defp deep_match_error(map, matcher) when is_map(map) do
    if matcher.(map) do
      throw({:found_error, map})
    else
      Enum.each(map, fn {_, v} -> deep_match_error(v, matcher) end)
    end
  end

  defp deep_match_error(list, matcher) when is_list(list) do
    Enum.each(list, &deep_match_error(&1, matcher))
  end

  defp deep_match_error({_, v}, matcher) do
    deep_match_error(v, matcher)
  end

  defp deep_match_error(_, _matcher) do
    :nope
  end

  # defp prune_error(term) do
  #   case term do
  #     %JSV.Validator.ValidationContext{} -> "__CONTEXT__"
  #     %s{} = struct -> Map.put(prune_error(Map.from_struct(struct)), :__struct__, s)
  #     map when is_map(map) -> Map.new(map, fn {k, v} -> {prune_error(k), prune_error(v)} end)
  #     list when is_list(list) -> Enum.map(list, &prune_error/1)
  #     tuple when is_tuple(tuple) -> tuple |> Tuple.to_list() |> prune_error() |> List.to_tuple()
  #     atom when is_atom(atom) -> atom
  #     binary when is_binary(binary) -> binary
  #     number when is_number(number) -> number
  #   end
  # end

  @error_output_schema JSV.normal_error_schema()

  defp assert_output_schema(formatted_error) do
    {:ok, output_schema} = JSV.build(@error_output_schema, resolver: JSV.Test.TestResolver)
    raw = Schema.normalize(formatted_error)

    case JSV.validate(raw, output_schema) do
      {:ok, _} ->
        true

      {:error, ve} ->
        flunk("""
        Error output did not validate output schema:

        # DATA
        #{inspect(raw, pretty: true)}

        # ERRORS
        #{inspect(JSV.normalize_error(ve), pretty: true)}
        """)
    end
  end

  test "sample example from json-schema.org blog" do
    schema =
      build_schema!(
        Codec.decode!(~S"""
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

    assert {:error, validation_error} = JSV.validate(invalid_data, schema)
    formatted_error = JSV.normalize_error(validation_error)
    assert_output_schema(formatted_error)
    assert valid_message(validation_error) =~ "at:"
  end

  test "error formatting for none of anyOf" do
    schema =
      build_schema!(
        Codec.decode!(~S"""
        {
          "$id": "https://example.com/anyOfExample",
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "$defs": {
            "some-def": {
              "maxProperties": 0
            }
          },
          "properties": {
            "a": {
              "properties": {
                "b": {
                  "$ref": "#/$defs/some-def",
                  "required": ["foo"],
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
                  }
                }
              }
            }
          }
        }
        """)
      )

    invalid_data = %{"a" => %{"b" => %{"foo" => %{"bar" => "baz"}}}}

    assert {:error, validation_error} = JSV.validate(invalid_data, schema)
    formatted_error = JSV.normalize_error(validation_error)

    assert_output_schema(formatted_error)
    assert valid_message(validation_error) =~ "at:"

    assert_match_error(formatted_error, %{
      schemaLocation: "https://example.com/anyOfExample#/properties/a/properties/b/properties/foo/anyOf/0"
    })

    assert_match_error(formatted_error, %{
      schemaLocation:
        "https://example.com/anyOfExample#/properties/a/properties/b/properties/foo/anyOf/1/properties/bar"
    })
  end

  test "error formatting for not all of allOf" do
    schema =
      build_schema!(
        Codec.decode!(~S"""
        {
          "$id": "https://example.com/allOfExample",
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

    assert {:error, validation_error} = JSV.validate(invalid_data, schema)
    formatted_error = JSV.normalize_error(validation_error)

    assert_output_schema(formatted_error)
    assert valid_message(validation_error) =~ "at:"

    assert_match_error(formatted_error, %{
      schemaLocation: "https://example.com/allOfExample#/properties/foo/allOf/1/properties/baz"
    })

    assert_match_error(formatted_error, %{
      schemaLocation: "https://example.com/allOfExample#/properties/foo/allOf/2",
      errors: [
        %{message: "property 'qux' is required", kind: :required}
      ]
    })
  end

  test "error formatting for more than one of oneOf" do
    schema =
      build_schema!(
        Codec.decode!(~S"""
        {
          "$id": "https://example.com/oneOfExample",
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

    assert {:error, validation_error} = JSV.validate(invalid_data, schema)
    formatted_error = JSV.normalize_error(validation_error)
    assert_output_schema(formatted_error)
    assert valid_message(validation_error) =~ "at:"

    assert_match_error(formatted_error, %{
      valid: true,
      schemaLocation: "https://example.com/oneOfExample#/properties/foo/oneOf/0"
    })

    assert_match_error(formatted_error, %{
      valid: true,
      schemaLocation: "https://example.com/oneOfExample#/properties/foo/oneOf/2"
    })
  end

  test "error formatting for none of oneOf" do
    schema =
      build_schema!(
        Codec.decode!(~S"""
        {
          "$id": "https://example.com/oneOfExample",
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
    invalid_data = %{"foo" => %{"other" => "nope"}}

    assert {:error, validation_error} = JSV.validate(invalid_data, schema)
    formatted_error = JSV.normalize_error(validation_error)
    assert_output_schema(formatted_error)
    assert valid_message(validation_error) =~ "at:"

    assert_match_error(formatted_error, %{
      schemaLocation: "https://example.com/oneOfExample#/properties/foo/oneOf/0"
    })

    assert_match_error(formatted_error, %{
      schemaLocation: "https://example.com/oneOfExample#/properties/foo/oneOf/1"
    })

    assert_match_error(formatted_error, %{
      schemaLocation: "https://example.com/oneOfExample#/properties/foo/oneOf/2"
    })
  end

  test "error formatting for if / else" do
    schema =
      build_schema!(
        Codec.decode!(~S"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "type": "object",
          "properties": {
            "age": {
              "type": "integer",
              "minimum": 0
            }
          },
          "required": ["age"],

          "if": {
            "properties": {
              "age": { "minimum": 18 }
            },
            "required": ["age"]
          },
          "then": {
            "required": ["driverLicense"],
            "properties": {
              "driverLicense": {
                "type": "string"
              }
            }
          },
          "else": {
            "properties": {
              "guardianName": {
                "type": "string"
              }
            },
            "required": ["guardianName"]
          }
        }
        """)
      )

    # validates the 'if' but not the 'then'

    invalid_data = %{"age" => 25}
    assert {:error, validation_error} = JSV.validate(invalid_data, schema)
    formatted_error = JSV.normalize_error(validation_error)
    assert_output_schema(formatted_error)
    assert valid_message(validation_error) =~ "at:"

    assert_match_error(formatted_error, %{
      schemaLocation: "#/then",
      errors: [
        %{
          message: "property 'driverLicense' is required",
          kind: :required
        }
      ]
    })

    # does not validate 'if' nor 'else'

    invalid_data = %{"age" => 12, "guardianName" => 123}
    assert {:error, validation_error} = JSV.validate(invalid_data, schema)
    formatted_error = JSV.normalize_error(validation_error)
    assert_output_schema(formatted_error)
    assert valid_message(validation_error) =~ "at:"
    assert_match_error(formatted_error, %{schemaLocation: "#/if/properties/age"})
    assert_match_error(formatted_error, %{schemaLocation: "#/else/properties/guardianName"})
  end

  test "error formatting for additionalProperties: false" do
    schema = %{properties: %{a: %{type: :integer}}, additionalProperties: false}
    root = JSV.build!(schema)

    assert {:ok, %{"a" => 1}} = JSV.validate(%{"a" => 1}, root)
    assert {:error, err} = JSV.validate(%{"a" => 1, "b" => 2}, root)

    # In case additionalProperties is a boolean schema we want a custom message,
    # so we must have the info in the error (boolean_schema_false: true) here:

    assert %JSV.ValidationError{errors: [%JSV.Validator.Error{args: [key: "b", boolean_schema_false: true]}, _]} = err

    assert %{
             valid: false,
             details: [
               %{
                 errors: [%{message: "value was rejected from boolean schema: false", kind: :boolean_schema}],
                 valid: false,
                 schemaLocation: "#/additionalProperties",
                 evaluationPath: "#/additionalProperties",
                 instanceLocation: "#/b"
               },
               %{
                 errors: [
                   # Here is the custom message in that case
                   %{
                     message: message,
                     kind: :additionalProperties
                   }
                 ],
                 valid: false,
                 schemaLocation: "#",
                 evaluationPath: "#",
                 instanceLocation: "#"
               }
             ]
           } =
             JSV.normalize_error(err)

    assert "additional properties are not allowed but found property 'b'" == message
  end

  test "dynamic anchor schema location" do
    # In case of a dynamic ref/anchor, the schema location on the error should
    # be correct and tell which anchor was used

    schema = %{
      "$schema" => "https://json-schema.org/draft/2020-12/schema",
      "$id" => "https://some-id/somepath",
      "$ref" => "list",
      "$defs" => %{
        "foo" => %{"$dynamicAnchor" => "items", "type" => "integer"},
        "list" => %{
          "$id" => "list",
          "$defs" => %{
            "items" => %{
              "$dynamicAnchor" => "items",
              "$comment" => "This is only needed to satisfy the bookending requirement"
            }
          },
          "type" => "array",
          "items" => %{"$dynamicRef" => "#items"}
        }
      }
    }

    root = JSV.build!(schema)

    data = [123, "not an integer"]

    assert {:error, err} = JSV.validate(data, root)
    formatted_error = JSV.normalize_error(err)

    # The schema location should be in the correct anchor definition
    assert_match_error(formatted_error, %{schemaLocation: "https://some-id/somepath#/$defs/foo"})
  end

  test "schema location on referenced schema" do
    defmodule OtherResolver do
      @behaviour JSV.Resolver

      @impl true
      def resolve("other:hello", _) do
        {:ok, %{"properties" => %{"b" => %{"type" => "integer"}}}}
      end

      def resolve(_, _) do
        {:error, :unknown}
      end
    end

    schema = %{"properties" => %{"a" => %{"$ref" => "other:hello"}}}
    root = JSV.build!(schema, resolver: OtherResolver)
    data = %{"a" => %{"b" => "not an integer"}}
    assert {:error, err} = JSV.validate(data, root)
    formatted_error = JSV.normalize_error(err)
    # The schema location should be in the correct anchor definition
    assert_match_error(formatted_error, %{
      errors: [%{message: "value is not of type integer", kind: :type}],
      valid: false,
      schemaLocation: "other:hello#/properties/b",
      evaluationPath: "#/properties/a/$ref/properties/b",
      instanceLocation: "#/a/b"
    })
  end

  test "inner reference should not have relative id before '#'" do
    schema = %{
      "$id" => "https://some/base",
      "$ref" => "extended",
      "$defs" => %{
        "foo" => %{
          "$id" => "extended",
          "type" => "integer"
        }
      }
    }

    root = JSV.build!(schema)
    data = "not an integer"
    assert {:error, err} = JSV.validate(data, root)
    formatted_error = JSV.normalize_error(err)
    # The schema location should not be https://some/extended...

    assert_match_error(formatted_error, %{schemaLocation: "https://some/base#/$defs/foo"})
  end

  test "inner reference from dynamic anchor should not have relative id before '#'" do
    schema = %JSV.Schema{
      "$id": "https://test/base",
      "$dynamicAnchor": "meta",
      "$ref": "extended",
      "$defs": %{
        bar: %JSV.Schema{
          "$id": "bar",
          type: "object",
          properties: %{baz: %JSV.Schema{"$dynamicRef": "extended#meta"}}
        },
        extended: %JSV.Schema{
          "$id": "extended",
          "$anchor": "meta",
          type: "object",
          properties: %{bar: %JSV.Schema{"$ref": "bar"}}
        }
      },
      type: "object",
      properties: %{foo: %{const: "pass"}}
    }

    root = JSV.build!(schema)
    data = "not an integer"
    assert {:error, err} = JSV.validate(data, root)
    formatted_error = JSV.normalize_error(err)

    # schema locations should not be https://test/extended

    assert_match_error(formatted_error, %{
      errors: [%{kind: :type}],
      schemaLocation: "https://test/base#",
      evaluationPath: "#",
      instanceLocation: "#"
    })

    assert_match_error(formatted_error, %{
      errors: [%{kind: :type}],
      schemaLocation: "https://test/base#/$defs/extended",
      evaluationPath: "#/$ref",
      instanceLocation: "#"
    })
  end

  test "locations are json-pointer encoded" do
    schema = %{
      "some" => %{
        "type" => "object",
        "properties" => %{
          "nested/~with/special" => %{"type" => "integer"}
        }
      },
      "$ref" => "#/some"
    }

    invalid = %{"nested/~with/special" => "not an int"}
    root = JSV.build!(schema)
    assert {:error, err} = JSV.validate(invalid, root)

    assert %{
             valid: false,
             details: [
               %{
                 errors: [
                   %{
                     kind: :type,
                     message: "value is not of type integer"
                   }
                 ],
                 valid: false,
                 instanceLocation: "#/nested~1~0with~1special",
                 schemaLocation: "#/some/properties/nested~1~0with~1special",
                 evaluationPath: "#/$ref/properties/nested~1~0with~1special"
               },
               %{
                 errors: [
                   %{
                     kind: :properties,
                     message: "property 'nested/~with/special' did not conform to the property schema"
                   }
                 ],
                 valid: false,
                 instanceLocation: "#",
                 schemaLocation: "#/some",
                 evaluationPath: "#/$ref"
               }
             ]
           } =
             JSV.normalize_error(err)
  end
end
