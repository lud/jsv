defmodule JSV.Vocabulary.V202012.Format do
  alias JSV.Builder
  alias JSV.Validator
  use JSV.Vocabulary, priority: 700

  @moduledoc """
  Implementation for the
  `https://json-schema.org/draft/2020-12/vocab/format-annotation` and
  `https://json-schema.org/draft/2020-12/vocab/format-assertion` vocabularies.
  """

  @impl true
  def init_validators(opts) do
    # The assert option is defined at the vocabulary level, as vocabularies are
    # defined like so:
    # "https://json-schema.org/draft/2020-12/vocab/format-annotation" =>
    #     Vocabulary.V202012.Format,
    # "https://json-schema.org/draft/2020-12/vocab/format-assertion" =>
    #     {Vocabulary.V202012.Format, assert: true},

    default_assert =
      case Keyword.fetch(opts, :assert) do
        {:ok, true} -> true
        _ -> false
      end

    %{default_assert: default_assert}
  end

  take_keyword :format, format, acc, builder, _ do
    validator_mods =
      case builder.opts[:formats] do
        # opt in / out, use defaults mods
        bool when is_boolean(bool) -> validation_modules_or_none(bool)
        # no opt-in/out, use default for vocabulary "assert" opt
        default when default in [nil, :default] -> validation_modules_or_none(acc.default_assert)
        # modules provided, use that
        list when is_list(list) -> list
      end

    case validator_mods do
      :none -> {acc, builder}
      _ -> add_format(validator_mods, format, acc, builder)
    end
  end

  ignore_any_keyword()

  defp validation_modules_or_none(false) do
    :none
  end

  defp validation_modules_or_none(true) do
    JSV.default_format_validator_modules()
  end

  defp add_format(validator_mods, format, acc, builder) do
    case Enum.find(validator_mods, :__no_mod__, fn mod -> format in mod.supported_formats() end) do
      :__no_mod__ -> Builder.fail(builder, {:unsupported_format, format}, nil)
      module -> {Map.put(acc, :format, {module, format}), builder}
    end
  end

  @impl true
  def finalize_validators(acc) do
    acc
    |> Map.delete(:default_assert)
    |> Map.to_list()
    |> case do
      [] -> :ignore
      [{:format, _}] = list -> list
    end
  end

  @impl true
  def validate(data, [format: {module, format}], vctx) when is_binary(data) do
    cast_formats? = vctx.opts[:cast_formats]

    case module.validate_cast(format, data) do
      {:ok, casted} when cast_formats? ->
        {:ok, casted, vctx}

      {:ok, _casted} ->
        {:ok, data, vctx}

      {:error, reason} ->
        {:error, Validator.with_error(vctx, :format, data, format: format, reason: json_encodable_or_inspect(reason))}

      other ->
        raise "invalid return from #{module}.validate/2 called with format #{inspect(format)}, got: #{inspect(other)}"
    end
  end

  @impl true
  def validate(data, [format: _], vctx) do
    {:ok, data, vctx}
  end

  if Code.ensure_loaded?(Poison.EncodeError) do
    defp json_encodable_or_inspect(term) do
      JSV.Codec.encode!(term)
    rescue
      _ in Protocol.UndefinedError -> inspect(term)
      _ in Poison.EncodeError -> inspect(term)
    end
  else
    defp json_encodable_or_inspect(term) do
      JSV.Codec.encode!(term)
    rescue
      _ in Protocol.UndefinedError -> inspect(term)
    end
  end

  # ---------------------------------------------------------------------------

  @impl true
  def format_error(:format, %{format: format, reason: reason}, _data) do
    "value does not respect the '#{format}' format (#{inspect(reason)})"
  end
end
