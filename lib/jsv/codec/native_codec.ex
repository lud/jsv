# credo:disable-for-this-file Credo.Check.Readability.Specs

if Code.ensure_loaded?(JSON) do
  defmodule JSV.Codec.NativeCodec do
    @moduledoc false
    alias JSV.Helpers.Traverse

    def decode!(json) do
      JSON.decode!(json)
    end

    def decode(json) do
      JSON.decode(json)
    end

    def encode_to_iodata!(data) do
      JSON.encode_to_iodata!(data)
    end

    cond do
      Code.ensure_loaded?(:json) && function_exported?(:json, :format, 3) ->
        def format_to_iodata!(data) do
          :json.format(data, &json_formatter/3, %{indent: 2})
        end

      Code.ensure_loaded?(:json) && function_exported?(:json, :format, 1) ->
        def format_to_iodata!(data) do
          :json.format(data)
        end

      true ->
        # Formatting will not be supported
        def format_to_iodata!(data) do
          encode_to_iodata!(data)
        end
    end

    if Code.ensure_loaded?(:json) && function_exported?(:json, :format, 3) do
      defmodule OrderedObject do
        @moduledoc false
        defstruct [:values]

        @spec new([{atom | binary, term}]) :: struct
        def new(values) do
          %__MODULE__{values: values}
        end
      end

      @spec to_ordered_data(term, term) :: term()
      def to_ordered_data(data, key_sorter) do
        Traverse.postwalk(data, fn
          {:val, map} when is_map(map) ->
            map
            |> Map.to_list()
            |> Enum.sort(fn {ka, _}, {kb, _} -> key_sorter.(ka, kb) end)
            |> OrderedObject.new()

          {:val, v} ->
            v

          {:key, k} ->
            k

          {:struct, struct, _cont} ->
            raise ArgumentError, "ordered JSON encoding does not support structs, got: #{inspect(struct)}"
        end)
      end

      defp json_formatter(%OrderedObject{} = oo, encode, state) do
        :json.format_key_value_list_checked(oo.values, encode, state)
      end

      defp json_formatter(other, encode, state) do
        :json.format_value(other, encode, state)
      end
    else
      @spec to_ordered_data(term, term) :: no_return()
      def to_ordered_data(_data, _key_sorter) do
        raise "ordered JSON encoding requires Jason prior to OTP 27.1, current version is: #{JSV.otp_version()}"
      end
    end
  end
end
