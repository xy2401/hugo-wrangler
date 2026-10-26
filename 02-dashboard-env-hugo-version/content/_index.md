---
title: "方案 02：CF 后台环境变量 HUGO_VERSION"
---

### 核心原理
Cloudflare Workers Builds 与原 Cloudflare Pages 共用了底层的构建镜像机制（Build Image）。当你在 **Cloudflare Dashboard -> Workers & Pages -> 你的 Worker -> Settings -> Build -> Build variables** 中添加 `HUGO_VERSION` 时，构建容器启动阶段会自动安装并切换至对应的 Hugo Extended 版本。

### Cloudflare 后台设置
- **Root directory（根目录）**: `/02-dashboard-env-hugo-version`
- **Build variables（构建变量）**:
  - 变量名：`HUGO_VERSION`
  - 变量值：例如 `0.148.2`（**注意**：填纯版本号，不要带 `v` 前缀）

### 优缺点分析
- **优点**：项目代码保持极简，与以前在 Cloudflare Pages 上的习惯完全一致。
- **缺点**：版本号配置保存在 Cloudflare 网页后台而非 Git 代码库中（Infrastructure as Code 不完整）；新建 Worker 或迁移项目时容易漏配。
