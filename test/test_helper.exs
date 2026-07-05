flag? = fn var -> System.get_env(var) in ["true", "1"] end
ci? = flag?.("GITHUB_ACTIONS")

enabled_live_test_suites = [
  # Enabled in CI
  httpc_live: ci? or flag?.("HTTPC_LIVE_TESTS")
]

excluded_tags =
  enabled_live_test_suites
  |> Enum.filter(fn {_tag, enabled?} -> not enabled? end)
  |> Enum.map(fn {tag, _enabled_false} -> {tag, _excluded = true} end)

ExUnit.configure(exclude: excluded_tags)

ExUnit.start(stacktrace_depth: 64)
