#!/bin/sh
set -eu

# Resolve paths from the repository root, regardless of the caller's directory.
cd "$(dirname "$0")/.."

if [ "$#" -eq 0 ]; then
  set -- tests/telescope_keymaps.lua tests/fyler_git.lua tests/navigation_keymaps.lua tests/action_keymaps.lua tests/context_menu.lua
fi

for test_file do
  NVIM_TEST_FILE="$test_file" nvim -n -i NONE --headless '+lua dofile("tests/run.lua")'
done
