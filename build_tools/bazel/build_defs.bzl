# Genesis basic bazel rule infrastructure
# The core building API list is shown below:
# +---------------------+---------------------------------------+
# | API                 | description                           |
# |=====================+=======================================|
# | fc_cc_library  | Compile the library file              |
# |---------------------+---------------------------------------|
# | fc_cc_binary   | Compile the executable binary file    |
# |---------------------+---------------------------------------+
# | fc_cc_test     | Compile cpp test                      |
# |-------------------------------------------------------------|
# | fc_py_test     | Create one or more python test file   |
# |-------------------------------------------------------------|
# | fc_sh_test     | Create bash test                      |
# +---------------------+---------------------------------------+
#
# The core building PyPi and cc2py-bind API list is shown below:
# +---------------------+---------------------------------------+
# | API                 | description                           |
# |=====================+=======================================|
# | fc_py_binary   | Build python binary file              |
# |-------------------------------------------------------------|
# | fc_py_library  | Build python library module           |
# |-------------------------------------------------------------|
#

# Add mlu tag for these with detail device tag like mlu370
def _add_mlu_tag(tags):
    if [
        tag
        for tag in tags
        if tag in ["mlu270", "mlu370", "ce3226"]
    ] and "mlu" not in tags:
        tags.append("mlu")
    return tags

def fc_cc_library(linkstatic = 0, alwayslink = 0, **kwargs):
    """ Compile the library file for fc. """
    native.cc_library(alwayslink = alwayslink, linkstatic = linkstatic, **kwargs)

# Define a bazel macro that creates cc_binary for fc
def fc_cc_binary(linkstatic = 0, deps = [], **kwargs):
    """ Compile the executable binary file for fc.

    This is a pass-through to the native cc_library which adds specific
    compiler specific options and deps.
    """
    extra_deps = []
    if "mlu" in kwargs.get("tags", []):
        extra_deps = ["@local_mlu_rep//mlu_config:mlu_common_libs"]
    _add_mlu_tag(kwargs.get("tags", []))

    native.cc_binary(deps = deps + extra_deps, linkstatic = linkstatic, **kwargs)

# Define a bazel macro that creates cc_test for fc
def fc_cc_test(
        copts = [],
        linkopts = [],
        deps = [],
        size = "medium",
        linkstatic = 0,
        **kwargs):
    """ Compile cpp test for fc.
    """
    extra_deps = []
    if "mlu" in kwargs.get("tags", []):
        extra_deps.append("@local_mlu_rep//mlu_config:mlu_common_libs")
    _add_mlu_tag(kwargs.get("tags", []))

    native.cc_test(
        size = size,
        copts = copts,
        linkopts = ["-lpthread", "-lm"] + linkopts,
        deps = deps + ["@com_google_googletest//:gtest_main", "@com_google_googletest//:gtest"],
        linkstatic = linkstatic,
        **kwargs
    )

def fc_sh_test(
        size = "medium",
        timeout = "moderate",
        shard_count = 1,  # default num of parallel shards
        flaky = 0,
        **kwargs):
    native.sh_test(
        size = size,
        timeout = timeout,
        flaky = flaky,
        shard_count = shard_count,
        **kwargs
    )

def fc_py_test(
        size = "medium",
        timeout = "moderate",
        main = None,
        shard_count = 1,  # default num of parallel shards
        flaky = 0,
        **kwargs):
    """ Create one or more python tests. """

    # Python version placeholder
    kwargs.setdefault("srcs_version", "PY2AND3")
    native.py_test(
        size = size,
        timeout = timeout,
        flaky = flaky,
        main = main,
        shard_count = shard_count,
        **kwargs
    )

def fc_py_binary(srcs_version = "PY2AND3", **kwargs):
    """ Build python binary file. """
    native.py_binary(srcs_version = srcs_version, **kwargs)

def fc_py_library(srcs_version = "PY2AND3", **kwargs):
    """ Build python library module. """
    native.py_library(srcs_version = srcs_version, **kwargs)
