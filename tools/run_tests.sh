#!/bin/bash
# Full test run. Fails if any test fails OR if Godot printed a SCRIPT ERROR.
cd "$(dirname "$0")/.."
LOG=$(mktemp)
timeout 1800 godot --headless res://tests/run_tests.tscn -- "$@" > "$LOG" 2>&1
CODE=$?
grep -E "^-- |ending:|passed|FAIL" "$LOG"
if grep -q "SCRIPT ERROR" "$LOG"; then
  echo "SCRIPT ERRORS:"; grep -A3 "SCRIPT ERROR" "$LOG" | head -40
  CODE=1
fi
rm -f "$LOG"
exit $CODE
