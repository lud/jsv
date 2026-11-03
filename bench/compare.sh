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
# * PIN_CPU - The CPU the benchmarks run on, default the last performance
#   core on hybrid CPUs, otherwise the last CPU. "none" disables pinning.
# * INSTRUCTIONS - When "1", also count the CPU instructions per call of every
#   scenario with `perf stat`, which requires kernel.perf_event_paranoid <= 1.
#   Instruction counts are reproducible within ~0.1% between runs, unlike
#   times.
# * INSTRUCTIONS_MS - Approximate duration of the measured loop of each
#   instruction count, default 300.
# * BENCH_FILTER, BENCH_ROUNDS, BENCH_ROUND_MS - Forwarded to validation.exs.
#
# Before measuring, every version is compiled and prechecked: each scenario
# must build and validate its valid and invalid data as expected.
#
# Instructions are counted for the whole VM, once with N calls of a scenario
# and once with none. The difference divided by N is the count per call. N is
# derived from the median time of the first pass.
#
# Raw outputs are written in bench/output/compare-<timestamp>/.
#
# Interesting commits:
#
# * e9cc63c - Last commit before the single cast stack optimization.
# * 14b4459 - Last commit before JSV.valid?/3 (#155).
# * 7aaf153 - JSV.valid?/3 merged (#155).

set -euo pipefail
shopt -s inherit_errexit

export MIX_ENV=prod

# Last commit before the single cast stack optimization.
baseline=e9cc63c

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_dir="$(git -C "$script_dir" rev-parse --show-toplevel)"
bench_file="$script_dir/validation.exs"
checkouts_dir="${BENCH_CHECKOUTS:-${TMPDIR:-/tmp}/jsv-bench-checkouts}"
passes="${PASSES:-2}"
instructions="${INSTRUCTIONS:-0}"
instructions_ms="${INSTRUCTIONS_MS:-300}"
out_dir="$script_dir/output/compare-$(date +%Y%m%d-%H%M%S)"

# The benchmarks run on a single scheduler without busy waiting, pinned to one
# CPU. Otherwise the VM moves between cores, which on hybrid CPUs do not run at
# the same speed, and idle schedulers execute instructions.
bench_cmd=(env "ERL_FLAGS=${ERL_FLAGS:-} +S 1:1 +sbwt none +sbwtdcpu none +sbwtdio none")

if [ -z "${PIN_CPU:-}" ]; then
  if [ -r /sys/devices/cpu_core/cpus ]; then
    performance_cpus="$(cat /sys/devices/cpu_core/cpus)"
    PIN_CPU="${performance_cpus##*[-,]}"
  elif command -v nproc >/dev/null; then
    PIN_CPU="$(($(nproc) - 1))"
  fi
fi

if [ -n "${PIN_CPU:-}" ] && [ "$PIN_CPU" != "none" ]; then
  if command -v taskset >/dev/null; then
    bench_cmd+=(taskset -c "$PIN_CPU")
  else
    echo "taskset not found, benchmarks are not pinned to a CPU" >&2
  fi
fi

bench_cmd+=(mix run --no-compile "$bench_file")

if [ "$instructions" = "1" ]; then
  if [ "$passes" -lt 1 ]; then
    echo "INSTRUCTIONS=1 requires at least one pass" >&2
    exit 1
  fi

  if ! perf stat -e instructions true >/dev/null 2>&1; then
    echo "perf stat cannot count instructions, check kernel.perf_event_paranoid (must be <= 1)" >&2
    exit 1
  fi
fi

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
  (cd "$tree" && mix compile >/dev/null && BENCH_PRECHECK=1 mix run --no-compile "$bench_file")
done

for pass in $(seq 1 "$passes"); do
  for i in "${!trees[@]}"; do
    tree="${trees[$i]}"
    label="${labels[$i]}"
    echo
    echo "== Pass $pass/$passes: $label"
    (cd "$tree" && "${bench_cmd[@]}") | tee "$out_dir/$label.pass$pass.txt"
  done
done

# Prints the instructions executed by the VM running the scenario variant $2
# $3 times in the tree $1.
count_instructions() {
  local perf_out="$out_dir/perf.tmp"

  (cd "$1" && BENCH_ONLY="$2" BENCH_ITERATIONS="$3" perf stat -x, -e instructions -o "$perf_out" -- "${bench_cmd[@]}" >/dev/null)

  # Hybrid CPUs report one counter per core type.
  awk -F, '$1 ~ /^[0-9]+$/ && $3 ~ /instructions/ { sum += $1 } END { print sum }' "$perf_out"
  rm "$perf_out"
}

if [ "$instructions" = "1" ]; then
  for i in "${!trees[@]}"; do
    tree="${trees[$i]}"
    label="${labels[$i]}"
    echo
    echo "== Instructions: $label"

    variants=()
    medians=()
    while read -r scenario variant median; do
      variants+=("$scenario $variant")
      medians+=("$median")
    done < <(awk '$(NF) ~ /^[0-9]+$/ && $(NF - 1) ~ /^[0-9.]+$/ { print $1, $2, $3 }' "$out_dir/$label.pass1.txt")

    empty="$(count_instructions "$tree" "${variants[0]}" 0)"

    for j in "${!variants[@]}"; do
      iterations="$(awk -v ms="$instructions_ms" -v us="${medians[$j]}" 'BEGIN { print int(ms * 1000 / us) + 1 }')"
      total="$(count_instructions "$tree" "${variants[$j]}" "$iterations")"
      per_call="$(awk -v t="$total" -v e="$empty" -v n="$iterations" 'BEGIN { printf "%d", (t - e) / n }')"
      printf "%-34s%12s%14s\n" "${variants[$j]}" "$iterations" "$per_call" | tee -a "$out_dir/$label.instructions.txt"
    done
  done
fi

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
    printf "%-34s", "scenario"
    for (i = 1; i <= n; i++) printf "%" width[i] "s", names[i]
    printf "\n"
    for (s = 1; s <= count; s++) {
      printf "%-34s", order[s]
      for (i = 1; i <= n; i++) {
        key = order[s] SUBSEP names[i]
        printf "%" width[i] "s", sprintf("%s / %s", best[key], reductions[key])
      }
      printf "\n"
    }
  }
' "$out_dir"/*.pass*.txt | tee "$out_dir/summary.txt"

if [ "$instructions" = "1" ]; then
  echo
  echo "== Summary: instructions per call, in thousands, change from ${labels[0]}"

  awk -v labels="${summary_files[*]}" '
    BEGIN {
      n = split(labels, names, " ")
      for (i = 1; i <= n; i++) width[i] = length(names[i]) + 4 > 22 ? length(names[i]) + 4 : 22
    }
    FNR == 1 {
      file = FILENAME
      sub(/.*\//, "", file)
      sub(/\.instructions\.txt$/, "", file)
    }
    {
      scenario = $1 " " $2
      if (!(scenario in seen)) { seen[scenario] = 1; order[++count] = scenario }
      count_of[scenario SUBSEP file] = $4
    }
    END {
      printf "%-34s", "scenario"
      for (i = 1; i <= n; i++) printf "%" width[i] "s", names[i]
      printf "\n"
      for (s = 1; s <= count; s++) {
        printf "%-34s", order[s]
        base = (order[s] SUBSEP names[1]) in count_of ? count_of[order[s] SUBSEP names[1]] : 0
        for (i = 1; i <= n; i++) {
          key = order[s] SUBSEP names[i]
          if (!(key in count_of)) cell = ""
          else if (i == 1 || base == 0) cell = sprintf("%.1f", count_of[key] / 1000)
          else cell = sprintf("%.1f (%+.2f%%)", count_of[key] / 1000, (count_of[key] - base) * 100 / base)
          printf "%" width[i] "s", cell
        }
        printf "\n"
      }
    }
  ' "$out_dir"/*.instructions.txt | tee "$out_dir/summary.instructions.txt"
fi
