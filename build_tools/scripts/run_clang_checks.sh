#!/bin/bash
set -e

# Build all the target first.
./run.sh -f //FormatCheck/... -d -j
# Gen compile_command.json under the root
bazel run //build_tools/scripts:refresh_compile_commands
# Run tool
iwyu_tool.py -- -Xiwyu --cxx17ns -Xiwyu '--verbose=1' -Xiwyu '--error=1' -Xiwyu --transitive_includes_only -p .
run-clang-tidy-15 -fix -format -quiet
git diff --exit-code
