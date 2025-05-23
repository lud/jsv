defmodule JSV.Vocabulary.V7.Format do
  alias JSV.Vocabulary.V202012.Format, as: Fallback
  use JSV.Vocabulary, priority: 300

  @moduledoc """
  Implementation of the format vocabulary with draft 7 sepecifiticies.
  """

  defdelegate init_validators(opts), to: Fallback

  defdelegate handle_keyword(kw_tuple, acc, builder, raw_schema), to: Fallback

  defdelegate finalize_validators(acc), to: Fallback

  defdelegate validate(data, vds, vctx), to: Fallback
end
