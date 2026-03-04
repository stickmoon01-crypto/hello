FROM node:22-bookworm-slim AS base

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /app

# Install only necessary system dependencies (no Whisper stage)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    curl \
    make \
    libnss3 \
    libdbus-1-3 \
    libatk1.0-0 \
    libgbm-dev \
    libasound2 \
    libxrandr2 \
    libxkbcommon-dev \
    libxfixes3 \
    libxcomposite1 \
    libxdamage1 \
    libatk-bridge2.0-0 \
    libpango-1.0-0 \
    libcairo2 \
    libcups2 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Setup pnpm (stable version)
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
ENV COREPACK_ENABLE_DOWNLOAD_PROMPT=0
RUN corepack enable && corepack prepare pnpm@8.15.9 --activate

# Install dependencies (including dev deps for build)
COPY package.json pnpm-lock.yaml* ./
RUN pnpm install --frozen-lockfile

# Copy all source code (Remotion needs full src/ at build time)
COPY . .

# Build the app
RUN pnpm build

# Final lightweight runtime stage
FROM node:22-bookworm-slim

WORKDIR /app

# Install runtime deps only
RUN apt-get update && apt-get install -y --no-install-recommends ffmpeg && rm -rf /var/lib/apt/lists/*

COPY --from=base /app/node_modules ./node_modules
COPY --from=base /app/dist ./dist
COPY --from=base /app/static ./static
COPY --from=base /app/package.json ./

# App configuration
ENV NODE_ENV=production
ENV DOCKER=true
ENV PORT=3123

EXPOSE 3123

CMD ["pnpm", "start"]

