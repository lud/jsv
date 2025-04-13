defmodule JSV.MixProject do
  use Mix.Project

  @source_url "https://github.com/lud/jsv"
  @version "0.6.3"

  def project do
    [
      app: :jsv,
      description: "A JSON Schema Validator with complete support for the latest specifications.",
      version: @version,
      elixir: "~> 1.15",
      # no protocol consolidation for the generation of the test suite
      consolidate_protocols: false,
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      source_url: @source_url,
      docs: docs(),
      package: package(),
      modkit: modkit(),
      dialyzer: dialyzer(),
      versioning: versioning()
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

  defp elixirc_paths(:dev) do
    ["lib", "dev"]
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
      {:abnf_parsec, "~> 2.0", optional: true},

      # Dev
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:dialyxir, "~> 1.4", only: :test, runtime: false},
      {:readmix, "~> 0.3", only: [:dev, :test], runtime: false},
      {:modkit, "~> 0.6", only: [:dev, :test], runtime: false},
      {:mix_version, "~> 2.4", only: [:dev, :test], runtime: false},

      # Test
      {:excoveralls, "~> 0.18", only: :test},
      {:briefly, "~> 0.5.1", only: :test},
      {:patch, "~> 0.15.0", only: :test},
      {:ex_check, "~> 0.16.0", only: [:dev, :test]},
      {:mix_audit, "~> 2.1", only: [:dev, :test]},
      {:mox, "~> 1.2", only: :test},

      # JSON Schema Test Suite
      json_schema_test_suite()
    ]
  end

  defp json_schema_test_suite do
    {:json_schema_test_suite,
     git: "https://github.com/json-schema-org/JSON-Schema-Test-Suite.git",
     ref: json_schema_test_suite_git_ref(),
     only: [:dev, :test],
     compile: false,
     app: false}
  end

  defp json_schema_test_suite_git_ref do
    __ENV__.file
    |> Path.dirname()
    |> Path.join("jsts_ref")
    |> File.read!()
    |> String.trim()
  end

  defp docs do
    [
      main: "JSV",
      extra_section: "GUIDES",
      source_ref: "v#{@version}",
      source_url: @source_url,
      extras: doc_extras(),
      groups_for_extras: groups_for_extras(),
      groups_for_modules: groups_for_modules(),
      groups_for_docs: groups_for_docs(),
      nest_modules_by_prefix: [JSV.Vocabulary]
    ]
  end

  def doc_extras do
    existing_guides = Path.wildcard("guides/**/*.md")

    defined_guides = [
      "CHANGELOG.md",
      "guides/schemas/defining-schemas.md",
      "guides/schemas/cast-functions.md",
      #
      "guides/build/build-basics.md",
      "guides/build/resolvers.md",
      "guides/build/vocabularies.md",
      #
      "guides/validation/validation-basics.md"
    ]

    case existing_guides -- defined_guides do
      [] ->
        :ok
        defined_guides

      missed ->
        IO.warn("""

        unreferenced guides

        #{Enum.map(missed, &[inspect(&1), ",\n"])}


        """)

        defined_guides ++ missed
    end
  end

  defp groups_for_extras do
    [
      Schemas: ~r/guides\/schemas\/.?/,
      Build: ~r/guides\/build\/.?/,
      Validation: ~r/guides\/validation\/.?/
    ]
  end

  defp groups_for_modules do
    [
      "Main API": [JSV],
      "Schema Definition": [JSV.Schema],
      Build: [JSV.FormatValidator, JSV.BuildError],
      Validation: [JSV.Root, JSV.ValidationError],
      Resolvers: [JSV.Resolver, JSV.Resolver.Httpc, JSV.Resolver.Embedded, JSV.Resolver.Internal, JSV.Resolver.Local],
      Vocabulary: [JSV.Vocabulary, ~r/^JSV\.Vocabulary\./],
      Utilities: [JSV.Normalizer, JSV.Normalizer.Normalize, JSV.Codec],
      Internal: ~r/.*/
    ]
  end

  defp groups_for_docs do
    [
      "Schema Definition Utilities": &(&1[:section] == :schema_utilities && &1[:sub_section] != :schema_casters),
      "Schema Casters": &(&1[:sub_section] == :schema_casters)
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{
        "Github" => @source_url,
        "Changelog" => "https://github.com/lud/jsv/blob/main/CHANGELOG.md"
      },
      files: package_files()
    ]
  end

  defp package_files do
    # Defaults from hex that matches files locally
    defaults = ["lib", "priv", ".formatter.exs", "mix.exs", "README*", "LICENSE*", "CHANGELOG*"]

    # Need to add local files as they are used in mix.exs/deps()
    custom = ["jsts_ref"]

    custom ++ defaults
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
      plt_add_apps: [:ex_unit, :mix, :readmix],
      plt_local_path: "_build/plts"
    ]
  end

  defp modkit do
    [
      mount: [
        {JSV, "lib/jsv"},
        {JSV.DocGen, "dev/doc_gen"}
      ]
    ]
  end

  defp versioning do
    [
      annotate: true,
      before_commit: [
        &update_readme/1,
        {:add, "README.md"},
        &gen_changelog/1,
        {:add, "CHANGELOG.md"}
      ]
    ]
  end

  def update_readme(vsn) do
    :ok = Readmix.update_file(Readmix.new(vars: %{app_vsn: vsn}), "README.md")
  end

  defp gen_changelog(vsn) do
    case System.cmd("git", ["cliff", "--tag", vsn, "-o", "CHANGELOG.md"], stderr_to_stdout: true) do
      {_, 0} -> IO.puts("Updated CHANGELOG.md with #{vsn}")
      {out, _} -> {:error, "Could not update CHANGELOG.md:\n\n #{out}"}
    end
  end
end
