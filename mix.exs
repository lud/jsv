defmodule JSV.MixProject do
  use Mix.Project

  @source_url "https://github.com/lud/jsv"
  def project do
    [
      app: :jsv,
      description: "A JSON Schema Validator with complete support for the latest specifications.",
      version: "0.4.0",
      elixir: "~> 1.15",
      # no protocol consolidation for the generation of the test suite
      consolidate_protocols: false,
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      source_url: @source_url,
      docs: docs(),
      test_coverage: [tool: ExCoveralls],
      package: package(),
      modkit: modkit(),
      dialyzer: dialyzer()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test) do
    ["lib", "test/support"]
  end

  defp elixirc_paths(_) do
    ["lib"]
  end

  defp deps do
    [
      # Actual dependencies
      {:nimble_options, "~> 1.0"},

      # Optional JSON support
      {:jason, "~> 1.0", optional: true},
      {:poison, "~> 6.0 or ~> 5.0", optional: true},

      # Optional Formats
      {:mail_address, "~> 1.0", optional: true},
      {:abnf_parsec, "~> 1.2.3 or ~> 1.3", optional: true},

      # Dev
      {:credo, "~> 1.7", only: [:dev, :test]},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:dialyxir, "~> 1.4", only: :test, runtime: false},
      {:modkit, "~> 0.6.1", only: :dev, runtime: false},

      # Test
      {:excoveralls, "~> 0.18", only: :test},
      {:briefly, "~> 0.5.1", only: :test},
      json_schema_test_suite()
    ]
  end

  defp json_schema_test_suite do
    {:json_schema_test_suite,
     git: "https://github.com/json-schema-org/JSON-Schema-Test-Suite.git",
     ref: "82a077498cc761d69e8530c721702be980926c89",
     only: [:dev, :test],
     compile: false,
     app: false}
  end

  defp docs do
    [
      main: "JSV",
      groups_for_modules: [
        Resolvers: [
          JSV.Resolver,
          JSV.Resolver.Embedded,
          JSV.Resolver.Httpc
        ],
        Build: [
          JSV.Builder,
          JSV.BuildError,
          JSV.Codec,
          JSV.Key,
          JSV.RNS,
          JSV.Ref,
          JSV.Resolver.Resolved
        ],
        Validation: [
          JSV.Validator,
          JSV.ValidationError,
          JSV.BooleanSchema,
          JSV.Root,
          JSV.Subschema,
          JSV.ErrorFormatter,
          JSV.Validator.Error,
          JSV.Validator.ValidationContext
        ],
        "Format Validation": [~r/^JSV\.Format.*/],
        Vocabulary: [~r/^JSV\.Vocabulary.*/],
        Utilities: [JSV.StructSupport]
      ]
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{
        "Github" => @source_url,
        "Changelog" => "https://github.com/lud/jsv/blob/main/CHANGELOG.md"
      }
    ]
  end

  def cli do
    [
      preferred_envs: [
        "coveralls.html": :test,
        dialyzer: :test
      ]
    ]
  end

  defp dialyzer do
    [
      flags: [:unmatched_returns, :error_handling, :unknown, :extra_return],
      list_unused_filters: true,
      plt_add_deps: :app_tree,
      plt_add_apps: [:ex_unit, :mix],
      plt_local_path: "_build/plts"
    ]
  end

  defp modkit do
    [
      mount: [
        {JSV, "lib/jsv"}
      ]
    ]
  end
end
