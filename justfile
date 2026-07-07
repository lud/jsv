gen-test-suite: _mix_deps
  mix compile
  mix jsv.gen_test_suite draft2020-12
  mix jsv.gen_test_suite draft7
  # mix format --check-formatted
  # git status --porcelain | rg "test/generated" --count && mix test || true

update-test-suite: _mix_deps
  mix deps.get
  mix jsv.update_jsts_ref
  mix deps.get
  just gen-test-suite
  mix test
  just _git_status

_mix_deps:
  mix deps.get

test:
  mix test

lint:
  mix compile --force --warnings-as-errors
  mix credo

dialyzer:
  mix dialyzer --format dialyzer

format:
  mix format --migrate

_libdev_check:
  mix libdev.check

_git_status:
  git status

readme:
  mix rdmx.update README.md
  rg rdmx guides -l0 | xargs -0 -n 1 mix rdmx.update

docs: readme
  mix docs --warnings-as-errors

changelog:
  git cliff -o CHANGELOG.md

check: _mix_deps format readme _libdev_check _git_status
