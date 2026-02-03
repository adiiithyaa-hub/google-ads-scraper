FROM node:20-bookworm-slim

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install Node.js dependencies
RUN npm ci --only=production

# Install Playwright browsers and system dependencies
# This must run AFTER npm install to use the correct Playwright version
RUN npx playwright install --with-deps chromium

# Copy application code
COPY . .

# Create non-root user for security
RUN useradd -m -u 1001 scraper && \
    chown -R scraper:scraper /app && \
    mkdir -p /home/scraper/.cache && \
    cp -r /root/.cache/ms-playwright /home/scraper/.cache/ && \
    chown -R scraper:scraper /home/scraper/.cache

USER scraper

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD node -e "require('http').get('http://localhost:8080/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Start server
CMD ["node", "server.js"]
