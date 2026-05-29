defmodule JSV.Schema.HelpersTest do
  alias JSV.Schema.Helpers
  use ExUnit.Case, async: true
  import Helpers

  doctest JSV.Schema.Helpers, import: true

  defp erase_type(it) do
    Process.get(make_ref(), it)
  end

  defp build(schema) do
    JSV.build!(schema, formats: true, atoms: true)
  end

  defp assert_valid(root, value) do
    case JSV.validate(value, root, cast_formats: true) do
      {:ok, _} ->
        :ok

      {:error, err} ->
        flunk("Expected #{inspect(value)} to be valid, got: #{inspect(JSV.normalize_error(err), pretty: true)}")
    end
  end

  defp assert_invalid(root, value) do
    case JSV.validate(value, root, cast_formats: true) do
      {:ok, casted} ->
        flunk("Expected #{inspect(value)} to be invalid, got casted: #{inspect(casted)}")

      {:error, _} ->
        :ok
    end
  end

  defp assert_cast(root, value, expected) do
    case JSV.validate(value, root, cast_formats: true) do
      {:ok, ^expected} ->
        :ok

      {:ok, casted} ->
        flunk("Expected #{inspect(value)} to cast to #{inspect(expected)}, got: #{inspect(casted)}")

      {:error, err} ->
        flunk("Expected #{inspect(value)} to be valid, got: #{inspect(JSV.normalize_error(err), pretty: true)}")
    end
  end

  describe "presets helpers" do
    test "boolean" do
      root = build(boolean())

      assert_valid root, true
      assert_valid root, false

      assert_invalid root, "hello"
      assert_invalid root, 0
      assert_invalid root, 1
      assert_invalid root, ""
      assert_invalid root, nil
    end

    test "integer" do
      root = build(integer())

      assert_valid root, 1
      assert_valid root, -10
      assert_cast root, 2.0, 2
      assert_cast root, -2.0, -2
      assert_cast root, +0.0, 0
      assert_cast root, -0.0, 0

      assert_invalid root, 1.5
      assert_invalid root, "string"
      assert_invalid root, true
      assert_invalid root, nil
    end

    test "pos_integer" do
      root = build(pos_integer())

      assert_valid root, 1
      assert_valid root, 42
      assert_cast root, 1.0, 1

      assert_invalid root, 0
      assert_invalid root, -1
      assert_invalid root, 1.5
      assert_invalid root, "string"
      assert_invalid root, true
      assert_invalid root, nil
    end

    test "non_neg_integer" do
      root = build(non_neg_integer())

      assert_valid root, 0
      assert_valid root, 1
      assert_valid root, 42
      assert_cast root, 1.0, 1
      assert_cast root, +0.0, 0
      assert_cast root, -0.0, 0

      assert_invalid root, -1
      assert_invalid root, 1.5
      assert_invalid root, "string"
      assert_invalid root, true
      assert_invalid root, nil
    end

    test "neg_integer" do
      root = build(neg_integer())

      assert_valid root, -1
      assert_valid root, -42
      assert_cast root, -1.0, -1

      assert_invalid root, 0
      assert_invalid root, 1
      assert_invalid root, -1.5
      assert_invalid root, "string"
      assert_invalid root, true
      assert_invalid root, nil
    end

    test "number" do
      root = build(number())

      assert_valid root, 1
      assert_valid root, 1.5
      assert_valid root, -10.2
      assert_valid root, -0.0

      assert_invalid root, "string"
      assert_invalid root, true
      assert_invalid root, nil
      assert_invalid root, []
      assert_invalid root, [0]
    end

    test "string" do
      root = build(string())

      assert_valid root, ""
      assert_valid root, "hello"
      assert_valid root, " "

      assert_invalid root, true
      assert_invalid root, false
      assert_invalid root, 1
      assert_invalid root, %{}
    end

    test "non_empty_string" do
      root = build(non_empty_string())

      assert_valid root, "hello"
      assert_valid root, " "

      assert_invalid root, ""
      assert_invalid root, true
      assert_invalid root, false
      assert_invalid root, 1
      assert_invalid root, %{}
      assert_invalid root, nil
    end

    test "format" do
      root = build(format("date"))

      assert_valid root, "2023-05-20"
      assert_valid root, 123
      assert_valid root, true
      assert_valid root, nil

      assert_invalid root, "20-05-2023"
      assert_invalid root, "2023-05-20T12:30:00Z"
    end

    test "string_of" do
      root = build(string_of("date"))

      assert_valid root, "2023-05-20"

      assert_invalid root, "20-05-2023"
      assert_invalid root, "2023-05-20T12:30:00Z"
      assert_invalid root, 123
      assert_invalid root, true
      assert_invalid root, nil
    end

    test "date" do
      root = build(date())

      assert_valid root, "2023-05-20"

      assert_invalid root, "20-05-2023"
      assert_invalid root, "2023-05-20T12:30:00Z"
      assert_invalid root, 123
      assert_invalid root, true
      assert_invalid root, nil
    end

    test "datetime" do
      root = build(datetime())

      assert_valid root, "2023-05-20T12:30:00Z"
      assert_valid root, "2023-05-20T12:30:00+02:00"
      assert_valid root, "2023-05-20T12:30:00.123Z"

      assert_invalid root, "2023-05-20"
      assert_invalid root, "12:30:00"
      assert_invalid root, "not a datetime"
      assert_invalid root, 123
      assert_invalid root, true
      assert_invalid root, nil
    end

    test "uri" do
      root = build(uri())

      assert_valid root, "https://example.com"
      assert_valid root, "http://localhost:4000"
      assert_valid root, "ftp://files.example.org"

      assert_invalid root, "example.com"
      assert_invalid root, "not a uri"
      assert_invalid root, 123
      assert_invalid root, true
      assert_invalid root, nil
    end

    test "uuid" do
      root = build(uuid())

      assert_valid root, "550e8400-e29b-41d4-a716-446655440000"

      assert_invalid root, "not-a-uuid"
      assert_invalid root, "123"
      assert_invalid root, "123e4567e89b12d3a456426614174000"
      assert_invalid root, 123
      assert_invalid root, true
      assert_invalid root, nil
    end

    test "email" do
      root = build(email())

      assert_valid root, "a@[IPv6:::1]"
      assert_valid root, "te~st@example.com"
      assert_valid root, "~test@example.com"
      assert_valid root, "test~@example.com"
      assert_valid root, "te.s.t@example.com"

      assert_invalid root, "bad email"
      assert_invalid root, "2962"
      assert_invalid root, ".test@example.com"
      assert_invalid root, "test.@example.com"
      assert_invalid root, "te..st@example.com"
      assert_invalid root, 123
      assert_invalid root, true
      assert_invalid root, nil
    end

    test "object" do
      root = build(object())

      assert_valid root, %{"key" => "value"}
      assert_valid root, %{}

      assert_invalid root, "string"
      assert_invalid root, 1
      assert_invalid root, nil
    end

    test "array_of" do
      root = build(array_of(%{type: :string}))

      assert_valid root, ["a", "b", "c"]

      assert_invalid root, ["a", 1, true]
      assert_invalid root, "not an array"
    end

    test "properties (as map)" do
      root = build(properties(%{prop1: %{type: :string}, prop2: %{type: :integer}}))

      assert_valid root, %{"prop1" => "value"}
      assert_valid root, %{"prop2" => 123}
      assert_valid root, %{"prop1" => "value", "prop2" => 123}
      assert_valid root, %{}
      assert_valid root, "not an object"
      assert_valid root, 123
      assert_valid root, nil

      assert_invalid root, %{"prop1" => %{}}
      assert_invalid root, %{"prop2" => %{}}
    end

    test "properties (as list)" do
      root = build(properties(prop1: %{type: :string}, prop2: %{type: :integer}))

      assert_valid root, %{"prop1" => "value"}
      assert_valid root, %{"prop2" => 123}
      assert_valid root, %{"prop1" => "value", "prop2" => 123}
      assert_valid root, %{}
      assert_valid root, "not an object"
      assert_valid root, 123
      assert_valid root, nil

      assert_invalid root, %{"prop1" => %{}}
      assert_invalid root, %{"prop2" => %{}}
    end

    test "props (as map)" do
      root = build(props(%{prop1: %{type: :string}, prop2: %{type: :integer}}))

      assert_valid root, %{"prop1" => "value"}
      assert_valid root, %{"prop2" => 123}
      assert_valid root, %{"prop1" => "value", "prop2" => 123}
      assert_valid root, %{}

      assert_invalid root, %{"prop1" => %{}}
      assert_invalid root, %{"prop2" => %{}}
      assert_invalid root, "not an object"
      assert_invalid root, 123
      assert_invalid root, nil
    end

    test "props (as list)" do
      root = build(props(prop1: %{type: :string}, prop2: %{type: :integer}))

      assert_valid root, %{"prop1" => "value"}
      assert_valid root, %{"prop2" => 123}
      assert_valid root, %{"prop1" => "value", "prop2" => 123}
      assert_valid root, %{}

      assert_invalid root, %{"prop1" => %{}}
      assert_invalid root, %{"prop2" => %{}}
      assert_invalid root, "not an object"
      assert_invalid root, 123
      assert_invalid root, nil
    end

    test "ref" do
      root = build(ref("#/$defs/an_int", %{"$defs": %{an_int: %{type: :integer}}}))

      assert_valid root, 1

      assert_invalid root, "not an int"
      assert_invalid root, nil
    end

    test "all_of" do
      root = build(all_of([%{type: :integer}, %{minimum: 1, maximum: 10}]))

      assert_valid root, 1
      assert_valid root, 5
      assert_valid root, 10

      assert_invalid root, 0
      assert_invalid root, 11
      assert_invalid root, "string"
      assert_invalid root, true
      assert_invalid root, nil
    end

    test "any_of" do
      root = build(any_of([%{type: :string}, %{type: :integer, minimum: 0}]))

      assert_valid root, "hello"
      assert_valid root, 0
      assert_valid root, 1

      assert_invalid root, -1
      assert_invalid root, true
      assert_invalid root, nil
      assert_invalid root, %{}
    end

    test "one_of" do
      root = build(one_of([%{type: :integer, maximum: 5}, %{type: :integer, minimum: 10}]))

      assert_valid root, 1
      assert_valid root, 3
      assert_valid root, 5
      assert_valid root, 10
      assert_valid root, 15

      assert_invalid root, 6
      assert_invalid root, 9
      assert_invalid root, "string"
      assert_invalid root, true
      assert_invalid root, nil
    end

    test "const" do
      root = build(const(1))

      assert_valid root, 1

      assert_invalid root, 2
      assert_invalid root, :hello
      assert_invalid root, "1"
      assert_invalid root, "HELLO"
      assert_invalid root, "null"
      assert_invalid root, :null
    end

    test "enum" do
      root = build(enum([1, "hello", nil]))

      assert_valid root, 1
      assert_valid root, 1.0
      assert_valid root, "hello"
      assert_valid root, nil

      assert_invalid root, 2
      assert_invalid root, :hello
      assert_invalid root, "1"
      assert_invalid root, "HELLO"
      assert_invalid root, "null"
      assert_invalid root, :null
    end

    test "string_enum_to_atom" do
      root = build(string_enum_to_atom([:aaa, :bbb, :ccc, nil]))

      assert_cast root, "aaa", :aaa
      assert_cast root, "bbb", :bbb
      assert_cast root, "ccc", :ccc
      assert_cast root, "nil", nil

      assert_invalid root, "ddd"
      assert_invalid root, 123
      assert_invalid root, true
      assert_invalid root, false
      assert_invalid root, :some_existing_atom
      assert_invalid root, nil
      assert_invalid root, "null"
      assert_invalid root, :aaa
    end

    test "string_enum_to_atom_or_nil" do
      root = build(string_enum_to_atom_or_nil([:aaa, :bbb, :ccc]))

      assert_cast root, "aaa", :aaa
      assert_cast root, "bbb", :bbb
      assert_cast root, "ccc", :ccc
      assert_cast root, nil, nil

      assert_invalid root, "ddd"
      assert_invalid root, 123
      assert_invalid root, true
      assert_invalid root, false
      assert_invalid root, :some_existing_atom
      assert_invalid root, "nil"
      assert_invalid root, "null"
      assert_invalid root, :aaa
    end

    # Casting cases

    test "string_to_number" do
      root = build(string_to_number())

      assert_valid root, "1"
      assert_valid root, "-10"
      assert_valid root, "0"
      assert_valid root, "1.5"
      assert_valid root, "-10.3"
      assert_valid root, "0.0"
      assert_valid root, "1e5"
      assert_valid root, "1.0e-3"

      assert_invalid root, "one"
      assert_invalid root, "1a"
      assert_invalid root, ""
      assert_invalid root, nil
      assert_invalid root, 1
      assert_invalid root, 1.5
    end

    test "string_to_boolean" do
      root = build(string_to_boolean())

      assert_cast root, "true", true
      assert_cast root, "false", false

      assert_invalid root, "True"
      assert_invalid root, "1"
      assert_invalid root, "yes"
      assert_invalid root, 1
      assert_invalid root, 0
      assert_invalid root, true
      assert_invalid root, false
      assert_invalid root, nil
    end

    test "string_to_integer" do
      root = build(string_to_integer())

      assert_cast root, "1", 1
      assert_cast root, "-10", -10
      assert_cast root, "0", 0

      assert_invalid root, "1.5"
      assert_invalid root, "one"
      assert_invalid root, "1a"
      assert_invalid root, "1e5"
      assert_invalid root, ""
      assert_invalid root, nil
      assert_invalid root, 123
    end

    test "string_to_float" do
      root = build(string_to_float())

      assert_cast root, "1.5", 1.5
      assert_cast root, "-10.3", -10.3
      assert_cast root, "0.0", 0.0
      assert_cast root, "1e5", 1.0e5
      assert_cast root, "1.0e-3", 1.0e-3

      assert_invalid root, "one"
      assert_invalid root, "1a"
      assert_invalid root, ""
      assert_invalid root, nil
      assert_invalid root, 1.5
    end

    test "string_to_existing_atom" do
      # ensure atoms exist before testing
      _ = :some_existing_atom

      root = build(string_to_existing_atom())

      assert_cast root, "true", true
      assert_cast root, "false", false
      assert_cast root, "nil", nil
      assert_cast root, "some_existing_atom", :some_existing_atom

      assert_invalid root, "some_atom_that_does_not_exist"
      assert_invalid root, 123
      assert_invalid root, true
      assert_invalid root, false
      assert_invalid root, :some_existing_atom
      assert_invalid root, nil
    end

    test "string_to_atom" do
      root = build(string_to_atom())
      unique = "any_string#{:erlang.unique_integer()}"

      assert_cast root, "true", true
      assert_cast root, "false", false
      assert_cast root, "nil", nil
      assert_cast root, unique, String.to_atom(unique)
      assert_cast root, "hello world", :"hello world"

      assert_invalid root, 123
      assert_invalid root, true
      assert_invalid root, false
      assert_invalid root, :some_unexisting_atom
      assert_invalid root, nil
    end

    test "guard clauses are handled by the compiler helper - props" do
      assert %{properties: %{a: _}} = props(a: true)
      assert %{properties: %{a: _}} = props(%{a: true})

      assert_raise FunctionClauseError, fn ->
        props(erase_type(1))
      end
    end

    test "guard clauses are handled by the compiler helper - all_of" do
      assert %{allOf: [%{type: :integer}]} = all_of([%{type: :integer}])

      assert_raise FunctionClauseError, fn ->
        all_of(erase_type(%{type: :integer}))
      end
    end

    test "guard clauses are handled by the compiler helper - any_of" do
      assert %{anyOf: [%{type: :integer}]} = any_of([%{type: :integer}])

      assert_raise FunctionClauseError, fn ->
        any_of(erase_type(%{type: :integer}))
      end
    end

    test "guard clauses are handled by the compiler helper - one_of" do
      assert %{oneOf: [%{type: :integer}]} = one_of([%{type: :integer}])

      assert_raise FunctionClauseError, fn ->
        one_of(erase_type(%{type: :integer}))
      end
    end
  end

  describe "aprops (as map)" do
    test "converts defined property keys to atoms" do
      root = build(aprops(%{name: string(), age: integer()}))
      assert_cast root, %{"name" => "Alice", "age" => 30}, %{name: "Alice", age: 30}
    end

    test "additional properties keep string keys" do
      root = build(aprops(%{name: string()}))
      assert_cast root, %{"name" => "Alice", "extra" => "value"}, %{:name => "Alice", "extra" => "value"}
    end

    test "absent defined properties are not inserted" do
      root = build(aprops(%{name: string(), age: integer()}))
      assert_cast root, %{"name" => "Alice"}, %{name: "Alice"}
    end

    test "empty properties" do
      root = build(aprops(%{}))
      assert_cast root, %{}, %{}
      assert_cast root, %{"extra" => "value"}, %{"extra" => "value"}
    end

    test "rejects non-object values" do
      root = build(aprops(%{name: string()}))
      assert_invalid root, "not an object"
      assert_invalid root, 123
      assert_invalid root, nil
      assert_invalid root, []
    end

    test "without cast: false, keys remain as strings" do
      root = build(aprops(%{name: string()}))
      {:ok, result} = JSV.validate(%{"name" => "Alice"}, root, cast: false)
      assert result == %{"name" => "Alice"}
    end

    test "required properties given as atoms" do
      root = build(aprops(%{name: string(), age: integer()}, required: [:name]))
      assert_cast root, %{"name" => "Alice"}, %{name: "Alice"}
      assert_invalid root, %{"age" => 30}
    end

    test "required properties given as strings" do
      root = build(aprops(%{name: string(), age: integer()}, required: ["name"]))
      assert_cast root, %{"name" => "Alice"}, %{name: "Alice"}
      assert_invalid root, %{"age" => 30}
    end

    test "required violation does not produce partial cast" do
      root = build(aprops(%{name: string(), age: integer()}, required: ["name", "age"]))
      assert_invalid root, %{"name" => "Alice"}
    end

    test "defined with string keys in schema map" do
      root = build(aprops(%{"name" => string(), "age" => integer()}))
      assert_cast root, %{"name" => "Alice", "age" => 30}, %{name: "Alice", age: 30}
    end

    test "property names that are not valid identifiers become special-form atoms" do
      root = build(aprops(%{"foo-bar" => string(), "with space" => integer()}))
      assert_cast root, %{"foo-bar" => "value", "with space" => 42}, %{"foo-bar": "value", "with space": 42}
    end

    test "additionalProperties: false rejects extra keys" do
      root = build(aprops(%{name: string()}, additionalProperties: false))
      assert_cast root, %{"name" => "Alice"}, %{name: "Alice"}
      assert_invalid root, %{"name" => "Alice", "extra" => "value"}
    end

    test "additionalProperties as a schema keeps extras as string keys" do
      root = build(aprops(%{name: string()}, additionalProperties: integer()))
      assert_cast root, %{"name" => "Alice", "count" => 42}, %{:name => "Alice", "count" => 42}
      assert_invalid root, %{"name" => "Alice", "count" => "not_int"}
    end

    test "patternProperties-only keys keep string keys" do
      root = build(aprops(%{name: string()}) ~> %{patternProperties: %{"^x_" => %{type: :string}}})

      assert_cast root, %{"name" => "Alice", "x_custom" => "val"}, %{:name => "Alice", "x_custom" => "val"}
    end

    test "key matching both patternProperties and properties is atomized" do
      root = build(aprops(%{name: string()}) ~> %{patternProperties: %{"^na" => %{type: :string}}})

      # "name" starts with "na" so it matches the pattern, but it's also defined => atom
      assert_cast root, %{"name" => "Alice", "narrow" => "road"}, %{:name => "Alice", "narrow" => "road"}
    end

    test "nested aprops are each atomized" do
      root = build(aprops(%{user: aprops(%{name: string(), age: integer()})}))

      assert_cast root, %{"user" => %{"name" => "Alice", "age" => 30}}, %{user: %{name: "Alice", age: 30}}
    end

    test "inside array_of each element is atomized" do
      root = build(array_of(aprops(%{id: integer(), label: string()})))

      assert_cast root,
                  [%{"id" => 1, "label" => "a"}, %{"id" => 2, "label" => "b"}],
                  [%{id: 1, label: "a"}, %{id: 2, label: "b"}]
    end

    test "guard clauses are handled by the compiler helper" do
      assert %{type: :object, properties: %{a: _}} = aprops(%{a: true})

      assert_raise FunctionClauseError, fn ->
        aprops(erase_type(1))
      end
    end
  end

  describe "aprops (as list)" do
    test "keyword list syntax converts defined keys to atoms" do
      root = build(aprops(name: string(), age: integer()))
      assert_cast root, %{"name" => "Alice", "age" => 30}, %{name: "Alice", age: 30}
    end

    test "additional properties keep string keys" do
      root = build(aprops(name: string()))
      assert_cast root, %{"name" => "Alice", "extra" => "value"}, %{:name => "Alice", "extra" => "value"}
    end

    test "empty keyword list" do
      root = build(aprops([]))
      assert_cast root, %{"key" => "value"}, %{"key" => "value"}
    end

    test "string key tuple syntax: [{string, schema}]" do
      root = build(aprops([{"name", string()}, {"age", integer()}]))
      assert_cast root, %{"name" => "Alice", "age" => 30}, %{name: "Alice", age: 30}
    end

    test "mixed atom and string key tuple list" do
      root = build(aprops([{:name, string()}, {"age", integer()}]))
      assert_cast root, %{"name" => "Alice", "age" => 30}, %{name: "Alice", age: 30}
    end

    test "guard clauses are handled by the compiler helper" do
      assert %{type: :object, properties: %{a: _}} = aprops(a: true)

      assert_raise FunctionClauseError, fn ->
        aprops(erase_type(1))
      end
    end
  end

  describe "aprops with atoms: false" do
    defp build_no_atoms(schema) do
      JSV.build!(schema, formats: true, atoms: false)
    end

    test "valid input is accepted and keys remain as strings" do
      root = build_no_atoms(aprops(name: string(), age: integer()))
      assert_valid root, %{"name" => "Alice", "age" => 30}
    end

    test "invalid input is still rejected" do
      root = build_no_atoms(aprops(name: string(), age: integer()))
      assert_invalid root, %{"name" => 123}
      assert_invalid root, "not an object"
    end

    test "atom keys are not produced when atoms: false" do
      root = build_no_atoms(aprops(name: string(), age: integer()))
      {:ok, result} = JSV.validate(%{"name" => "Alice", "age" => 30}, root)
      assert result == %{"name" => "Alice", "age" => 30}
      refute match?(%{name: _}, result)
    end

    test "required constraints still apply" do
      root = build_no_atoms(aprops(%{name: string(), age: integer()}, required: ["name"]))
      assert_valid root, %{"name" => "Alice"}
      assert_invalid root, %{"age" => 30}
    end

    test "additionalProperties: false still rejects extras" do
      root = build_no_atoms(aprops(%{name: string()}, additionalProperties: false))
      assert_valid root, %{"name" => "Alice"}
      assert_invalid root, %{"name" => "Alice", "extra" => "value"}
    end
  end

  describe "arprops (as map)" do
    test "all defined properties are required" do
      root = build(arprops(%{name: string(), age: integer()}))
      assert_cast root, %{"name" => "Alice", "age" => 30}, %{name: "Alice", age: 30}
      assert_invalid root, %{"name" => "Alice"}
      assert_invalid root, %{"age" => 30}
      assert_invalid root, %{}
    end

    test "defined properties get atom keys, additional keep string keys" do
      root = build(arprops(%{name: string()}))
      assert_cast root, %{"name" => "Alice", "extra" => "value"}, %{:name => "Alice", "extra" => "value"}
    end

    test "rejects non-object values" do
      root = build(arprops(%{name: string()}))
      assert_invalid root, "not an object"
      assert_invalid root, nil
    end

    test "defined with string keys in schema map" do
      root = build(arprops(%{"name" => string(), "age" => integer()}))
      assert_cast root, %{"name" => "Alice", "age" => 30}, %{name: "Alice", age: 30}
      assert_invalid root, %{"name" => "Alice"}
    end

    test "extra schema attributes are respected" do
      root = build(arprops(%{name: string()}, additionalProperties: false))
      assert_cast root, %{"name" => "Alice"}, %{name: "Alice"}
      assert_invalid root, %{"name" => "Alice", "extra" => "value"}
    end
  end

  describe "arprops (as list)" do
    test "keyword list: all defined properties are required" do
      root = build(arprops(name: string(), age: integer()))
      assert_cast root, %{"name" => "Alice", "age" => 30}, %{name: "Alice", age: 30}
      assert_invalid root, %{"name" => "Alice"}
    end

    test "string key tuple syntax" do
      root = build(arprops([{"name", string()}, {"age", integer()}]))
      assert_cast root, %{"name" => "Alice", "age" => 30}, %{name: "Alice", age: 30}
      assert_invalid root, %{"name" => "Alice"}
    end

    test "empty list requires nothing" do
      root = build(arprops([]))
      assert_cast root, %{}, %{}
      assert_cast root, %{"extra" => "value"}, %{"extra" => "value"}
    end
  end

  describe "the ~> operator" do
    test "merging two schemas" do
      schema =
        pos_integer(description: "old")
        ~> string_of("date", description: "new")
        ~> any_of([integer(), string()])

      assert %{
               type: :string,
               description: "new",
               minimum: 1,
               format: "date",
               anyOf: [%{type: :integer}, %{type: :string}]
             } = schema
    end
  end
end
