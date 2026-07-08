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

# Tests tagged :unix rely on Unix-only filesystem semantics (mode bits,
# unprivileged symlinks) that do not apply on Windows.
{os_family, _} = :os.type()

excluded_tags =
  if os_family == :unix do
    excluded_tags
  else
    [{:unix, true} | excluded_tags]
  end

ExUnit.configure(exclude: excluded_tags)

ExUnit.start(stacktrace_depth: 64)
