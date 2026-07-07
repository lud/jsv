defprotocol JSV.Normalizer.Normalize do
  @moduledoc """
  Protocol used by `JSV.Normalizer` to transform structs into JSON-compatible
  data structures when normalizing a schema.

  When implementing this protocol you do not need to run any specific
  normalization by yourself, but rather just return a map with all or a
  selection of keys. Keys can be atoms or binaries, and values will be
  normalized recursively.
  """
  @doc """
  Returns a JSON-compatible representation of the given term. Maps returned
  from this function can have atom or binary keys and their values are
  normalized recursively.
  """
  @spec normalize(term) :: term
  def normalize(t)
end
