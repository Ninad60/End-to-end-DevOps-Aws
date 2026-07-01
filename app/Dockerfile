# Use slim Node 18 Alpine for small image size
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Copy package files first (layer caching - only reinstalls if package.json changes)
COPY package*.json ./

# Install only production dependencies
RUN npm ci --only=production

# Copy application code
COPY index.js ./

# Don't run as root - security best practice
USER node

# Expose port
EXPOSE 3000

# Health check built into Docker image
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1

# Start the app
CMD ["node", "index.js"]
