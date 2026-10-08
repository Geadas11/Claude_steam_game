#!/bin/bash
# Full test run, parallelised (one process per ending). Fails if any test fails
# OR if Godot printed a SCRIPT ERROR anywhere.
#   tools/run_tests.sh                 -> everything, in parallel
#   tools/run_tests.sh --only=validate -> pass-through to a single process
cd "$(dirname "$0")/.."
run_one() { timeout 1800 godot --headless res://tests/run_tests.tscn -- "$@" 2>&1; }
if [ $# -gt 0 ]; then
  LOG=$(mktemp); run_one "$@" > "$LOG"; CODE=$?
  grep -E "^-- |ending:|passed|FAIL" "$LOG"
  if grep -q "SCRIPT ERROR" "$LOG"; then echo "SCRIPT ERRORS:"; grep -A3 "SCRIPT ERROR" "$LOG" | head -40; CODE=1; fi
  rm -f "$LOG"; exit $CODE
fi
python3 tools/flag_audit.py || exit 1
DIR=$(mktemp -d)
run_one --only=validate > "$DIR/validate.log" &
run_one --only=save > "$DIR/save.log" &
for p in A B C D E; do
  extra=""; [ "$p" = "A" ] || [ "$p" = "E" ] && extra="--ui"
  run_one --only=play --policy=$p $extra > "$DIR/play_$p.log" &
done
wait
CODE=0
for f in "$DIR"/*.log; do
  echo "== $(basename "$f" .log)"
  grep -E "ending:|passed|FAIL" "$f"
  grep -q "0 failed" "$f" || CODE=1
  if grep -q "SCRIPT ERROR" "$f"; then echo "SCRIPT ERRORS:"; grep -A3 "SCRIPT ERROR" "$f" | head -20; CODE=1; fi
done
rm -rf "$DIR"
[ $CODE -eq 0 ] && echo "ALL GREEN" || echo "FAILURES"
exit $CODE
