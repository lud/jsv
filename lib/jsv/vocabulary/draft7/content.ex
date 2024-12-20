defmodule JSV.Vocabulary.Draft7.Content do
  alias JSV.Vocabulary.V202012.Content, as: Fallback
  use JSV.Vocabulary, priority: 300

  defdelegate init_validators(opts), to: Fallback

  ignore_keyword(:contentSchema)
  defdelegate handle_keyword(kw_tuple, acc, builder, raw_schema), to: Fallback

  defdelegate finalize_validators(acc), to: Fallback

  @spec validate(term, term, term) :: no_return()
  def validate(_data, _validators, _context) do
    raise "should not be called"
  end
end
