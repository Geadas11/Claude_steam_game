#!/bin/bash
# Parse/compile check for every GDScript file (headless).
cd "$(dirname "$0")/.."
timeout 120 godot --headless --import >/dev/null 2>&1
timeout 60 godot --headless res://tools/compile_all.tscn 2>&1 | grep -E "SCRIPT ERROR|Parse Error|ERROR|error|FAILED|OK:" | grep -v "^\s*at:" | head -${1:-40}
