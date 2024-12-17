defmodule JSV.Root do
  alias __MODULE__
  alias JSV.BooleanSchema
  alias JSV.Builder
  alias JSV.Key
  alias JSV.Resolver

  defstruct validators: %{}, root_key: nil, raw: nil
  @opaque t :: %__MODULE__{}

  @default_draft_default "https://json-schema.org/draft/2020-12/schema"

  def build(raw_schema, opts) when is_map(raw_schema) do
    {resolver_impl, opts} = Keyword.pop!(opts, :resolver)
    {default_draft, opts} = Keyword.pop(opts, :default_draft, @default_draft_default)

    resolver_opts = %{resolver: resolver_impl, default_draft: default_draft}

    with {:ok, resolver} <- Resolver.new_root(raw_schema, resolver_opts),
         bld = Builder.new(resolver: resolver, opts: opts),
         bld = Builder.stage_build(bld, resolver.root),
         root_key = Key.of(resolver.root),
         {:ok, validators} <- Builder.build_all(bld) do
      {:ok, %Root{raw: raw_schema, validators: validators, root_key: root_key}}
    end
  end

  def build(valid?, _opts) when is_boolean(valid?) do
    {:ok, %Root{raw: valid?, root_key: :root, validators: %{root: BooleanSchema.of(valid?)}}}
  end
end
