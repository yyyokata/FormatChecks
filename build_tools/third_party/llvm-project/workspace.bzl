"""Provides the repository macro to import LLVM."""

load("//build_tools/bazel:repo.bzl", "fc_http_archive")

def http_repo(name):
    """Imports LLVM."""
    LLVM_COMMIT = "0538e5431afdb1fa05bdcedf70ee502ccfcd112a"
    LLVM_SHA256 = "01f168b1a8798e652a04f1faecc3d3c631ff12828b89c65503f39b0a0d6ad048"

    fc_http_archive(
        name = name,
        sha256 = LLVM_SHA256,
        strip_prefix = "llvm-project-{commit}".format(commit = LLVM_COMMIT),
        urls = [
            "https://github.com/llvm/llvm-project/archive/{commit}.tar.gz".format(commit = LLVM_COMMIT),
        ],
        build_file = "//build_tools/third_party/llvm-project:llvm.BUILD",
        link_files = {"//build_tools/third_party/llvm-project:run_lit.sh": "mlir/run_lit.sh"},
    )
