defmodule JSV.Vocabulary.Draft7.MetaData do
  alias JSV.Vocabulary.V202012.MetaData, as: Fallback
  use JSV.Vocabulary, priority: 300

  @moduledoc """
  Implementation of the meta-data vocabulary with draft 7 sepecifiticies.
  """

  defdelegate init_validators(opts), to: Fallback

  defdelegate handle_keyword(kw_tuple, acc, builder, raw_schema), to: Fallback

  defdelegate finalize_validators(acc), to: Fallback

  @spec validate(term, term, term) :: no_return()
  def validate(_data, _validators, _context) do
    raise "should not be called"
  end
end
