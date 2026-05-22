# zo2api

English | [简体中文](./README.zh-CN.md)

Zo Computer API reverse proxy with OpenAI and Anthropic compatible endpoints.

This service forwards requests to `api.zo.computer` and exposes common SDK-friendly API paths, so clients can call Zo Computer through OpenAI-style or Anthropic-style interfaces.

## Features

- OpenAI compatible `POST /v1/chat/completions`
- OpenAI compatible `GET /v1/models`
- Anthropic compatible `POST /v1/messages`
- Streaming and non-streaming responses
- Tool/function call conversion for OpenAI and Anthropic clients
- API key protection for the proxy
- Docker and Docker Compose deployment
- Built-in health check at `GET /healthz`
- Optional prompt override and output sanitization flags

## Requirements

- Node.js 20 or newer
- A Zo Computer access token starting with `zo_sk_`
- Docker and Docker Compose, if using container deployment

The project has no npm runtime dependencies.

## Quick Start

Copy the environment template:

```bash
cp .env.example .env
```

Edit `.env` and set at least:

```bash
ZO_ACCESS_TOKEN=zo_sk_your_token_here
PROXY_API_KEY=sk-proxy-gateway-v1
PORT=8000
```

Start locally:

```bash
npm run start:local
```

Or run directly:

```bash
npm start
```

Check the service:

```bash
curl http://localhost:8000/healthz
```

## Run From Source

Use this mode for local development or quick verification.

```bash
cp .env.example .env
```

Edit `.env` with a real Zo Computer token:

```bash
ZO_ACCESS_TOKEN=zo_sk_your_token_here
PROXY_API_KEY=sk-proxy-gateway-v1
PORT=8000
```

Run the built-in validation:

```bash
npm run check
```

Start the service:

```bash
npm run start:local
```

Call the health endpoint:

```bash
curl http://localhost:8000/healthz
```

## Docker Deployment

Build and start with Docker Compose:

```bash
./scripts/deploy.sh
```

View status:

```bash
docker compose ps
```

View logs:

```bash
docker compose logs -f zo2api
```

Stop the service:

```bash
docker compose down
```

## Run a Published Docker Image

After a version tag is released by GitHub Actions, the image is pushed to Docker Hub. Replace `your-dockerhub-user/zo2api` with your configured image name.

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

Check the container:

```bash
curl http://localhost:8000/healthz
docker logs -f zo2api
```

The Docker Hub repository description is generated from `DOCKER.md` during every release. Keep Docker-specific usage, tag, and environment-variable documentation there so Docker Hub stays in sync with the released image.

### macOS Docker Support

The published Docker image supports macOS through Docker Desktop:

- Intel Mac: `linux/amd64`
- Apple Silicon Mac: `linux/arm64`

Docker Desktop usually selects the correct image automatically. This project does not publish native `darwin` container images; the macOS runtime path is Docker Desktop running Linux containers.

## Environment Variables

| Variable | Required | Default | Description |
| --- | --- | --- | --- |
| `ZO_ACCESS_TOKEN` | Yes | None | Zo Computer access token used to call the upstream API. |
| `PROXY_API_KEY` | No | Random key on each start | External API key accepted by this proxy. Set this explicitly for stable clients. |
| `PORT` | No | `8000` | HTTP port used by the local server and Docker container. |
| `PROXY_PROMPT_OVERRIDE` | No | `false` | Enables the request prompt wrapper in `server.js`. |
| `PROXY_OUTPUT_SANITIZE` | No | `false` | Enables response text sanitization in `server.js`. |

If `PROXY_API_KEY` is not set, the server generates a random key during startup. That is useful for testing, but not suitable for SDK configuration because the key changes after every restart.

## API Endpoints

| Method | Path | Description |
| --- | --- | --- |
| `GET` | `/healthz` | Health check. Does not require authentication. |
| `GET` | `/v1/models` | Lists available upstream models in OpenAI-compatible format. |
| `POST` | `/v1/chat/completions` | OpenAI-compatible chat completions endpoint. |
| `POST` | `/v1/messages` | Anthropic-compatible messages endpoint. |

The server also accepts these compatibility paths:

- `/models`
- `/chat/completions`
- `/messages`
- `/v1/v1/models`
- `/v1/v1/chat/completions`
- `/v1/v1/messages`

## Authentication

All API endpoints except `/healthz` require the proxy API key.

Supported headers:

```http
Authorization: Bearer sk-proxy-gateway-v1
```

```http
x-api-key: sk-proxy-gateway-v1
```

```http
anthropic-api-key: sk-proxy-gateway-v1
```

## OpenAI Compatible Usage

List models:

```bash
curl http://localhost:8000/v1/models \
  -H "Authorization: Bearer sk-proxy-gateway-v1"
```

Create a chat completion:

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

Streaming:

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

OpenAI SDK example:

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

## Anthropic Compatible Usage

Create a message:

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

Anthropic SDK example:

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

## Model Mapping

The proxy fetches model metadata from Zo Computer using `/models/available` and caches it in memory. Requested model names are mapped as follows:

- Exact match against upstream `model_name` or `label`
- Names containing `claude` map to an Anthropic model
- Names containing `gpt`, `o1`, `o3`, or `openai` map to an OpenAI model
- Names containing `deepseek` map to a DeepSeek model
- Names containing `gemini` map to a Google model
- Names containing `glm` map to a Z.ai model
- Names containing `minimax` map to a MiniMax model
- Names starting with `zo:` are passed through directly

If no mapping is found, the request is still sent without `model_name`, allowing the upstream service to choose its default behavior.

## Conversation Continuity

The proxy forwards `x-conversation-id` when provided and returns upstream `x-conversation-id` response headers when available.

Example:

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

## Browser Test Page

The repository includes `test-page.html` as a simple browser-based chat test page. Serve the repository directory with any static file server, then open the page in a browser.

Example:

```bash
python3 -m http.server 3000
```

Then open:

```text
http://localhost:3000/test-page.html
```

## Troubleshooting

`ZO_ACCESS_TOKEN is required`

Set `ZO_ACCESS_TOKEN` in `.env`, or export it before running the server.

`401 Invalid or missing API key`

Make sure the request uses the same key as `PROXY_API_KEY` through `Authorization`, `x-api-key`, or `anthropic-api-key`.

`Failed to fetch models from Zo`

Check that `ZO_ACCESS_TOKEN` is valid and the upstream API is reachable from your environment.

Docker port does not respond

Confirm `PORT` is set consistently in `.env`, then check:

```bash
docker compose ps
docker compose logs -f zo2api
```

## CI/CD

The repository includes GitHub Actions workflows:

| Workflow | Trigger | Purpose |
| --- | --- | --- |
| `.github/workflows/ci.yml` | `push` to branches and `pull_request` | Runs CI, dependency audit, CodeQL code audit, then builds the Docker image only after all gates pass. |
| `.github/workflows/release.yml` | `push` tags matching `v*` | Runs CI, dependency audit, CodeQL code audit, creates a GitHub Release, pushes multi-arch Docker images to Docker Hub, then updates the Docker Hub description from `DOCKER.md`. |

The code audit gates include:

- `npm audit --audit-level=moderate --omit=dev` for production dependency vulnerability checks.
- CodeQL JavaScript/TypeScript analysis with `security-extended` and `security-and-quality` query suites.
- Docker image build is gated by CI and both audit jobs.

Configure these GitHub Actions secrets before publishing Docker images:

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `DOCKERHUB_USERNAME` | Secret | Yes | Docker Hub username. |
| `DOCKERHUB_TOKEN` | Secret | Yes | Docker Hub access token. |
| `DOCKERHUB_REPOSITORY` | Variable | No | Full Docker image name, for example `your-dockerhub-user/zo2api`. |

If `DOCKERHUB_REPOSITORY` is not configured, the release workflow pushes to:

```text
${DOCKERHUB_USERNAME}/zo2api
```

Create and push a release tag:

```bash
git tag v1.0.0
git push origin v1.0.0
```

The release workflow publishes these Docker tags:

```text
v1.0.0
1.0.0
1.0
latest
sha-<short-sha>
```

During every `v*` tag release, the workflow rewrites `VERSION` from the tag name before validation, GitHub Release creation, and Docker image build. For example, tag `v1.2.3` produces a `VERSION` file containing `1.2.3`, and that file is copied into the Docker image.

The Docker image is also built with version metadata:

- `/app/VERSION` contains the tag version without the leading `v`.
- `APP_VERSION` is set inside the image.
- OCI labels include `org.opencontainers.image.version` and `org.opencontainers.image.ref.name`.
- Docker Hub receives both the release version tag and `latest`.

## Scripts

| Command | Description |
| --- | --- |
| `npm run check` | Validate `server.js` syntax with `node --check`. |
| `npm start` | Run `node server.js`. |
| `npm run start:local` | Load `.env`, validate `ZO_ACCESS_TOKEN`, then run the server. |
| `npm run deploy` | Build and start the Docker Compose service. |

## Common Maintenance Commands

Validate locally:

```bash
npm run check
npm audit --audit-level=moderate --omit=dev
sh -n scripts/start.sh scripts/deploy.sh
```

Build the Docker image locally:

```bash
docker build -t zo2api:local .
```

Validate Docker Compose config:

```bash
cp .env.example .env
docker compose config
```

## Project Structure

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
