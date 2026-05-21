# zo2api Docker Image

Zo Computer API reverse proxy with OpenAI and Anthropic compatible endpoints.

This image runs `zo2api`, a lightweight Node.js gateway that forwards requests to `api.zo.computer` and exposes SDK-friendly API paths for OpenAI-style and Anthropic-style clients.

## Features

- OpenAI compatible `POST /v1/chat/completions`
- OpenAI compatible `GET /v1/models`
- Anthropic compatible `POST /v1/messages`
- Streaming and non-streaming responses
- Tool/function call conversion
- Proxy API key protection
- Built-in unauthenticated health check at `GET /healthz`
- Multi-arch images for `linux/amd64` and `linux/arm64`

## Quick Start

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

Check the service:

```bash
curl http://localhost:8000/healthz
```

List models:

```bash
curl http://localhost:8000/v1/models \
  -H "Authorization: Bearer sk-proxy-gateway-v1"
```

## Environment Variables

| Variable | Required | Default | Description |
| --- | --- | --- | --- |
| `ZO_ACCESS_TOKEN` | Yes | None | Zo Computer access token used to call the upstream API. |
| `PROXY_API_KEY` | No | Random key on each start | External API key accepted by this proxy. Set it explicitly for stable clients. |
| `PORT` | No | `8000` | HTTP port used by the server. |
| `PROXY_PROMPT_OVERRIDE` | No | `false` | Enables the request prompt wrapper in `server.js`. |
| `PROXY_OUTPUT_SANITIZE` | No | `false` | Enables response text sanitization in `server.js`. |

## API Paths

| Method | Path | Description |
| --- | --- | --- |
| `GET` | `/healthz` | Health check. Does not require authentication. |
| `GET` | `/v1/models` | Lists upstream models in OpenAI-compatible format. |
| `POST` | `/v1/chat/completions` | OpenAI-compatible chat completions endpoint. |
| `POST` | `/v1/messages` | Anthropic-compatible messages endpoint. |

All API paths except `/healthz` require the configured proxy API key.

## Image Tags

Every `v*` release tag publishes and updates these Docker tags:

```text
v1.2.3
1.2.3
1.2
latest
sha-<short-sha>
```

The image includes version metadata:

- `/app/VERSION` contains the release version without the leading `v`.
- `APP_VERSION` is set inside the image.
- OCI labels include `org.opencontainers.image.version` and `org.opencontainers.image.ref.name`.

## Docker Compose

For Compose deployment, use the repository `docker-compose.yml` and `.env.example` files:

```bash
cp .env.example .env
./scripts/deploy.sh
```

## Source

The source repository contains the Dockerfile, Compose file, release pipeline, and usage examples.
