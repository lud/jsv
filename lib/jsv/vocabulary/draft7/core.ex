defmodule JSV.Vocabulary.Draft7.Core do
  alias JSV.Ref
  alias JSV.Vocabulary.V202012.Core, as: Fallback
  use JSV.Vocabulary, priority: 100

  defdelegate init_validators(opts), to: Fallback

  take_keyword :"$ref", raw_ref, _acc, bld, raw_schema do
    ref_relative_to_ns =
      case {raw_schema, bld} do
        # The ref is not relative to the current $id if defined at the same
        # level and there is a parent $id.
        #
        # Parent cannot be :root because a ref cannot target :root, it must be a
        # defined $id.
        {%{"$id" => _}, %{ns: _, parent_ns: parent}} when parent != :root ->
          parent

        # Otherwise take the $id at the same level or higher
        {_, %{ns: current_ns}} ->
          current_ns
      end

    with {:ok, ref} <- Ref.parse(raw_ref, ref_relative_to_ns) do
      # reset the acc as $ref overrides any other keyword
      Fallback.ok_put_ref(ref, [], bld)
    end
  end

  # $ref overrides any other keyword
  def handle_keyword(_kw_tuple, acc, bld, raw_schema) when is_map_key(raw_schema, "$ref") do
    {:ok, acc, bld}
  end

  defdelegate handle_keyword(kw_tuple, acc, bld, raw_schema), to: Fallback

  defdelegate finalize_validators(acc), to: Fallback

  defdelegate validate(data, vds, vdr), to: Fallback
end
