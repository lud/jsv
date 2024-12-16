defmodule JSV.Vocabulary.V202012.Content do
  use JSV.Vocabulary, priority: 300

  def init_validators(_) do
    []
  end

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

  def finalize_validators([]) do
    :ignore
  end

  def validate(_data, _validators, _context) do
    raise "TODO!"
  end
end
