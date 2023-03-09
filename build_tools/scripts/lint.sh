#!/bin/bash

# ==============================================================================
# Copyright 2021 The IREE Authors
#
# Licensed under the Apache License v2.0 with LLVM Exceptions.
# See https://llvm.org/LICENSE.txt for license information.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
# ==============================================================================

# Runs all the lint checks that we run on Gitlab locally.

# WARNING: this script *makes changes* to the working directory and the index.

set -uo pipefail

FINAL_RET=0
LATEST_RET=0

scripts_dir="$(dirname $0)"
BASE_REF="${1:-master}"
ENABLE_BAZEL_BUILD="${2:-1}"

function update_ret() {
  LATEST_RET="$?"
  if [[ "${LATEST_RET}" -gt "${FINAL_RET}" ]]; then
    FINAL_RET="${LATEST_RET}"
  fi
}

# Update the exit code after every command
function enable_update_ret() {
  trap update_ret DEBUG
}

echo "***** Uncommitted changes *****"
git add -A
git diff HEAD --exit-code

if [[ $? -ne 0 ]]; then
  echo "Found uncomitted changes in working directory. This script requires" \
        "all changes to be committed. All changes have been added to the" \
        "index. Please commit or clean all changes and try again."
  exit 1
fi

enable_update_ret

echo $BASE_REF
echo "***** buildifier *****"
# Don't fail script if condition is false
${scripts_dir}/run_buildifier.sh $BASE_REF
git diff --exit-code

if [[ $ENABLE_BAZEL_BUILD -eq 1 ]]; then
  echo "***** clang-tidy *****"
  ${scripts_dir}/run_clang_checks.sh
fi

echo "***** yapf *****"
# Don't fail script if condition is false
git diff -U0 $BASE_REF | ./build_tools/scripts/format_diff.py yapf -i

echo "***** clang-format *****"
git-clang-format --style=file $BASE_REF
git diff --exit-code

echo "***** check-header *****"
files=`git diff -U0 $BASE_REF --name-only`
for file in $files; do
  python3 ./build_tools/scripts/format_checker.py --path $file
done

if (( "${FINAL_RET}" != 0 )); then
  echo "Encountered failures. Check error messages and changes to the working" \
       "directory and git index (which may contain fixes) and try again."
fi

exit "${FINAL_RET}"
