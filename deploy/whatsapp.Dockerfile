# MamaSafe Baileys WhatsApp gateway
# Build: docker build -f ../deploy/whatsapp.Dockerfile -t mamasafe-whatsapp backend/whatsapp
# Context must be backend/whatsapp
FROM node:20-slim

ENV NODE_ENV=production \
    AUTH_DIR=/app/auth

WORKDIR /app

# Install production dependencies first for better layer caching
COPY package.json package-lock.json ./
RUN npm ci --omit=dev

# Application code
COPY src ./src

# The auth/ directory holds the WhatsApp session. Use a volume in compose.
RUN mkdir -p /app/auth

EXPOSE 3001

CMD ["node", "src/index.js"]
