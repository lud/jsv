defmodule JSV.CodecTest do
  alias JSV.Codec
  alias JSV.Codec.JasonCodec
  alias JSV.Codec.NativeCodec

  use ExUnit.Case, async: true

  describe "ordered encoding" do
    defp sample_ordering_data do
      %{
        minimum: 100,
        default: 200,
        if: %{
          minimum: 200,
          default: 200,
          if: %{
            a: "va",
            b: "vb"
          }
        }
      }
    end

    # we will have keys in reverse order to be sure ordering is done, except `if`
    # will be first.
    defp sample_key_sorter(a, b) do
      case {a, b} do
        {:if, _} -> true
        {_, :if} -> false
        _ -> a > b
      end
    end

    defp expected_ordered_json do
      json =
        """
        {
          "if": {
            "if": {
              "b": "vb",
              "a": "va"
            },
            "minimum": 200,
            "default": 200
          },
          "minimum": 100,
          "default": 200
        }
        """

      String.trim(json)
    end

    # We will compare the values trimmed since the native encoder and Jason have
    # different behaviours.

    defp call_sort_encoder(module) do
      iodata = Codec.format_ordered_to_iodata!(module, sample_ordering_data(), &sample_key_sorter/2)

      iodata
      |> IO.iodata_to_binary()
      |> String.trim()
    end

    test "with Jason" do
      assert expected_ordered_json() == call_sort_encoder(JSV.Codec.JasonCodec)
    end

    cond do
      Code.ensure_loaded?(JSV.Codec.NativeCodec) && JSV.Codec.NativeCodec.supports_ordered_formatting?() ->
        test "with Native" do
          assert expected_ordered_json() == call_sort_encoder(JSV.Codec.NativeCodec)
        end

      Code.ensure_loaded?(JSV.Codec.NativeCodec) ->
        test "with Native" do
          assert_raise RuntimeError, ~r/ordered JSON encoding requires Jason/, fn ->
            call_sort_encoder(JSV.Codec.NativeCodec)
          end
        end

      :otherwise ->
        IO.puts("no native JSON codec test")
    end

    if Code.ensure_loaded?(JasonCodec) do
      test "formatting support from Jason" do
        assert is_boolean(JasonCodec.supports_ordered_formatting?())
        assert is_boolean(JasonCodec.supports_formatting?())
      end
    end

    if Code.ensure_loaded?(NativeCodec) do
      test "formatting support from native" do
        assert is_boolean(NativeCodec.supports_ordered_formatting?())
        assert is_boolean(NativeCodec.supports_formatting?())
      end
    end
  end

  describe "JSON protocol implementation" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "$id" => "https://test.json-schema.org/dynamicRef-dynamicAnchor-same-schema/root",
        "$defs" => %{"foo" => %{"$dynamicAnchor" => "items", "type" => "string"}},
        "type" => "array",
        "items" => %{"$dynamicRef" => "#items"}
      }

      invalid_data = ["foo", 42]

      root = JSV.build!(schema)
      assert {:error, jsv_err} = JSV.validate(invalid_data, root)

      %{sample_error: jsv_err}
    end

    test "Jason", ctx do
      actual = ctx.sample_error |> Jason.encode!() |> Jason.decode!()

      expected_decoded =
        ctx.sample_error
        |> JSV.normalize_error()
        |> Jason.encode!()
        |> Jason.decode!()

      assert expected_decoded == actual
    end

    if Code.ensure_loaded?(JSV.Codec.NativeCodec) do
      test "Native", ctx do
        actual = ctx.sample_error |> JSON.encode!() |> JSON.decode!()

        expected_decoded =
          ctx.sample_error
          |> JSV.normalize_error()
          |> JSON.encode!()
          |> JSON.decode!()

        assert expected_decoded == actual
      end
    else
      IO.puts("no native JSON protocol test")
    end
  end
end
