---
title: "方案 04：通过 package.json (hugo-extended) 锁定版本"
---

### 核心原理
Cloudflare Workers Builds 在检测到项目目录下存在 `package.json` 时，会自动在构建前执行 `npm install`。
通过在 `devDependencies` 中引入 [`hugo-extended`](https://www.npmjs.com/package/hugo-extended)（或 [`hugo-bin`](https://www.npmjs.com/package/hugo-bin)），并在 `wrangler.jsonc` 中将构建命令设为 `npm run build`，`npm` 会优先将 `./node_modules/.bin` 加入 `PATH`，从而直接调用你在 `package.json` 中锁定的 Hugo 版本。

### 配置文件 (`package.json` & `wrangler.jsonc`)

```json
// package.json
{
  "name": "hugo-workers-04-npm-pkg",
  "private": true,
  "scripts": {
    "build": "hugo --gc --minify"
  },
  "devDependencies": {
    "hugo-extended": "0.148.2"
  }
}
```

```jsonc
// wrangler.jsonc
{
  "name": "hugo-workers-04-npm-pkg",
  "compatibility_date": "2026-10-01",
  "build": {
    "command": "npm run build"
  },
  "assets": {
    "directory": "./public",
    "not_found_handling": "404-page"
  }
}
```

### Cloudflare 后台设置
- **Root directory（根目录）**: `/04-npm-hugo-extended`
- **Build variables（构建变量）**: **无需配置任何变量！**

### 优缺点分析
- **优点（强烈推荐）**：
  1. **配置即代码（IaC）**：版本号跟随 Git 仓库版本控制，无需去 Cloudflare 网页后台手动设置 `HUGO_VERSION`。
  2. **本地与云端一致**：本地执行 `npm run build` 或 `npx wrangler dev` 时使用的 Hugo 版本与云端 100% 一致。
  3. **天然契合 TailwindCSS / PostCSS**：如果主题本身就需要 `package.json` 来装 Tailwind 或 PostCSS，只需多加一行 `"hugo-extended"` 即可。
- **缺点**：`npm install` 阶段会拉取对应的 Hugo 二进制包，增加几秒钟的依赖安装时间。
