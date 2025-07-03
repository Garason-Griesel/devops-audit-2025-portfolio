# Multi-stage build for production optimization
FROM node:18-alpine AS base

# Install security updates and required packages
RUN apk update && apk upgrade && \
    apk add --no-cache curl dumb-init && \
    rm -rf /var/cache/apk/*

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nextjs -u 1001

WORKDIR /app

# Copy package files
COPY package*.json ./
COPY server/package*.json ./server/
COPY client/package*.json ./client/

# Install dependencies
FROM base AS deps
RUN npm ci --only=production && npm cache clean --force
RUN cd server && npm ci --only=production && npm cache clean --force
RUN cd client && npm ci --only=production && npm cache clean --force

# Build stage
FROM base AS builder
COPY --from=deps /app/node_modules ./node_modules
COPY --from=deps /app/server/node_modules ./server/node_modules
COPY --from=deps /app/client/node_modules ./client/node_modules

COPY . .

# Build the application
RUN cd client && npm run build
RUN cd server && npm run build || echo "No build script found"

# Production stage
FROM base AS runner

# Copy built application
COPY --from=builder --chown=nextjs:nodejs /app/server ./server
COPY --from=builder --chown=nextjs:nodejs /app/client/dist ./client/dist
COPY --from=deps --chown=nextjs:nodejs /app/server/node_modules ./server/node_modules

# Set environment variables
ENV NODE_ENV=production
ENV PORT=3000

# Expose port
EXPOSE 3000

# Switch to non-root user
USER nextjs

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

# Start the application
ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "server/index.js"]
