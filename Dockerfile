

# ============================
# Stage 1 - Build Frontend
# ============================
FROM oven/bun:1 AS frontend-build

WORKDIR /app/frontend

COPY frontend/package.json frontend/bun.lock ./

RUN bun install

COPY frontend/ ./

ENV VITE_API_URL=""

ARG VITE_CLERK_PUBLISHABLE_KEY
ENV VITE_CLERK_PUBLISHABLE_KEY=$VITE_CLERK_PUBLISHABLE_KEY

RUN bun run build


# ============================
# Stage 2 - Build Backend
# ============================
FROM oven/bun:1 AS backend-build

WORKDIR /app/backend

COPY backend/package.json backend/bun.lock ./

RUN bun install

COPY backend/ ./

RUN bun run build


# ============================
# Stage 3 - Production
# ============================
FROM oven/bun:1 AS runner

WORKDIR /app

ENV NODE_ENV=production
ENV PORT=3001

COPY backend/package.json backend/bun.lock ./

RUN bun install --production

COPY --from=backend-build /app/backend/dist ./dist
COPY --from=frontend-build /app/frontend/dist ./public

EXPOSE 3001

CMD ["bun", "run", "dist/server.js"]