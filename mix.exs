defmodule JSV.MixProject do
  use Mix.Project

  def project do
    [
      app: :jsv,
      description: "Yet another JSON Schema Validator with complete support for the latest specifications.",
      version: "0.0.1",
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      package: package(),
      modkit: modkit(),
      dialyzer: dialyzer()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :public_key, :crypto]
    ]
  end

  defp elixirc_paths(:prod) do
    ["lib"]
  end

  defp elixirc_paths(_) do
    ["lib", "test/support"]
  end

  defp json_schema_test_suite do
    {:json_schema_test_suite,
     git: "https://github.com/json-schema-org/JSON-Schema-Test-Suite.git",
     ref: "82a077498cc761d69e8530c721702be980926c89",
     only: [:test],
     compile: false,
     app: false}
  end

  defp deps do
    [
      {:jason, "~> 1.4"},
      {:decimal, "~> 2.1"},

      # Formats
      {:mail_address, "~> 1.0", optional: true},
      {:abnf_parsec, "~> 1.0", optional: true},
      {:ecto, "> 0.0.0", optional: true},

      # Test or Prod ?
      {:ex_ssl_options, "~> 0.1.0"},

      # Dev
      {:credo, "~> 1.7", only: [:dev, :test]},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:dialyxir, "~> 1.4", runtime: false},
      {:cli_mate, ">= 0.0.0", only: :dev},
      {:modkit, "~> 0.6", only: :dev},

      # Test
      {:excoveralls, "~> 0.18.0", only: :test},
      {:mutex, "~> 3.0", only: :test},
      json_schema_test_suite()
    ]
  end

  defp package do
    [licenses: ["MIT"], links: %{"Github" => "https://github.com/lud/jsv"}]
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
