gen-test-suite: _mix_deps
  mix compile
  mix jsv.gen_test_suite draft2020-12
  mix jsv.gen_test_suite draft7
  # mix format --check-formatted
  # git status --porcelain | rg "test/generated" --count && mix test || true

update-test-suite: _mix_deps
  mix deps.get
  mix jsv.update_jsts_ref
  mix deps.get | rg json_schema_test_suite
  just gen-test-suite
  mix test
  just _git_status

_mix_deps:
  out=$(mix deps.get) && echo "all dependencies fetched" || { echo "$out"; exit 1; }

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
  for f in $(rg rdmx guides -l); do mix rdmx.update "$f"; done

docs: readme
  mix docs --warnings-as-errors

changelog:
  git cliff -o CHANGELOG.md

check: _mix_deps format readme _libdev_check _git_status

release bump:
  #!/usr/bin/env bash
  set -euo pipefail
  notes=tmp/release-notes.md
  if [ -f "$notes" ]; then
    mix version --{{bump}} --confirm --annotation-file "$notes"
    mv "$notes" "tmp/release-notes.$(date +%Y%m%dT%H%M%S).md"
  else
    mix version --{{bump}} --confirm
  fi

push-release:
  git push --follow-tags
  gh release create "$(git describe --tags --abbrev=0)" --notes "$(git cliff --latest --strip all)"
