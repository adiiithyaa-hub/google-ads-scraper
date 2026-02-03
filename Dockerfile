FROM node:20-bookworm-slim

# Install Playwright system dependencies
# This installs Chromium and all required libraries (libnss3, libatk, etc.)
RUN npx -y playwright@1.48.0 install --with-deps chromium

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install Node.js dependencies
RUN npm ci --only=production

# Copy application code
COPY . .

# Create non-root user for security
RUN useradd -m -u 1001 scraper && chown -R scraper:scraper /app
USER scraper

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD node -e "require('http').get('http://localhost:8080/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Start server
CMD ["node", "server.js"]
