defmodule JSV.Vocabulary.V202012.MetaData do
  use JSV.Vocabulary, priority: 300

  @impl true
  def init_validators(_) do
    []
  end

  @impl true
  consume_keyword("deprecated")
  consume_keyword("description")
  consume_keyword("default")
  consume_keyword("title")
  consume_keyword("readOnly")
  consume_keyword("writeOnly")
  consume_keyword("examples")

  ignore_any_keyword()
  @impl true
  def finalize_validators(_) do
    :ignore
  end

  @impl true
  def validate(_data, _validators, _context) do
    raise "should not be called"
  end
end
