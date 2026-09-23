defmodule JSV.Warnings do
  alias JSV.Helpers.OptsValidator

  @moduledoc false

  @type warning :: %{
          required(:key) => atom,
          required(:message) => String.t(),
          optional(:rev_path) => [term],
          optional(atom) => term
        }
  @type silence :: atom | {atom, term}
  @type config :: :emit | :silence | {:silence, [silence]}

  @spec validate_config!(atom, term) :: config
  def validate_config!(key, value) do
    case value do
      :emit -> :emit
      :silence -> :silence
      :silent -> :silence
      {:silence, silences} when is_list(silences) -> {:silence, validate_silences!(key, value, silences)}
      other -> invalid_config!(key, other)
    end
  end

  defp validate_silences!(key, value, silences) do
    Enum.each(silences, fn
      key when is_atom(key) -> :ok
      {key, _} when is_atom(key) -> :ok
      _ -> invalid_config!(key, value)
    end)

    silences
  end

  @spec invalid_config!(atom, term) :: no_return()
  defp invalid_config!(key, value) do
    OptsValidator.invalid_option!(key, value, ":emit, :silence or {:silence, [atom | {atom, term}]}")
  end

  @spec emit([warning], config, Exception.stacktrace()) :: :ok
  def emit(warnings, config, stacktrace)

  def emit(_warnings, :silence, _stacktrace) do
    :ok
  end

  def emit(warnings, :emit, stacktrace) do
    Enum.each(warnings, &emit_warning(&1, stacktrace))
  end

  def emit(warnings, {:silence, silences}, stacktrace) do
    Enum.each(warnings, fn warning ->
      if !silenced?(warning, silences) do
        emit_warning(warning, stacktrace)
      end
    end)
  end

  @spec silenced?(warning, [silence]) :: boolean
  def silenced?(warning, silences) do
    Enum.any?(silences, &silence_matches?(&1, warning))
  end

  defp silence_matches?(key, %{key: key}) when is_atom(key) do
    true
  end

  defp silence_matches?({:unresolved_module, module}, %{key: :unresolved_module, module: module}) do
    true
  end

  defp silence_matches?(_silence, _warning) do
    false
  end

  defp silence_of(%{key: :unresolved_module, module: module}) do
    {:unresolved_module, module}
  end

  defp silence_of(%{key: key}) do
    key
  end

  defp emit_warning(warning, stacktrace) do
    IO.warn(
      """
      #{warning.message}
      #{format_location(warning)}
      Use the `warnings: {:silence, #{inspect([silence_of(warning)])}}` option to silence this warning.
      """,
      stacktrace
    )
  end

  defp format_location(%{rev_path: rev_path}) do
    "\nWarning emitted at #{JSV.ErrorFormatter.format_schema_path(rev_path)}.\n"
  end

  defp format_location(_warning) do
    ""
  end
end
