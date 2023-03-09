#!/bin/bash
# [DESC]
#   Check that if the commit message meets the requirements of the standard format
# [ARGS]
#   $1 - Title of commit message
# [RETN]
#   0 - commit message is in correct format.
#   1 - commit message is illegal.
function check_commit() {
  commit=$*
  regexp="\[\w+-[0-9]+\][ ](feat|fix|docs|style|refactor|perf|test|chore)\(.*\):[ ][a-z]+(.*)[^.]$"
  if [[ $commit =~ "Revert" || $commit =~ "Merge" || $commit =~ "merge" ]]
  then
    return 0
  fi
  js_path=`git rev-parse --show-toplevel`/build_tools/git-hooks/commitlint.config.js
  echo $commit | commitlint -g $js_path
  if [ $? -ne 0 ] ;then
    return 1
  else
    return 0
  fi
}

# [DESC]
#   Get commit messages from specified source branch to HEAD.
# [ARGS]
#   $1 - Source branch of the merge request on CI
#   $2 - Target branch of the merge request on CI
# [RETN]
#   "${msg}" - Commit messages from source branch to HEAD
function get_commit_msg() {
  source_branch=$1
  target_branch=$2
  msg=`git log $source_branch...$target_branch --pretty=format:"%s"` && echo "$msg"
}

function check_branch() {
  echo "Check if the commit message meets the specification. [Checking...]"
  #source_branch=$CI_MERGE_REQUEST_SOURCE_BRANCH_NAME
  #target_branch=$CI_MERGE_REQUEST_TARGET_BRANCH_NAME
  source_branch=$1
  target_branch=$2
  if [[ $source_branch != "" ]]; then
    source_branch="origin/$source_branch"
  else
    echo "Error: CI_MERGE_REQUEST_SOURCE_BRANCH_NAME is empty."
    exit 1
  fi
  if [[ $target_branch != "" ]]; then
    target_branch="origin/$target_branch"
  else
    echo "Error: CI_MERGE_REQUEST_TARGET_BRANCH_NAME is empty."
    exit 1
  fi
  commit_messages=`get_commit_msg $source_branch $target_branch`
  error_cnt=0

  # Multi commits to string array
  OLD_IFS=$IFS
  IFS=$'\n' msg=($commit_messages)
  for i in "${!msg[@]}"
  do
    check_commit "${msg[$i]}"
    if [ $? = 1 ]; then
      echo Illegal format commit: "${msg[$i]}"
      error_cnt=`expr $error_cnt + 1`
    fi
    # Check repetition commit message
    for((j=0; j<i; j++))
    do
      if [ "${msg[$i]}" ==  "${msg[$j]}" ]; then
        IFS=$OLD_IFS
        echo [ERROR] Repetition commit message detected: "${msg[$j]}"
        error_cnt=`expr $error_cnt + 1`
        break
      fi
    done
  done
  IFS=$OLD_IFS
  if [[ $error_cnt -eq 0 ]]; then
    echo "Commit messages are conform to the specification."
    exit 0
  else
    exit 1
  fi
}

function usage() {
  echo  "Usage: commit_check.sh <\"commit message content\">"
  echo  "Usage: commit_check.sh <source_branch> <target_branch>"
}

# Check one single message
if [ $# -eq 1 ]; then
  echo Check message $1
  check_commit $1
  if [ $? = 1 ]; then
    echo Illegal format commit: $commit
    exit 1
  fi
# Check commit message from source branch to target branch
elif [ $# -eq 2 ]; then
  echo Check branch from $1 to $2
  check_branch $1 $2
else
  usage
fi

exit 0
