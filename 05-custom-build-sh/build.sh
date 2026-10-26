#!/usr/bin/env bash
#------------------------------------------------------------------------------
# 方案 05：自定义构建脚本 (参考 Hugo 官方 Host on Cloudflare 文档)
# 支持在代码里锁定默认 Hugo 版本，同时允许通过环境变量 HUGO_VERSION 覆盖
#------------------------------------------------------------------------------
set -euo pipefail

# 代码库默认锁定的 Hugo 版本（当后台未设置 HUGO_VERSION 时使用此版本）
DEFAULT_HUGO_VERSION="0.148.2"
TARGET_HUGO_VERSION="${HUGO_VERSION:-$DEFAULT_HUGO_VERSION}"
# 去除可能误带的 v 前缀
TARGET_HUGO_VERSION="${TARGET_HUGO_VERSION#v}"

echo "==> [build.sh] Target Hugo Extended version: ${TARGET_HUGO_VERSION}"

# 创建本地临时目录存放下载的二进制文件
BIN_DIR="$(pwd)/.bin"
mkdir -p "${BIN_DIR}"

# 下载对应版本的 Hugo Extended (Linux amd64)
TARBALL="hugo_extended_${TARGET_HUGO_VERSION}_linux-amd64.tar.gz"
DOWNLOAD_URL="https://github.com/gohugoio/hugo/releases/download/v${TARGET_HUGO_VERSION}/${TARBALL}"

echo "==> [build.sh] Downloading ${DOWNLOAD_URL} ..."
curl -sL "${DOWNLOAD_URL}" -o "${BIN_DIR}/${TARBALL}"
tar -xzf "${BIN_DIR}/${TARBALL}" -C "${BIN_DIR}" hugo
chmod +x "${BIN_DIR}/hugo"

# 将自定义二进制目录置于 PATH 最前面
export PATH="${BIN_DIR}:${PATH}"

echo "==> [build.sh] Verifying active Hugo binary:"
which hugo
hugo version

echo "==> [build.sh] Building Hugo site..."
hugo --gc --minify
