#!/bin/bash
set -e

install_bazel() {
  # As new llvm-version need new version of bazel, so we install new bazel
  BAZEL_VERSION=$1
  echo "Start to install bazel $BAZEL_VERSION"
  rm -rf /bazel && mkdir /bazel
  if [[ $BAZEL_VERSION == "5.3.0" ]]; then
      cp /data/fetch_data/bazel-5.3.0-installer-linux-x86_64.sh /bazel/installer.sh
  else
      wget -O /bazel/installer.sh "https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-installer-linux-x86_64.sh"
  fi
  chmod +x /bazel/installer.sh && /bazel/installer.sh
  rm -f /bazel/installer.sh
}

if [ $# -ne 1 ]; then
  echo "install_bazel.sh [new|old]"
  exit 1
fi

if [[ "$1" == "new" ]]; then
  install_bazel "5.3.0"
elif [[ "$1" == "old" ]]; then
  install_bazel "3.5.0"
else
  echo "only can specify new|old, but got $1"
fi
