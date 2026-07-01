# #Stage 1
# #produce html/css/js under frontend/dist
# FROM node: 22-bookworm-slim AS frontend-build
# WORKDIR /app/frontend
# COPY frontend/package.json frontend/packege-lock.json ./
# RUN bun install --no-audit --no-fund --legacy-peer-deps
# COPY frontend/ ./

# #Empty = browser calls /api on the smae host as the page,
# ENV VITE_API_URL =
# # Public Clerk key is embedded in client JS.
# ARG VITE_CLERK_PUBLISHABLE_KEY
# ENV VITE_CLERK_PUBLISHABLE_KEY=$VITE_CLERK_PUBLISHABLE_KEY
# RUN bun run build


# #Srep 2
# #This backend is ESM JavaScript, so bun build copies src/ to dist/.

# FROM node:22-bookworm-slim AS backend-build
# WORKDIR /app
# COPY backend/package.json backend/package-lock.json ./
# RUN bun install --no-audit --no-fund
# COPY backend/ ./
# RUN bun run build 


# #Step 3
# #Express serves API routes and static files from public/.
# FROM node:22-bookworm-slim AS runner
# WORKDIR /app
# ENV NODE_ENV=production
# ENV PORT=3001

# COPY backend/package.json backend/package-lock.json ./
# RUN bun install --omit=dev --no-audit --no-fund && bun cache clean --force

# COPY --from=backend-build /app/dist ./dist
# COPY --from=frontend-build /app/frontend/dist ./public

# EXPOSE 3001
# USER node

# CMD ["node", "dist/index.js"]


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