# Nexus 서버 이미지 — deploy/docker-compose.prod.yml 이 쓴다.
#
# 두 단계다. `build` 는 개발 의존성까지 깔아 컴파일하고, 마지막 단계는 운영 의존성과
# 산출물만 옮긴다. 마이그레이션 · 시드는 prisma CLI · ts-node(개발 의존성)가 필요해
# compose 의 `migrate` 서비스가 `build` 단계를 그대로 쓴다.
#
# bookworm-slim 을 쓰는 이유: Prisma 엔진 · argon2 · sharp 가 glibc 용 미리 빌드된 바이너리를
# 내려받는다. alpine(musl)이면 일부가 소스 빌드로 떨어져 이미지 안에 컴파일러가 필요해진다.
FROM node:22-bookworm-slim AS build
WORKDIR /app
# Prisma 엔진이 libssl 을 찾는다 — 없으면 쿼리 엔진이 뜨지 않는다.
RUN apt-get update && apt-get install -y --no-install-recommends openssl \
  && rm -rf /var/lib/apt/lists/*

# 의존성 층을 소스 층과 나눈다 — 소스만 바뀐 빌드가 npm ci 를 다시 돌지 않게.
COPY package.json package-lock.json ./
RUN npm ci
COPY prisma ./prisma
RUN npx prisma generate
COPY tsconfig.json tsconfig.build.json nest-cli.json ./
COPY src ./src
RUN npm run build

# 운영 의존성만 남긴 node_modules. 생성된 Prisma Client(node_modules/.prisma)는
# 패키지가 아니라 prune 대상이 아니다 — 실행 단계에서 그대로 쓴다.
FROM build AS prod-deps
RUN npm prune --omit=dev

FROM node:22-bookworm-slim
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends openssl \
  && rm -rf /var/lib/apt/lists/*
ENV NODE_ENV=production
COPY --from=prod-deps /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY package.json ./
# 로컬 드라이버를 쓸 때의 저장 위치. 볼륨을 여기 붙인다(STORAGE_LOCAL_DIR).
RUN mkdir -p /data/storage && chown node:node /data/storage
USER node
EXPOSE 3000
CMD ["node", "dist/main"]
