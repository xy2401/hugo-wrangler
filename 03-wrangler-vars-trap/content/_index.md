---
title: "方案 03：【误区验证】wrangler.jsonc 中的 vars"
---

### 为什么这是一个常见误区？
很多开发者从 Cloudflare Pages 迁移到 Cloudflare Workers 时，想把原本在后台配置的 `HUGO_VERSION` 写进 `wrangler.jsonc` 的 `vars` 字段中：

```jsonc
{
  "name": "hugo-workers-03-vars-trap",
  "compatibility_date": "2026-10-01",
  "vars": {
    // ❌ 误区：这里的变量仅注入给 Worker 运行时 JS 代码（env.HUGO_VERSION），
    // 并不会在 Cloudflare 构建机器初始化或执行 hugo 命令时生效！
    "HUGO_VERSION": "0.148.2"
  },
  "build": {
    "command": "hugo --gc --minify"
  },
  "assets": {
    "directory": "./public",
    "not_found_handling": "404-page"
  }
}
```

### 实测现象
部署后查看上方表格中的 **`hugo.Version`**，你会发现它**并不是 `0.148.2`**，而是与 `01-default-hugo` 完全相同的默认版本。

### 如何在代码库里真正锁定版本？
如果你希望在 Git 代码库中（而不是去 Cloudflare 网页后台手填变量）锁定 Hugo 版本，请参考：
- **方案 04 (`04-npm-hugo-extended`)**：通过 `package.json` 锁定版本
- **方案 05 (`05-custom-build-sh`)**：通过 `build.sh` 脚本下载指定版本
