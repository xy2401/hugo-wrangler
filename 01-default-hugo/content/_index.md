---
title: "方案 01：默认 Hugo 环境"
---

### 核心配置 (`wrangler.jsonc`)

```jsonc
{
  "name": "hugo-workers-01-default",
  "compatibility_date": "2026-10-01",
  "build": {
    "command": "hugo --gc --minify"
  },
  "assets": {
    "directory": "./public",
    "not_found_handling": "404-page"
  }
}
```

### Cloudflare 后台设置
- **Root directory（根目录）**: `/01-default-hugo`
- **Build command（构建命令）**: `npx wrangler deploy`（或留空由 Cloudflare 自动执行 deploy，构建阶段会自动触发 `wrangler.jsonc` 中的 `build.command`）
- **Build variables（构建环境变量）**: 无需配置

### 优缺点分析
- **优点**：零额外配置，构建速度极快（无需下载 Hugo 二进制文件或 npm 包）。
- **缺点**：Cloudflare 默认镜像预装的 Hugo 版本通常滞后于最新正式版，如果主题要求较新版本的 Hugo 会构建失败。
