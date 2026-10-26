# Cloudflare Workers 部署 Hugo 全方案对比实测 (`hugo-wrangler`)

由于 Cloudflare 官方目前已将重心从 **Cloudflare Pages** 转移至 **Cloudflare Workers（Static Assets 静态资源托管模式）**，使用 `wrangler.jsonc` 部署 Hugo 博客时，关于「**如何指定与锁定 Hugo 版本**」以及「**构建环境如何工作**」存在多种不同方案与常见误区。

本仓库按子目录拆分为 **5 个独立的 Hugo + Wrangler 示例项目**，并已全部部署至 Cloudflare Workers 进行线上实测。每个子目录都在首页直接渲染出构建时的真实环境数据（包括 `hugo.Version`、`hugo.IsExtended`、`hugo.GoVersion`、`hugo.CommitHash`、构建时间等）。

---

## 🌐 线上实测地址与结果汇总

### 线上 Demo 列表
- [方案 01：默认 Hugo 环境 (Default Hugo)](https://hugo-workers-01-default.xy2401.workers.dev/)
- [方案 02：CF 后台环境变量 HUGO\_VERSION](https://hugo-workers-02-dashboard-env.xy2401.workers.dev/)
- [方案 03：【误区验证】在 wrangler.jsonc vars 中配置 HUGO\_VERSION](https://hugo-workers-03-vars-trap.xy2401.workers.dev/)
- [方案 04：通过 package.json (hugo-extended) 锁定版本](https://hugo-workers-04-npm-pkg.xy2401.workers.dev/)
- [方案 05：通过自定义 build.sh 脚本精准控制构建环境](https://hugo-workers-05-build-sh.xy2401.workers.dev/)

### 实测数据对比表

| 子目录 | 线上实测地址 | 实测 `hugo.Version` | 实测 `hugo.IsExtended` | 是否依赖后台配置 | 版本受 Git 控制 (IaC) | 实测结论与避坑指南 |
| :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| [`01-default-hugo`](./01-default-hugo/) | [线上预览](https://hugo-workers-01-default.xy2401.workers.dev/) | **`0.147.7`** | ✅ **`true`** | ❌ 否 | ❌ 否 | 默认镜像自带 `0.147.7` Extended 版，零配置开箱即用，但版本滞后于最新版。 |
| [`02-dashboard-env-hugo-version`](./02-dashboard-env-hugo-version/) | [线上预览](https://hugo-workers-02-dashboard-env.xy2401.workers.dev/) | **`0.148.2`** | ⚠️ **`false` (标准版!)** | ✅ **是** | ❌ 否 | **重大发现**：后台填 `HUGO_VERSION=0.148.2` 虽能切换版本，但安装的是**非 Extended 标准版**！遇到 SCSS 会报错。 |
| [`03-wrangler-vars-trap`](./03-wrangler-vars-trap/) | [线上预览](https://hugo-workers-03-vars-trap.xy2401.workers.dev/) | **`0.147.7`** *(未生效)* | ✅ **`true`** | ❌ 否 | ⚠️ **无效** | **误区证实**：`wrangler.jsonc` 的 `vars` 仅作用于 Worker 运行时，构建时完全忽略，回退到了默认的 `0.147.7`。 |
| [`04-npm-hugo-extended`](./04-npm-hugo-extended/) | [线上预览](https://hugo-workers-04-npm-pkg.xy2401.workers.dev/) | **`0.148.2`** | ✅ **`true`** | ❌ 否 | ✅ **是** | ⭐ **强烈推荐**：通过 `package.json` 锁定 `hugo-extended`，必为 Extended 版，无需后台配置。 |
| [`05-custom-build-sh`](./05-custom-build-sh/) | [线上预览](https://hugo-workers-05-build-sh.xy2401.workers.dev/) | **`0.148.2`** | ✅ **`true`** | ❌ 否 | ✅ **是** | ⭐ **官方推荐**：无需 Node/npm，通过 `build.sh` 直接拉取官方 Release 的 Extended 二进制包，极速可靠。 |

---

## 💡 核心实测发现总结

通过这次对 5 个子目录的真实部署对比，得出了 3 个非常关键的结论：

1. **Cloudflare Workers 默认环境 (`01-default-hugo`)**：
   - 当前默认预装的是 **`Hugo 0.147.7` (Extended)**。如果你的主题不需要高于 `0.147.7` 的特性，什么都不配也能正常支持 SCSS/Sass。
2. **`wrangler.jsonc` 的 `vars` 陷阱 (`03-wrangler-vars-trap`)**：
   - 在 `wrangler.jsonc` 中写 `"vars": { "HUGO_VERSION": "0.148.2" }` **完全无效**（实测构建出来的依然是 `0.147.7`），因为 `vars` 只是注入给 Worker JS 运行时的环境变量，不是构建机容器的环境变量。
3. **后台设置 `HUGO_VERSION` 的隐藏大坑 (`02-dashboard-env-hugo-version`)**：
   - 当在 Cloudflare Dashboard 的 Build variables 中设置 `HUGO_VERSION=0.148.2` 时，版本确实变成了 `0.148.2`，但 **`hugo.IsExtended` 变成了 `false`（标准版）**！这会导致依赖 SCSS/Sass 的现代 Hugo 主题构建失败。
   - **最佳实践**：建议使用 **方案 04 (`04-npm-hugo-extended`)** 或 **方案 05 (`05-custom-build-sh`)**，不仅能将版本号纳入 Git 代码库管理（无需去网页后台手填变量），而且能 **100% 保证使用的是 `Extended` 版本**。

---

## 🚀 如何在 Cloudflare Workers Builds 中复现测试

1. 登录 [Cloudflare Dashboard](https://dash.cloudflare.com/) -> **Compute (Workers)** -> **Workers & Pages** -> **Create**。
2. 选择 **Import a repository** 连接本 Git 仓库。
3. 在构建设置（Build settings）中，针对你要测试的子目录修改 **Root directory（根目录）**：

### 1️⃣ [`01-default-hugo`](./01-default-hugo/)（默认 Hugo 版本）
- **线上预览**：https://hugo-workers-01-default.xy2401.workers.dev/
- **Root directory**: `/01-default-hugo`
- **Build variables**: 不填
- **实测结果**：`hugo.Version` = `0.147.7`，`hugo.IsExtended` = `true`。

### 2️⃣ [`02-dashboard-env-hugo-version`](./02-dashboard-env-hugo-version/)（后台环境变量指定版本）
- **线上预览**：https://hugo-workers-02-dashboard-env.xy2401.workers.dev/
- **Root directory**: `/02-dashboard-env-hugo-version`
- **Build variables（构建环境变量）**: 添加 `HUGO_VERSION` = `0.148.2`
- **实测结果**：`hugo.Version` = `0.148.2`，但 `hugo.IsExtended` = `false`（标准版）。

### 3️⃣ [`03-wrangler-vars-trap`](./03-wrangler-vars-trap/)（验证 `wrangler.jsonc` `vars` 误区）
- **线上预览**：https://hugo-workers-03-vars-trap.xy2401.workers.dev/
- **Root directory**: `/03-wrangler-vars-trap`
- **Build variables**: 不填（代码里的 `wrangler.jsonc` 写了 `"vars": { "HUGO_VERSION": "0.148.2" }`）
- **实测结果**：`vars` 未在构建时生效，回退至默认 `0.147.7`。

### 4️⃣ [`04-npm-hugo-extended`](./04-npm-hugo-extended/)（通过 `package.json` 锁定版本 —— 推荐）
- **线上预览**：https://hugo-workers-04-npm-pkg.xy2401.workers.dev/
- **Root directory**: `/04-npm-hugo-extended`
- **Build variables**: 不填
- **实测结果**：自动通过 `npm install` 安装 `hugo-extended@0.148.2`，实测 `hugo.Version` = `0.148.2` 且 `hugo.IsExtended` = `true`。

### 5️⃣ [`05-custom-build-sh`](./05-custom-build-sh/)（通过 `build.sh` 下载构建 —— Hugo 官方推荐）
- **线上预览**：https://hugo-workers-05-build-sh.xy2401.workers.dev/
- **Root directory**: `/05-custom-build-sh`
- **Build variables**: 不填
- **实测结果**：由 `./build.sh` 直接从 GitHub Releases 下载 `hugo_extended_0.148.2_linux-amd64.tar.gz`，实测 `hugo.Version` = `0.148.2` 且 `hugo.IsExtended` = `true`。

---

## 🛠️ 本地一键验证构建

你可以在仓库根目录下直接测试各个子目录的脚本与构建输出：

```bash
# 1. 使用当前机器环境测试 01 / 02 / 03
hugo --source 01-default-hugo --gc --minify
hugo --source 02-dashboard-env-hugo-version --gc --minify
hugo --source 03-wrangler-vars-trap --gc --minify

# 2. 测试方案 04 (通过 npm 下载并运行指定版本 hugo-extended)
cd 04-npm-hugo-extended && npm install && npm run build && cd ..

# 3. 测试方案 05 (通过 build.sh 自动下载指定版本 Hugo 二进制并构建)
cd 05-custom-build-sh && chmod a+x build.sh && ./build.sh && cd ..
```
