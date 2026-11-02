#!/bin/bash
# Runs the demo RUNS times and checks that every run printed the same
# trace and that it matches the reference model (test/model.py).
#   determinism.sh [RUNS] [SECONDS]
set -u
. "$(dirname "$0")/../scripts/env.sh"
runs=${1:-5}
seconds=${2:-2}
dir=$BUILD/determinism
rm -rf "$dir"

for i in $(seq "$runs"); do
  "$ROOT/scripts/run-demo.sh" "$seconds" "$dir/$i" > /dev/null || exit 1
done
# Runs stop at different points; compare the lines every run printed.
n=$(wc -l "$dir"/*/trace.txt | grep -v total | awk '{print $1}' | sort -n | head -1)
if [ "$n" -lt 10 ]; then
  echo "FAIL: only $n trace lines" >&2
  exit 1
fi
fail=0
for i in $(seq 2 "$runs"); do
  if ! cmp -s <(head -"$n" "$dir/1/trace.txt") <(head -"$n" "$dir/$i/trace.txt"); then
    echo "FAIL: run $i differs from run 1" >&2
    fail=1
  fi
done
if ! diff <(sed 's/  guest polls.*//' "$dir/1/trace.txt" | head -"$n") \
          <(python3 "$ROOT/test/model.py" $((n * 10)) | head -"$n") > "$dir/model.diff"; then
  echo "FAIL: run 1 differs from the model ($dir/model.diff)" >&2
  fail=1
fi
[ $fail = 0 ] && echo "PASS: $runs runs identical and equal to the model ($n lines)"
exit $fail
