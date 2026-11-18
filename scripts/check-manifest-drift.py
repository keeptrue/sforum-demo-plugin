#!/usr/bin/env python3
"""比对已提交清单与工作区清单，允许工具链相关的 backend 摘要变化。

CI 的漂移门分两段：frontend/ 下的前端制品是确定性的，直接用 git diff 比对；
清单 sforum.extension.json 里的 backend.digest 与 backend 可执行文件摘要会随
工具链/平台变化，不能当作者提交物，因此在这里归一化后再比较整份清单。

用法（在仓库根执行）：python3 scripts/check-manifest-drift.py plugins/sforum-demo-plugin
退出码：0 = 一致，或 HEAD 里没有该清单（新包，skip）；1 = 有实质性差异；2 = 用法错误。
"""

import json
import subprocess
import sys

MAX_REPORTED = 20


def committed_manifest(package_dir):
    """返回 HEAD 中已提交的清单原文；不存在时返回 None。"""
    relative = "%s/sforum.extension.json" % package_dir.rstrip("/")
    proc = subprocess.run(
        ["git", "show", "HEAD:%s" % relative],
        capture_output=True,
        text=True,
    )
    if proc.returncode != 0:
        return None
    return proc.stdout


def workspace_manifest(package_dir):
    path = "%s/sforum.extension.json" % package_dir.rstrip("/")
    with open(path, encoding="utf-8") as handle:
        return json.load(handle)


def normalize_backend_digests(committed, workspace):
    """把随工具链变化的 backend 摘要对齐到 HEAD 的值。

    两边都声明 backend 时才归一化：只归一化「工作区」一侧，HEAD 侧保持原样，
    于是「作者改了别的字段」仍然会被后续的整份比较抓到。
    """
    head_backend = committed.get("backend") or {}
    work_backend = workspace.get("backend") or {}
    if not head_backend or not work_backend:
        return

    entry = work_backend.get("entry") or head_backend.get("entry")
    if head_backend.get("digest"):
        work_backend["digest"] = head_backend["digest"]

    head_files = {}
    for item in committed.get("packageFiles") or []:
        head_files[item.get("path")] = item.get("digest")
    for item in workspace.get("packageFiles") or []:
        path = item.get("path")
        if entry and path == entry and path in head_files:
            item["digest"] = head_files[path]


def collect_diffs(committed, workspace, prefix=""):
    """逐 key 路径收集差异，返回 [(path, HEAD 值, 工作区值)]。"""
    diffs = []

    if isinstance(committed, dict) and isinstance(workspace, dict):
        for key in sorted(set(committed) | set(workspace)):
            child = "%s.%s" % (prefix, key) if prefix else key
            if key not in committed:
                diffs.append((child, "<缺失>", workspace[key]))
            elif key not in workspace:
                diffs.append((child, committed[key], "<缺失>"))
            else:
                diffs.extend(collect_diffs(committed[key], workspace[key], child))
        return diffs

    if isinstance(committed, list) and isinstance(workspace, list):
        if len(committed) != len(workspace):
            diffs.append(("%s.length" % prefix, len(committed), len(workspace)))
        for index, (left, right) in enumerate(zip(committed, workspace)):
            diffs.extend(collect_diffs(left, right, "%s[%d]" % (prefix, index)))
        return diffs

    if type(committed) is not type(workspace) or committed != workspace:
        diffs.append((prefix or "<根>", committed, workspace))
    return diffs


def main():
    if len(sys.argv) != 2:
        print("用法：python3 scripts/check-manifest-drift.py <package-dir>", file=sys.stderr)
        return 2

    package_dir = sys.argv[1].rstrip("/")
    raw = committed_manifest(package_dir)
    if raw is None:
        print("skip: HEAD 中没有 %s/sforum.extension.json（尚未提交的清单）" % package_dir)
        return 0

    committed = json.loads(raw)
    workspace = workspace_manifest(package_dir)
    normalize_backend_digests(committed, workspace)

    diffs = collect_diffs(committed, workspace)
    if not diffs:
        print("manifest drift check: %s/sforum.extension.json 与 HEAD 一致" % package_dir)
        return 0

    print(
        "manifest drift check: %s/sforum.extension.json 与 HEAD 有 %d 处差异"
        % (package_dir, len(diffs)),
        file=sys.stderr,
    )
    for path, before, after in diffs[:MAX_REPORTED]:
        print(
            "  %s: HEAD=%s 工作区=%s"
            % (path, json.dumps(before, ensure_ascii=False), json.dumps(after, ensure_ascii=False)),
            file=sys.stderr,
        )
    if len(diffs) > MAX_REPORTED:
        print("  …另有 %d 处差异未列出" % (len(diffs) - MAX_REPORTED), file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
