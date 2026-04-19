defmodule JSV.Vocabulary.V7.Core do
  alias JSV.Ref
  alias JSV.Vocabulary.V202012.Core, as: Fallback
  use JSV.Vocabulary, priority: 100

  @moduledoc """
  Implementation of the core vocabulary with draft 7 sepecifiticies.
  """

  @impl true
  defdelegate init_validators(opts), to: Fallback

  @impl true
  take_keyword :"$ref", raw_ref, _acc, builder, raw_schema do
    ref_relative_to_ns =
      case {raw_schema, builder} do
        {%{"$id" => _}, %{ns: _, parent_ns: parent}} when is_binary(parent) ->
          # $ref and $id are siblings inside a nested subschema. We know it is in
          # a subschema because parent in a binary.
          #
          # In this case, $id does not change the base URI used to resolve $ref.
          # The $ref resolves against the enclosing parent $id instead. This only
          # applies when there is an actual outer $id (a binary).
          parent

        {_, %{ns: current_ns}} ->
          # $ref at the top-level. In that case, the sibling $id (if exists) is
          # used for the basis of $ref resolution. If it does not exist, the
          # $ref will resolve against :root.
          current_ns
      end

    ref = unwrap_ok(Ref.parse(raw_ref, ref_relative_to_ns))
    Fallback.put_ref(ref, :"$ref", [], builder)
  end

  consume_keyword :definitions

  # $ref overrides any other keyword in Draft7
  def handle_keyword(_kw_tuple, acc, builder, raw_schema) when is_map_key(raw_schema, "$ref") do
    {acc, builder}
  end

  defdelegate handle_keyword(kw_tuple, acc, builder, raw_schema), to: Fallback

  @impl true
  defdelegate finalize_validators(acc), to: Fallback

  @impl true
  defdelegate validate(data, vds, vctx), to: Fallback
end
