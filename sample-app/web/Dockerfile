FROM node:16.14.2-slim AS builder

WORKDIR /app
COPY package.json .
COPY yarn.lock .
RUN yarn install

COPY . .
RUN yarn build

FROM node:16.14.2-slim AS runner

ENV HOST=0.0.0.0
ENV EXPOSE_PORT=80
EXPOSE ${EXPOSE_PORT}

WORKDIR /app
COPY package.json .
COPY yarn.lock .
RUN yarn install --production

COPY --from=builder /app/.nuxt ./.nuxt

CMD yarn start --port ${EXPOSE_PORT}
