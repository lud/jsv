defmodule JSV.Resolver.Internal do
  alias JSV.Helpers.StringExt

  @behaviour JSV.Resolver

  @moduledoc """
  A `JSV.Resolver` implementation that resolves URIs pointing to the application
  code base or JSV code base.

  A custom resolver implementation should delegate `jsv:` prefixed URIs to this
  module to enable support of the internal resolutions features.

  ### Module based schemas

  This resolver will resolve `jsv:module:MODULE` URIs where `MODULE` is a string
  representation of an Elixir module. Modules pointed at with such references
  MUST export a `json_schema/0` function that returns a normalized JSON schema
  with binary keys and values.

  ### Security considerations

  This resolver is always included in the resolver chain used by `JSV.build/2`,
  so any schema, including a schema obtained from external input, can contain a
  `jsv:module:` reference. Resolving such a reference calls `json_schema/0` on
  the target module.

  The reachable surface is narrow: only modules already known by the runtime
  can be referenced, the invoked function name and arity are fixed, and errors
  raised during resolution are returned as build errors. Keep `json_schema/0`
  implementations pure, building and returning the schema data, so that
  resolving a module reference stays free of side effects.
  """

  @uri_prefix "jsv:module:"

  @impl true
  def resolve(url, opts)

  def resolve(@uri_prefix <> module_string, _) do
    case StringExt.safe_string_to_existing_module(module_string) do
      {:ok, module} -> {:ok, JSV.Schema.from_module(module)}
      {:error, reason} -> {:error, reason}
    end
  rescue
    e -> {:error, {:invalid_schema_module, e}}
  end

  def resolve(other, _) do
    {:error, {:unsupported, other}}
  end

  @doc """
  Returns a JSV internal URI for the given module.

  ### Example

      iex> module_to_uri(Inspect.Opts)
      "jsv:module:Elixir.Inspect.Opts"
  """
  @spec module_to_uri(module) :: binary
  def module_to_uri(module) when is_atom(module) do
    @uri_prefix <> Atom.to_string(module)
  end
end
