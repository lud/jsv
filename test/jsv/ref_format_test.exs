# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule JSV.RefFormatTest do
  alias JSV.Ref
  use ExUnit.Case, async: true

  defp assert_roundtrip_as_inspect_code(%Ref{} = ref) do
    parse_code = inspect(ref)
    {rebuilt_ref, _binding} = Code.eval_string(parse_code)

    assert ref == rebuilt_ref
  end

  test "String.Chars outputs canonical reference strings" do
    assert "" == to_string(Ref.parse!("", :root))
    assert "#foo" == to_string(Ref.parse!("#foo", :root))
    assert "#/properties/name" == to_string(Ref.parse!("#/properties/name", :root))

    assert "#/properties/path~1name~0tilde/user%20name" ==
             to_string(Ref.parse!("#/properties/path~1name~0tilde/user%20name", :root))

    assert "http://example.com/schema.json" ==
             to_string(Ref.parse!("http://example.com/schema.json", :root))

    assert "http://example.com/schema.json#/properties/name" ==
             to_string(Ref.parse!("http://example.com/schema.json#/properties/name", :root))
  end

  test "String.Chars drops dynamic marker information" do
    ref = Ref.parse_dynamic!("#meta", "http://example.com/schema.json")

    assert "http://example.com/schema.json#meta" == to_string(ref)
  end

  test "Inspect outputs parse code for regular references" do
    refs = [
      Ref.parse!("", :root),
      Ref.parse!("http://example.com/schema.json", :root),
      Ref.parse!("#foo", :root),
      Ref.parse!("#foo", "schema.json"),
      Ref.parse!("#/properties/name", :root),
      Ref.parse!("#/items/0", :root),
      Ref.parse!("#/properties/path~1name~0tilde/user%20name", :root)
    ]

    Enum.each(refs, &assert_roundtrip_as_inspect_code/1)
  end

  test "Inspect outputs parse_dynamic! code for dynamic references" do
    ref = Ref.parse_dynamic!("#meta", "http://example.com/schema.json")

    assert ~s|JSV.Ref.parse_dynamic!("#meta", "http://example.com/schema.json")| ==
             inspect(ref)

    assert_roundtrip_as_inspect_code(ref)
  end

  test "Inspect outputs fake Elixir code" do
    ref = Ref.parse!("#/properties/name", :root)

    assert "#/properties/name" == to_string(ref)
    assert "JSV.Ref.parse!(\"#/properties/name\", :root)" == inspect(ref)
    assert_roundtrip_as_inspect_code(ref)
  end

  test "inspects as parseable" do
    # Keep one example per ns/kind/dynamic? combination.
    refs = [
      %Ref{ns: :root, kind: :top, arg: [], dynamic?: false},
      %Ref{ns: :root, kind: :anchor, arg: "foo", dynamic?: false},
      %Ref{ns: :root, kind: :anchor, arg: "foo", dynamic?: true},
      %Ref{ns: :root, kind: :pointer, arg: ["properties", "path/name~tilde", "user name"], dynamic?: false},
      %Ref{ns: "http://example.com/schema.json", kind: :top, arg: [], dynamic?: false},
      %Ref{ns: "http://example.com/schema.json", kind: :anchor, arg: "foo", dynamic?: false},
      %Ref{ns: "http://example.com/schema.json", kind: :anchor, arg: "meta", dynamic?: true},
      %Ref{ns: "http://example.com/schema.json", kind: :pointer, arg: ["$defs", "foo\"bar"], dynamic?: false}
    ]

    Enum.each(refs, &assert_roundtrip_as_inspect_code/1)
  end
end
