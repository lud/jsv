defmodule JSV.Vocabulary.V202012.Content do
  use JSV.Vocabulary, priority: 300

  @impl true
  def init_validators(_) do
    []
  end

  @impl true
  def take_keyword({"contentMediaType", _}, acc, ctx, _) do
    {:ok, acc, ctx}
  end

  def take_keyword({"contentEncoding", _}, acc, ctx, _) do
    {:ok, acc, ctx}
  end

  def take_keyword({"contentSchema", _}, acc, ctx, _) do
    {:ok, acc, ctx}
  end

  ignore_any_keyword()

  @impl true
  def finalize_validators([]) do
    :ignore
  end

  # TODO validate content?
  @impl true
  @spec validate(term, term, term) :: no_return()
  def validate(_data, _validators, _context) do
    raise "should not be called"
  end
end
