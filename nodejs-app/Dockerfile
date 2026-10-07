# ============================================================
#  nodejs-app/Dockerfile
#  Multi-stage: stage 1 installs prod deps, stage 2 is the runtime.
#  Result: small image, no devDependencies, non-root user.
# ============================================================

# ---------- Stage 1: dependencies ----------
FROM node:20-alpine AS deps
WORKDIR /app
COPY package*.json ./
# `npm ci` (not `npm install`): deterministic install from package-lock.json
RUN npm ci --omit=dev

# ---------- Stage 2: runtime ----------
FROM node:20-alpine AS runtime
ENV NODE_ENV=production \
    PORT=3000
WORKDIR /app

# copy ONLY what the runtime needs from the deps stage
COPY --from=deps /app/node_modules ./node_modules
COPY package*.json ./
COPY src ./src

# never run containers as root (CIS Docker benchmark / Trivy will flag it)
RUN addgroup -g 1001 -S appgroup \
 && adduser  -u 1001 -S appuser -G appgroup \
 && chown -R appuser:appgroup /app
USER appuser

EXPOSE 3000

# Jenkins uses this to verify the container is really healthy after deploy
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD node -e "require('http').get('http://127.0.0.1:'+(process.env.PORT||3000)+'/health',r=>process.exit(r.statusCode===200?0:1)).on('error',()=>process.exit(1))"

CMD ["node", "src/server.js"]
