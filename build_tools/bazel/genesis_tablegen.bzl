load("@llvm-project//mlir:tblgen.bzl", "gentbl_cc_library")

def fc_gentbl_cc_library(includes = [], **kwargs):
    """Genesis version of gentbl_cc_library which sets up includes properly."""

    gentbl_cc_library(includes = includes + [
        "/external/llvm-project/mlir/include",
    ], **kwargs)
