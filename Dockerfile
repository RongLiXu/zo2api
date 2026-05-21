FROM node:22-alpine

WORKDIR /app

ARG APP_VERSION=dev
ARG SOURCE_TAG=dev

ENV NODE_ENV=production
ENV PORT=8000
ENV APP_VERSION=${APP_VERSION}

LABEL org.opencontainers.image.title="zo2api"
LABEL org.opencontainers.image.version="${APP_VERSION}"
LABEL org.opencontainers.image.ref.name="${SOURCE_TAG}"

COPY package.json ./
COPY VERSION ./
COPY server.js ./

RUN chown -R node:node /app

USER node

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD node -e "require('http').get('http://127.0.0.1:' + (process.env.PORT || 8000) + '/healthz', r => process.exit(r.statusCode === 200 ? 0 : 1)).on('error', () => process.exit(1))"

CMD ["node", "server.js"]
