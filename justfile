gen-test-suite:
  mix compile
  mix run tools/gen.test.suite.exs draft2020-12
  mix run tools/gen.test.suite.exs draft7
  mix format
  git status --porcelain | rg "test/generated" --count && mix test || true


test:
  mix test

lint:
  mix credo
  # mix compile --force --warnings-as-errors

_mix_format:
  mix format

_git_status:
  git status

check: _mix_format test lint _git_status

