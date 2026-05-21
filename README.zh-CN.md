# zo2api

[English](./README.md) | 简体中文

Zo Computer API 反向代理服务，提供 OpenAI 和 Anthropic 兼容接口。

该服务会将请求转发到 `api.zo.computer`，并暴露常见 SDK 友好的 API 路径，让客户端可以用 OpenAI 风格或 Anthropic 风格调用 Zo Computer。

## 功能特性

- OpenAI 兼容接口 `POST /v1/chat/completions`
- OpenAI 兼容接口 `GET /v1/models`
- Anthropic 兼容接口 `POST /v1/messages`
- 支持流式和非流式响应
- 支持 OpenAI 和 Anthropic 客户端的工具/函数调用转换
- 代理层 API Key 保护
- 支持 Docker 和 Docker Compose 部署
- 内置健康检查接口 `GET /healthz`
- 可选的提示词覆盖和输出清洗开关

## 环境要求

- Node.js 20 或更高版本
- 一个以 `zo_sk_` 开头的 Zo Computer access token
- 如果使用容器部署，需要 Docker 和 Docker Compose

本项目没有 npm 运行时依赖。

## 快速开始

复制环境变量模板：

```bash
cp .env.example .env
```

编辑 `.env`，至少填写：

```bash
ZO_ACCESS_TOKEN=zo_sk_your_token_here
PROXY_API_KEY=sk-proxy-gateway-v1
PORT=8000
```

本地启动：

```bash
npm run start:local
```

也可以直接运行：

```bash
npm start
```

检查服务状态：

```bash
curl http://localhost:8000/healthz
```

## 从源码启动

适合本地开发或快速验证。

```bash
cp .env.example .env
```

编辑 `.env`，填入真实的 Zo Computer token：

```bash
ZO_ACCESS_TOKEN=zo_sk_your_token_here
PROXY_API_KEY=sk-proxy-gateway-v1
PORT=8000
```

运行内置校验：

```bash
npm run check
```

启动服务：

```bash
npm run start:local
```

调用健康检查接口：

```bash
curl http://localhost:8000/healthz
```

## Docker 部署

使用 Docker Compose 构建并启动：

```bash
./scripts/deploy.sh
```

查看状态：

```bash
docker compose ps
```

查看日志：

```bash
docker compose logs -f zo2api
```

停止服务：

```bash
docker compose down
```

## 使用已发布的 Docker 镜像

推送版本 tag 后，GitHub Actions 会自动把镜像发布到 Docker Hub。请把 `your-dockerhub-user/zo2api` 替换成你配置的镜像名。

```bash
docker run -d \
  --name zo2api \
  --restart unless-stopped \
  -p 8000:8000 \
  -e ZO_ACCESS_TOKEN=zo_sk_your_token_here \
  -e PROXY_API_KEY=sk-proxy-gateway-v1 \
  -e PROXY_PROMPT_OVERRIDE=true \
  -e PROXY_OUTPUT_SANITIZE=false \
  your-dockerhub-user/zo2api:latest
```

检查容器：

```bash
curl http://localhost:8000/healthz
docker logs -f zo2api
```

Docker Hub 仓库介绍会在每次 release 时从 `DOCKER.md` 自动同步。Docker 专用的运行方式、tag 和环境变量说明应维护在该文件中，这样 Docker Hub 页面会与发布镜像保持一致。

## 环境变量

| 变量 | 必填 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `ZO_ACCESS_TOKEN` | 是 | 无 | 调用上游 Zo Computer API 使用的 access token。 |
| `PROXY_API_KEY` | 否 | 每次启动随机生成 | 代理服务对外接受的 API key。建议显式设置，方便客户端稳定使用。 |
| `PORT` | 否 | `8000` | 本地服务和 Docker 容器使用的 HTTP 端口。 |
| `PROXY_PROMPT_OVERRIDE` | 否 | `false` | 是否启用 `server.js` 中的请求提示词包装逻辑。 |
| `PROXY_OUTPUT_SANITIZE` | 否 | `false` | 是否启用 `server.js` 中的响应文本清洗逻辑。 |

如果不设置 `PROXY_API_KEY`，服务会在启动时生成一个随机 key。这适合临时测试，但不适合 SDK 配置，因为每次重启后 key 都会变化。

## API 接口

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| `GET` | `/healthz` | 健康检查，不需要鉴权。 |
| `GET` | `/v1/models` | 以 OpenAI 兼容格式列出可用上游模型。 |
| `POST` | `/v1/chat/completions` | OpenAI 兼容聊天补全接口。 |
| `POST` | `/v1/messages` | Anthropic 兼容消息接口。 |

服务同时兼容以下路径：

- `/models`
- `/chat/completions`
- `/messages`
- `/v1/v1/models`
- `/v1/v1/chat/completions`
- `/v1/v1/messages`

## 鉴权

除 `/healthz` 外，所有 API 接口都需要代理 API key。

支持以下请求头：

```http
Authorization: Bearer sk-proxy-gateway-v1
```

```http
x-api-key: sk-proxy-gateway-v1
```

```http
anthropic-api-key: sk-proxy-gateway-v1
```

## OpenAI 兼容用法

列出模型：

```bash
curl http://localhost:8000/v1/models \
  -H "Authorization: Bearer sk-proxy-gateway-v1"
```

创建聊天补全：

```bash
curl http://localhost:8000/v1/chat/completions \
  -H "Authorization: Bearer sk-proxy-gateway-v1" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-4o",
    "messages": [
      { "role": "user", "content": "Hello" }
    ]
  }'
```

流式响应：

```bash
curl http://localhost:8000/v1/chat/completions \
  -H "Authorization: Bearer sk-proxy-gateway-v1" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-4o",
    "stream": true,
    "messages": [
      { "role": "user", "content": "Write one short paragraph." }
    ]
  }'
```

OpenAI SDK 示例：

```js
import OpenAI from "openai";

const client = new OpenAI({
  apiKey: "sk-proxy-gateway-v1",
  baseURL: "http://localhost:8000/v1",
});

const response = await client.chat.completions.create({
  model: "gpt-4o",
  messages: [{ role: "user", content: "Hello" }],
});

console.log(response.choices[0].message.content);
```

## Anthropic 兼容用法

创建消息：

```bash
curl http://localhost:8000/v1/messages \
  -H "anthropic-api-key: sk-proxy-gateway-v1" \
  -H "anthropic-version: 2023-06-01" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "claude-3-5-sonnet-latest",
    "max_tokens": 1024,
    "messages": [
      { "role": "user", "content": "Hello" }
    ]
  }'
```

Anthropic SDK 示例：

```js
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic({
  apiKey: "sk-proxy-gateway-v1",
  baseURL: "http://localhost:8000",
});

const response = await client.messages.create({
  model: "claude-3-5-sonnet-latest",
  max_tokens: 1024,
  messages: [{ role: "user", content: "Hello" }],
});

console.log(response.content);
```

## 模型映射

代理会通过 `/models/available` 从 Zo Computer 获取模型元数据，并缓存在内存中。请求模型名会按以下规则映射：

- 精确匹配上游 `model_name` 或 `label`
- 包含 `claude` 的名称映射到 Anthropic 模型
- 包含 `gpt`、`o1`、`o3` 或 `openai` 的名称映射到 OpenAI 模型
- 包含 `deepseek` 的名称映射到 DeepSeek 模型
- 包含 `gemini` 的名称映射到 Google 模型
- 包含 `glm` 的名称映射到 Z.ai 模型
- 包含 `minimax` 的名称映射到 MiniMax 模型
- 以 `zo:` 开头的名称会直接透传

如果没有找到映射，请求仍会发送给上游，但不会携带 `model_name`，由上游服务决定默认行为。

## 会话连续性

如果请求中提供 `x-conversation-id`，代理会转发该请求头；如果上游返回 `x-conversation-id`，代理也会把它返回给客户端。

示例：

```bash
curl http://localhost:8000/v1/chat/completions \
  -H "Authorization: Bearer sk-proxy-gateway-v1" \
  -H "x-conversation-id: your-conversation-id" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-4o",
    "messages": [
      { "role": "user", "content": "Continue our previous topic." }
    ]
  }'
```

## 浏览器测试页

仓库内包含 `test-page.html`，可用于在浏览器中进行简单聊天测试。用任意静态文件服务器启动仓库目录后，在浏览器中打开该页面即可。

示例：

```bash
python3 -m http.server 3000
```

然后打开：

```text
http://localhost:3000/test-page.html
```

## 常见问题

`ZO_ACCESS_TOKEN is required`

在 `.env` 中设置 `ZO_ACCESS_TOKEN`，或者在启动服务前通过环境变量导出。

`401 Invalid or missing API key`

确认请求中使用的 key 和 `.env` 里的 `PROXY_API_KEY` 一致，并通过 `Authorization`、`x-api-key` 或 `anthropic-api-key` 传入。

`Failed to fetch models from Zo`

检查 `ZO_ACCESS_TOKEN` 是否有效，以及当前环境是否可以访问上游 API。

Docker 端口无法访问

确认 `.env` 中的 `PORT` 设置一致，然后检查：

```bash
docker compose ps
docker compose logs -f zo2api
```

## CI/CD

仓库内置 GitHub Actions 工作流：

| 工作流 | 触发条件 | 作用 |
| --- | --- | --- |
| `.github/workflows/ci.yml` | 推送普通分支和 `pull_request` | 执行 CI、依赖审计、CodeQL 代码审计，全部通过后才构建 Docker 镜像。 |
| `.github/workflows/release.yml` | 推送匹配 `v*` 的 tag | 执行 CI、依赖审计、CodeQL 代码审计，创建 GitHub Release，把多架构 Docker 镜像推送到 Docker Hub，然后用 `DOCKER.md` 更新 Docker Hub 仓库介绍。 |

代码审计包含：

- `npm audit --audit-level=moderate --omit=dev`，用于检查生产依赖漏洞。
- CodeQL JavaScript/TypeScript 分析，并启用 `security-extended` 和 `security-and-quality` 查询集。
- Docker 镜像构建依赖 CI 和两类审计任务全部通过。

发布 Docker 镜像前，需要在 GitHub Actions 中配置：

| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `DOCKERHUB_USERNAME` | Secret | 是 | Docker Hub 用户名。 |
| `DOCKERHUB_TOKEN` | Secret | 是 | Docker Hub access token。 |
| `DOCKERHUB_REPOSITORY` | Variable | 否 | 完整镜像名，例如 `your-dockerhub-user/zo2api`。 |

如果不配置 `DOCKERHUB_REPOSITORY`，release 工作流会推送到：

```text
${DOCKERHUB_USERNAME}/zo2api
```

创建并推送版本 tag：

```bash
git tag v1.0.0
git push origin v1.0.0
```

release 工作流会发布这些 Docker tag：

```text
v1.0.0
1.0.0
1.0
latest
sha-<short-sha>
```

每次推送 `v*` tag 发布时，工作流都会先根据 tag 名改写 `VERSION` 文件，再执行校验、创建 GitHub Release 和构建 Docker 镜像。例如 tag `v1.2.3` 会生成内容为 `1.2.3` 的 `VERSION` 文件，并把该文件复制进 Docker 镜像。

Docker 镜像也会写入版本元数据：

- `/app/VERSION` 包含去掉开头 `v` 后的版本号。
- 镜像内设置 `APP_VERSION` 环境变量。
- OCI labels 包含 `org.opencontainers.image.version` 和 `org.opencontainers.image.ref.name`。
- Docker Hub 会同时更新发布版本 tag 和 `latest`。

## 脚本

| 命令 | 说明 |
| --- | --- |
| `npm run check` | 使用 `node --check` 校验 `server.js` 语法。 |
| `npm start` | 执行 `node server.js`。 |
| `npm run start:local` | 加载 `.env`、校验 `ZO_ACCESS_TOKEN`，然后启动服务。 |
| `npm run deploy` | 构建并启动 Docker Compose 服务。 |

## 常用维护命令

本地校验：

```bash
npm run check
npm audit --audit-level=moderate --omit=dev
sh -n scripts/start.sh scripts/deploy.sh
```

本地构建 Docker 镜像：

```bash
docker build -t zo2api:local .
```

校验 Docker Compose 配置：

```bash
cp .env.example .env
docker compose config
```

## 项目结构

```text
.
├── .github/
│   └── workflows/
│       ├── ci.yml
│       └── release.yml
├── DOCKER.md
├── Dockerfile
├── README.md
├── README.zh-CN.md
├── VERSION
├── docker-compose.yml
├── package-lock.json
├── package.json
├── server.js
├── scripts/
│   ├── deploy.sh
│   └── start.sh
├── test-page.html
└── .env.example
```
