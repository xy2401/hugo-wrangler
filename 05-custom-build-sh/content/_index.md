---
title: "方案 05：自定义 build.sh 脚本 (Hugo 官方推荐方案)"
---

### 核心原理
这是 [Hugo 官方文档 (Host on Cloudflare)](https://gohugo.io/hosting-and-deployment/hosting-on-cloudflare/) 中针对复杂环境或最新特性的推荐做法。

在 `wrangler.jsonc` 中将 `build.command` 指向项目根目录下的 `./build.sh`：

```jsonc
{
  "name": "hugo-workers-05-build-sh",
  "compatibility_date": "2026-10-01",
  "build": {
    "command": "chmod a+x build.sh && ./build.sh"
  },
  "assets": {
    "directory": "./public",
    "not_found_handling": "404-page"
  }
}
```

### `build.sh` 的优势
1. **无需 `package.json` / Node 依赖**：纯 Shell 脚本通过 `curl` 直接从 GitHub Releases 拉取官方预编译好的 `hugo_extended` 二进制包，解压仅需 1~2 秒。
2. **双重灵活性**：脚本中写法为 `TARGET_HUGO_VERSION="${HUGO_VERSION:-0.148.2}"`——既在 Git 代码里保证了默认锁定的版本（`0.148.2`），又支持随时在 Cloudflare 后台设置 `HUGO_VERSION` 临时覆盖。
3. **可扩展任意工具链**：如果你的 Hugo 站点还需要特定版本的 **Dart Sass**、**Go**（用于 Hugo Modules）或预处理脚本，都可以直接在 `build.sh` 中一并下载和执行。
