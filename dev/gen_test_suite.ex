# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Mix.Tasks.Jsv.GenTestSuite do
  alias CliMate.CLI
  use Mix.Task

  @shortdoc "Regenerate the JSON Schema Test Suite"
  @moduledoc false

  @command [
    module: __MODULE__,
    arguments: [
      suite: [
        type: :string,
        short: :s,
        doc: """
        The json test suite in 'draft2019-09', 'draft2020-12', 'draft3', 'draft4',
        'draft6', 'draft7', 'draft-next' or 'latest'.
        """
      ]
    ],
    options: []
  ]

  @impl true
  def run(argv) do
    %{options: _options, arguments: %{suite: suite}} = CLI.parse_or_halt!(argv, @command)
    JSV.TestSuiteGenerator.run(suite)
  end
end
