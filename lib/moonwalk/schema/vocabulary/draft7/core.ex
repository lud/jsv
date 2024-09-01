defmodule Moonwalk.Schema.Vocabulary.Draft7.Core do
  alias Moonwalk.Schema.Ref
  alias Moonwalk.Schema.Vocabulary.V202012.Core, as: Fallback
  use Moonwalk.Schema.Vocabulary, priority: 100

  @impl true
  defdelegate init_validators(opts), to: Fallback

  @impl true

  def take_keyword({"$ref", raw_ref}, _acc, bld, raw_schema) do
    ref_relative_to_ns =
      case {raw_schema, bld} do
        # The ref is not relative to the current $id if defined at the same
        # level and there is a parent $id.
        #
        # Parent cannot be :root because a ref cannot target :root, it must be a
        # defined $id.
        {%{"$id" => current_id}, %{ns: current_id, parent_nss: [parent | _]}} when parent != :root ->
          raise "what if the current_id is partial ?"
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
  def take_keyword(_kw_tuple, acc, bld, raw_schema) when is_map_key(raw_schema, "$ref") do
    {:ok, acc, bld}
  end

  defdelegate take_keyword(kw_tuple, acc, bld, raw_schema), to: Fallback

  @impl true
  defdelegate finalize_validators(acc), to: Fallback

  @impl true
  defdelegate validate(data, vds, vdr), to: Fallback
end
