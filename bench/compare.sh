#!/usr/bin/env bash
# Runs bench/validation.exs against several versions of the library and prints
# the numbers side by side.
#
#     bench/compare.sh [ref ...]
#
# Each argument is a git ref, or "." for the current checkout including its
# uncommitted changes. Without arguments, the baseline commit below is
# compared with the current checkout.
#
# Refs are exported with `git archive` into $BENCH_CHECKOUTS/<sha>, default
# ${TMPDIR:-/tmp}/jsv-bench-checkouts. Exports are kept so their build is reused
# on the next runs. The benchmark file always comes from the current checkout.
#
# Environment variables:
#
# * PASSES - Number of measured passes over all versions, default 2. Passes
#   alternate between versions so a noisy period affects all of them.
# * BENCH_FILTER, BENCH_ROUNDS, BENCH_ROUND_MS - Forwarded to validation.exs.
#
# Before measuring, every version is compiled and prechecked: each scenario
# must build and validate its valid and invalid data as expected.
#
# Raw outputs are written in bench/output/compare-<timestamp>/.

set -euo pipefail

# Last commit before the single cast stack optimization.
baseline=e9cc63c

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_dir="$(git -C "$script_dir" rev-parse --show-toplevel)"
bench_file="$script_dir/validation.exs"
checkouts_dir="${BENCH_CHECKOUTS:-${TMPDIR:-/tmp}/jsv-bench-checkouts}"
passes="${PASSES:-2}"
out_dir="$script_dir/output/compare-$(date +%Y%m%d-%H%M%S)"

if [ "$#" -gt 0 ]; then
  refs=("$@")
else
  refs=("$baseline" .)
fi

trees=()
labels=()

for ref in "${refs[@]}"; do
  if [ "$ref" = "." ]; then
    label="$(git -C "$repo_dir" symbolic-ref --short -q HEAD || git -C "$repo_dir" rev-parse --short HEAD)"
    if ! git -C "$repo_dir" diff --quiet HEAD; then
      label="$label+dirty"
    fi
    trees+=("$repo_dir")
  else
    sha="$(git -C "$repo_dir" rev-parse --verify "$ref^{commit}")"
    short_sha="$(git -C "$repo_dir" rev-parse --short "$sha")"
    tree="$checkouts_dir/$sha"

    if [ ! -d "$tree" ]; then
      mkdir -p "$tree"
      git -C "$repo_dir" archive "$sha" | tar -x -C "$tree"
      ln -s "$repo_dir/deps" "$tree/deps"
    fi

    if [ "$ref" = "$short_sha" ] || [ "$ref" = "$sha" ]; then
      label="$short_sha"
    else
      label="$ref@$short_sha"
    fi
    trees+=("$tree")
  fi
  labels+=("${label//\//_}")
done

mkdir -p "$out_dir"
echo "Results in $out_dir"

echo
echo "== Precheck"
for i in "${!trees[@]}"; do
  tree="${trees[$i]}"
  label="${labels[$i]}"
  echo "-- $label ($tree)"
  (cd "$tree" && mix compile >/dev/null && BENCH_PRECHECK=1 mix run "$bench_file")
done

for pass in $(seq 1 "$passes"); do
  for i in "${!trees[@]}"; do
    tree="${trees[$i]}"
    label="${labels[$i]}"
    echo
    echo "== Pass $pass/$passes: $label"
    (cd "$tree" && mix run "$bench_file") | tee "$out_dir/$label.pass$pass.txt"
  done
done

echo
echo "== Summary: best median µs over $passes passes / reductions per call"

summary_files=()
for label in "${labels[@]}"; do
  summary_files+=("$label")
done

awk -v labels="${summary_files[*]}" '
  BEGIN {
    n = split(labels, names, " ")
    for (i = 1; i <= n; i++) width[i] = length(names[i]) + 4 > 22 ? length(names[i]) + 4 : 22
  }
  FNR == 1 {
    file = FILENAME
    sub(/.*\//, "", file)
    sub(/\.pass[0-9]+\.txt$/, "", file)
  }
  $(NF) ~ /^[0-9]+$/ && $(NF - 1) ~ /^[0-9.]+$/ {
    scenario = $1 " " $2
    if (!(scenario in seen)) { seen[scenario] = 1; order[++count] = scenario }
    key = scenario SUBSEP file
    if (!(key in best) || $3 + 0 < best[key] + 0) best[key] = $3
    reductions[key] = $5
  }
  END {
    printf "%-30s", "scenario"
    for (i = 1; i <= n; i++) printf "%" width[i] "s", names[i]
    printf "\n"
    for (s = 1; s <= count; s++) {
      printf "%-30s", order[s]
      for (i = 1; i <= n; i++) {
        key = order[s] SUBSEP names[i]
        printf "%" width[i] "s", sprintf("%s / %s", best[key], reductions[key])
      }
      printf "\n"
    }
  }
' "$out_dir"/*.pass*.txt | tee "$out_dir/summary.txt"
