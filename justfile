gen-test-suite:
  mix compile
  mix jsv.gen_test_suite draft2020-12
  mix jsv.gen_test_suite draft7
  # mix format --check-formatted
  # git status --porcelain | rg "test/generated" --count && mix test || true

update-test-suite: deps
  #!/usr/bin/env bash
  pushd deps/json_schema_test_suite
  git checkout main
  git pull
  git rev-parse HEAD > ../../jsts_ref
  popd
  mix deps.get
  just gen-test-suite
  just _git_status

deps:
  mix deps.get

test:
  mix test

lint:
  mix compile --force --warnings-as-errors
  mix credo

dialyzer:
  mix dialyzer

_mix_format:
  mix format

_mix_check:
  mix check

_git_status:
  git status

docs:
  mix docs
  mix rdmx.update README.md
  rg rdmx guides -l0 | xargs -0 -n 1 mix rdmx.update


changelog:
  git cliff -o CHANGELOG.md

check: deps _mix_format _mix_check docs _git_status

