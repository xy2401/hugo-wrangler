# Cloudflare Workers 部署 Hugo 全方案对比实测 (`hugo-wrangler`)

由于 Cloudflare 官方目前已将重心从 **Cloudflare Pages** 转移至 **Cloudflare Workers（Static Assets 静态资源托管模式）**，使用 `wrangler.jsonc` 部署 Hugo 博客时，关于「**如何指定与锁定 Hugo 版本**」以及「**构建环境如何工作**」存在多种不同方案与常见误区。

本仓库按子目录拆分为 **5 个独立的 Hugo + Wrangler 示例项目**。每个子目录部署后，都会在首页直接渲染出构建时的实测数据（包括 `hugo.Version`、`hugo.IsExtended`、`hugo.GoVersion`、构建时间等），方便你在 Cloudflare Workers Builds 上逐一部署验证。

---

## 📊 5 种方案全景对比表

| 子目录 | 方案名称 | 版本指定位置 | 是否依赖 CF 后台配置 | 版本是否受 Git 控制 (IaC) | 适用场景与结论 |
| :--- | :--- | :--- | :---: | :---: | :--- |
| [`01-default-hugo`](./01-default-hugo/) | **01. 默认构建环境** | 不指定（使用 CF 容器预装） | ❌ 否 | ❌ 否 | 适合对 Hugo 版本无要求的简单站点；缺点是 CF 默认预装版本可能滞后。 |
| [`02-dashboard-env-hugo-version`](./02-dashboard-env-hugo-version/) | **02. CF 后台 `HUGO_VERSION` 变量** | CF Dashboard -> Build variables | ✅ **是** | ❌ 否 | 延续原 Cloudflare Pages 的习惯；在后台设置 `HUGO_VERSION=0.148.2`（不带 `v`）。 |
| [`03-wrangler-vars-trap`](./03-wrangler-vars-trap/) | **03. 【常见误区】`wrangler.jsonc` `vars`** | `wrangler.jsonc` 的 `vars` 字段 | ❌ 否 | ⚠️ **无效** | **踩坑演示**：`vars` 是 Worker 运行时变量，**不会**在构建容器安装 Hugo 时生效！ |
| [`04-npm-hugo-extended`](./04-npm-hugo-extended/) | **04. `package.json` (`hugo-extended`)** | `package.json` (`devDependencies`) | ❌ 否 | ✅ **是** | ⭐ **强烈推荐**：通过 npm 锁定 `hugo-extended` 版本，本地与云端 100% 一致，零后台配置。 |
| [`05-custom-build-sh`](./05-custom-build-sh/) | **05. 自定义 `build.sh` 脚本** | `build.sh` 脚本内部下载 | ❌ 否（可选覆盖） | ✅ **是** | ⭐ **Hugo 官方文档方案**：无需 Node/npm，脚本直接拉取官方 Release 二进制包，还可扩展 Dart Sass 等。 |

---

## 🚀 如何在 Cloudflare Workers Builds 中测试各个子目录

1. 登录 [Cloudflare Dashboard](https://dash.cloudflare.com/) -> **Compute (Workers)** -> **Workers & Pages** -> **Create**。
2. 选择 **Import a repository** 连接本 Git 仓库。
3. 在构建设置（Build settings）中，针对你要测试的子目录修改 **Root directory（根目录）**：

### 1️⃣ 测试 [`01-default-hugo`](./01-default-hugo/)（默认 Hugo 版本）
- **Root directory**: `/01-default-hugo`
- **Build variables**: 不填
- **预期结果**：页面显示 Cloudflare Workers Builds 当前构建容器内置的默认 Hugo 版本。

### 2️⃣ 测试 [`02-dashboard-env-hugo-version`](./02-dashboard-env-hugo-version/)（后台环境变量指定版本）
- **Root directory**: `/02-dashboard-env-hugo-version`
- **Build variables（构建环境变量）**: 添加 `HUGO_VERSION` = `0.148.2`（注意：**不要**加 `v` 前缀，且必须填在 **Build variables** 而不是 Worker Runtime variables）
- **预期结果**：Cloudflare 构建日志会显示安装指定版本的 Hugo，页面渲染出的 `hugo.Version` 为 `0.148.2`。

### 3️⃣ 测试 [`03-wrangler-vars-trap`](./03-wrangler-vars-trap/)（验证 `wrangler.jsonc` `vars` 误区）
- **Root directory**: `/03-wrangler-vars-trap`
- **Build variables**: 不填（代码里的 `wrangler.jsonc` 写了 `"vars": { "HUGO_VERSION": "0.148.2" }`）
- **预期结果**：**不会变成 `0.148.2`**！页面显示的依然是 Cloudflare 默认版本，直观证明 `wrangler.jsonc` 中的 `vars` 只作用于 Worker 运行时（Runtime），不作用于构建时（Build time）。

### 4️⃣ 测试 [`04-npm-hugo-extended`](./04-npm-hugo-extended/)（通过 `package.json` 锁定版本 —— 推荐）
- **Root directory**: `/04-npm-hugo-extended`
- **Build variables**: 不填
- **工作原理**：Cloudflare 检测到子目录下的 `package.json` 会自动执行 `npm install` 安装 `hugo-extended@0.148.2`，随后 `wrangler.jsonc` 中的 `"command": "npm run build"` 会直接调用 `node_modules/.bin/hugo`。
- **预期结果**：无需在 Cloudflare 后台配置任何环境变量，页面显示的 `hugo.Version` 严格为 `0.148.2` 且 `hugo.IsExtended` 为 `true`。

### 5️⃣ 测试 [`05-custom-build-sh`](./05-custom-build-sh/)（通过 `build.sh` 下载构建 —— Hugo 官方推荐）
- **Root directory**: `/05-custom-build-sh`
- **Build variables**: 不填（若填写 `HUGO_VERSION` 则会覆盖脚本内的默认值）
- **工作原理**：`wrangler.jsonc` 配置 `"command": "chmod a+x build.sh && ./build.sh"`，由脚本直接从 GitHub Releases 下载指定版本的 `hugo_extended` Linux 二进制包并执行构建。
- **预期结果**：页面显示的 `hugo.Version` 严格为脚本锁定的 `0.148.2`。

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
