# Workspace file for the fc project.

workspace(name = "org_fc")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

###############################################################################
# Skylib
http_archive(
    name = "bazel_skylib",
    sha256 = "1dde365491125a3db70731e25658dfdd3bc5dbdfd11b840b3e987ecf043c7ca0",
    urls = [
        "https://storage.googleapis.com/mirror.tensorflow.org/github.com/bazelbuild/bazel-skylib/releases/download/0.9.0/bazel_skylib-0.9.0.tar.gz",
        "https://github.com/bazelbuild/bazel-skylib/releases/download/0.9.0/bazel_skylib-0.9.0.tar.gz",
    ],
)

load("@bazel_skylib//:workspace.bzl", "bazel_skylib_workspace")

bazel_skylib_workspace()
###############################################################################

###############################################################################
# llvm-project
load("//build_tools/third_party/llvm-project:workspace.bzl", llvm = "http_repo")

llvm("llvm-raw")

load("//build_tools/third_party/llvm-project:setup.bzl", "llvm_setup")

llvm_setup("llvm-project")

###############################################################################
# Hedron's Compile Commands Extractor for Bazel.
http_archive(
    name = "hedron_compile_commands",
    sha256 = "9a68018c9120a636e60988b265c85e56f169a1408ed0c6bd164dd3a6996a9b36",
    strip_prefix = "bazel-compile-commands-extractor-752014925d055387ff4590a9862fb382350b0e5d",
    url = "https://github.com/hedronvision/bazel-compile-commands-extractor/archive/752014925d055387ff4590a9862fb382350b0e5d.tar.gz",
)

load("@hedron_compile_commands//:workspace_setup.bzl", "hedron_compile_commands_setup")

hedron_compile_commands_setup()
###############################################################################

###############################################################################
# All other fc submodule dependencies

load("//build_tools/bazel:workspace.bzl", "configure_fc_submodule_deps")

configure_fc_submodule_deps()
