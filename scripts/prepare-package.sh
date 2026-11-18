#!/usr/bin/env bash
# 构建并校验 SForum 纯前端示例插件：刷新 frontend/admin 制品与精确摘要，跑宿主契约检查。
#
# 用法：scripts/prepare-package.sh [--package] [package-dir]
#   --package     校验通过后额外打一个发布 zip 到 <repo>/dist/
#   package-dir   扩展包目录，默认 <repo>/plugins/sforum-demo-plugin
#
# 环境变量：
#   SFORUM_DIR    宿主 SForum 检出目录，默认与本仓库同级的 SForum
#
# 本包没有 Go 后端，所以这里不构建 backend/plugin；宿主 CLI 本身是 Go 程序，
# 因此仍需要 go 工具链，前端构建需要 bun。
set -euo pipefail

usage() {
  cat <<'EOF'
用法：scripts/prepare-package.sh [--package] [package-dir]

  --package     校验通过后额外打发布 zip 到 <repo>/dist/
  package-dir   扩展包目录，默认 <repo>/plugins/sforum-demo-plugin

环境变量：
  SFORUM_DIR    宿主 SForum 检出目录，默认与本仓库同级的 SForum
EOF
}

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PKG=""
DO_PACKAGE=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    -p|--package) DO_PACKAGE=1 ;;
    -h|--help) usage; exit 0 ;;
    -*) echo "未知参数：$1" >&2; usage >&2; exit 2 ;;
    *) PKG="$1" ;;
  esac
  shift
done

PKG="${PKG:-$ROOT/plugins/sforum-demo-plugin}"
SFORUM_DIR="${SFORUM_DIR:-$(cd "$ROOT/.." && pwd)/SForum}"

if [ ! -f "$PKG/sforum.extension.json" ]; then
  echo "找不到扩展包清单：$PKG/sforum.extension.json" >&2
  exit 1
fi
if [ ! -d "$SFORUM_DIR/apps/api" ]; then
  echo "找不到 SForum 检出目录：$SFORUM_DIR" >&2
  echo "可用 SFORUM_DIR=/path/to/SForum 指定，或把本仓库与 SForum 放在同一父目录下。" >&2
  exit 1
fi
if ! command -v bun >/dev/null 2>&1; then
  echo "需要 bun 来构建 frontend/admin（https://bun.sh）。" >&2
  exit 1
fi
if ! command -v go >/dev/null 2>&1; then
  echo "需要 go 工具链来运行宿主 CLI（go run ./cmd/sforum）。" >&2
  exit 1
fi
if ! command -v python3 >/dev/null 2>&1; then
  echo "需要 python3 来读取清单版本号并生成发布资产名（--package 分支）。" >&2
  exit 1
fi

# 宿主 CLI 必须在 apps/api 下运行：它按该工作目录解析宿主的清单契约与校验目录。
sforum_cli() {
  (cd "$SFORUM_DIR/apps/api" && go run ./cmd/sforum "$@")
}

# 带后端的包必须先有 backend/plugin：extension build 里的 digest/validate/test 会在
# 清单声明 backend 时要求该二进制存在。纯前端包整步跳过。
HAS_BACKEND="$(python3 -c "import json,sys;print('true' if json.load(open(sys.argv[1])).get('backend') else 'false')" "$PKG/sforum.extension.json")"
if [ "$HAS_BACKEND" = "true" ]; then
  echo "==> 清单声明 backend：先构建 backend/plugin（CGO_ENABLED=0，与宿主 dev watcher 同参）"
  (cd "$PKG/backend" && CGO_ENABLED=0 go build -trimpath -o "$PKG/backend/plugin" ./)
else
  echo "==> 清单没有 backend 字段：纯前端包，跳过后端构建"
fi

echo "==> 构建前端并刷新精确摘要（extension build：bun 构建 + digest + validate + test）"
sforum_cli extension build "$PKG"

echo "==> 品牌资产检查（extension brand check）"
sforum_cli extension brand check "$PKG"

echo "==> 校验清单（extension validate）"
sforum_cli extension validate "$PKG"

echo "==> 宿主契约检查（extension test）"
sforum_cli extension test "$PKG"

# 提示需要提交的内容：前端制品会被重写；清单里的 backend 摘要 churn 由
# scripts/check-manifest-drift.py 归一化掉，其余清单改动仍要求提交。
REL_PKG="${PKG#"$ROOT"/}"
if [ "$REL_PKG" != "$PKG" ] && git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  NEED_COMMIT=0
  if ! git -C "$ROOT" diff --quiet -- "$REL_PKG/frontend"; then
    NEED_COMMIT=1
  fi
  if ! (cd "$ROOT" && python3 scripts/check-manifest-drift.py "$REL_PKG" >/dev/null 2>&1); then
    NEED_COMMIT=1
  fi
  if [ "$NEED_COMMIT" = "1" ]; then
    echo "==> 本次构建改写了前端制品或清单摘要，记得提交这些变更："
    git --no-pager -C "$ROOT" diff --stat -- "$REL_PKG/frontend" "$REL_PKG/sforum.extension.json"
  fi
fi

if [ "$DO_PACKAGE" = "1" ]; then
  VERSION="$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['version'])" "$PKG/sforum.extension.json")"
  SLUG="$(basename "$PKG")"
  # 与 release 流水线同名：带后端的包按本机平台加后缀，纯前端包用裸版本号。
  if [ "$HAS_BACKEND" = "true" ]; then
    ASSET="${SLUG}_${VERSION}_$(go env GOOS)_$(go env GOARCH).zip"
  else
    ASSET="${SLUG}_${VERSION}.zip"
  fi
  mkdir -p "$ROOT/dist"
  echo "==> 打包发布 zip（extension package --exclude-source）"
  sforum_cli extension package "$PKG" --exclude-source -o "$ROOT/dist/$ASSET"
  (cd "$ROOT/dist" && sha256sum "$ASSET" "$ASSET.sbom.json" > SHA256SUMS && cat SHA256SUMS)
fi

echo "完成：$PKG"
