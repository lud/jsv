defmodule JSV.BuildError do
  @moduledoc """
  A simple wrapper for errors returned from `JSV.build/2`.
  """

  @enforce_keys [:reason, :action, :build_path]
  defexception @enforce_keys

  @doc """
  Wraps the given term as the `reason` in a `#{inspect(__MODULE__)}` struct.

  The `action` should be a `{module, function, [arg1, arg2, ..., argN]}` tuple or
  a mfa tuple whenever possible.
  """

  @spec of(term, term, build_path :: nil | String.t()) :: Exception.t()
  def of(reason, action, build_path \\ nil) do
    %__MODULE__{reason: reason, action: action, build_path: build_path}
  end

  @impl true
  def message(%{reason: reason, action: {m, f, a}}) when is_atom(m) and is_atom(f) and (is_list(a) or is_integer(a)) do
    """
    could not build JSON schema

    REASON
    #{inspect(reason, pretty: true)}

    action
    #{Exception.format_mfa(m, f, a)}
    """
  end

  def message(e) do
    "could not build JSON schema got error: #{inspect(e.reason)} in context #{inspect(e.action)}"
  end
end
