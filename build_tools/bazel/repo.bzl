# Copyright 2017 The TensorFlow Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Utilities for defining Genesis Bazel dependencies."""

def _get_link_dict(ctx, link_files, build_file):
    link_dict = {ctx.path(v): ctx.path(Label(k)) for k, v in link_files.items()}
    if build_file:
        # Use BUILD.bazel because it takes precedence over BUILD.
        link_dict[ctx.path("BUILD.bazel")] = ctx.path(Label(build_file))
    return link_dict

def _is_windows(ctx):
    return ctx.os.name.lower().find("windows") != -1

def _get_env_var(ctx, name):
    if name in ctx.os.environ:
        return ctx.os.environ[name]
    else:
        return None

def _wrap_bash_cmd(ctx, cmd):
    if _is_windows(ctx):
        bazel_sh = _get_env_var(ctx, "BAZEL_SH")
        if not bazel_sh:
            fail("BAZEL_SH environment variable is not set")
        cmd = [bazel_sh, "-l", "-c", " ".join(["\"%s\"" % s for s in cmd])]
    return cmd

# Executes specified command with arguments and calls 'fail' if it exited with
# non-zero code
def _execute_and_check_ret_code(repo_ctx, cmd_and_args):
    result = repo_ctx.execute(cmd_and_args, timeout = 60)
    if result.return_code != 0:
        fail(("Non-zero return code({1}) when executing '{0}':\n" + "Stdout: {2}\n" +
              "Stderr: {3}").format(
            " ".join([str(x) for x in cmd_and_args]),
            result.return_code,
            result.stdout,
            result.stderr,
        ))

# Apply a patch_file to the repository root directory
# Runs 'patch -p1' on both Windows and Unix.
def _apply_patch(ctx, patch_file):
    patch_command = ["git", "apply", ctx.path(patch_file)]
    cmd = _wrap_bash_cmd(ctx, patch_command)
    _execute_and_check_ret_code(ctx, cmd)

def _fc_http_archive_impl(ctx):
    # Construct all paths early on to prevent rule restart. We want the
    # attributes to be strings instead of labels because they refer to files
    # in the Genesis repository, not files in repos depending on Genesis.
    # See also https://github.com/bazelbuild/bazel/issues/10515.
    link_dict = _get_link_dict(ctx, ctx.attr.link_files, ctx.attr.build_file)

    # For some reason, we need to "resolve" labels once before the
    # download_and_extract otherwise it'll invalidate and re-download the
    # archive each time.
    # https://github.com/bazelbuild/bazel/issues/10515
    patch_files = ctx.attr.patch_file
    for patch_file in patch_files:
        if patch_file:
            ctx.path(Label(patch_file))

    ctx.download_and_extract(
        url = ctx.attr.urls,
        sha256 = ctx.attr.sha256,
        type = ctx.attr.type,
        stripPrefix = ctx.attr.strip_prefix,
    )
    if patch_files:
        for patch_file in patch_files:
            patch_file = ctx.path(Label(patch_file)) if patch_file else None
            if patch_file:
                _apply_patch(ctx, patch_file)

    for dst, src in link_dict.items():
        ctx.delete(dst)
        ctx.symlink(src, dst)

_fc_http_archive = repository_rule(
    implementation = _fc_http_archive_impl,
    attrs = {
        "sha256": attr.string(mandatory = True),
        "urls": attr.string_list(mandatory = True),
        "strip_prefix": attr.string(),
        "type": attr.string(),
        "patch_file": attr.string_list(),
        "build_file": attr.string(),
        "link_files": attr.string_dict(),
    },
)

def fc_http_archive(name, sha256, urls, **kwargs):
    """Downloads and creates Bazel repos for dependencies.

    This is a swappable replacement for both http_archive() and
    new_http_archive() that offers some additional features. It also helps
    ensure best practices are followed.

    File arguments are relative to the Genesis repository by default. Dependent
    repositories that use this rule should refer to files either with absolute
    labels (e.g. '@foo//:bar') or from a label created in their repository (e.g.
    'str(Label("//:bar"))').
    """
    if len(urls) < 2:
        fail("fc_http_archive(urls) must have redundant URLs.")

    if native.existing_rule(name):
        # buildifier: disable=print
        print("\n\033[1;33mWarning:\033[0m skipping import of repository '" +
              name + "' because it already exists.\n")
        return

    _fc_http_archive(
        name = name,
        sha256 = sha256,
        urls = urls,
        **kwargs
    )
