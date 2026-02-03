#!/bin/bash

# Test Scraper Service Locally
# Run this before deploying to verify everything works

set -e

echo "🧪 Testing Scraper Service Locally"
echo "======================================"
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker Desktop."
    exit 1
fi

echo "✅ Docker is running"
echo ""

# Build image
echo "📦 Building Docker image..."
docker build -t scraper-test . --quiet

echo "✅ Image built successfully"
echo ""

# Start container
echo "🚀 Starting container..."
docker run -d -p 8080:8080 --name scraper-test scraper-test > /dev/null

# Wait for service to start
echo "⏳ Waiting for service to start (5 seconds)..."
sleep 5

echo ""
echo "======================================"
echo "Testing Endpoints"
echo "======================================"
echo ""

# Test health endpoint
echo "1️⃣  Testing health endpoint..."
HEALTH_RESPONSE=$(curl -s http://localhost:8080/health)
echo "Response: $HEALTH_RESPONSE"

if echo "$HEALTH_RESPONSE" | grep -q '"status":"ok"'; then
    echo "✅ Health check passed"
else
    echo "❌ Health check failed"
    docker logs scraper-test
    docker stop scraper-test > /dev/null 2>&1
    docker rm scraper-test > /dev/null 2>&1
    exit 1
fi

echo ""

# Test scraping endpoint
echo "2️⃣  Testing scraping endpoint (this takes ~20 seconds)..."
echo "   Scraping 'nike'..."

SCRAPE_RESPONSE=$(curl -s -X POST http://localhost:8080/scrape \
  -H "Content-Type: application/json" \
  -d '{"company_name": "nike"}')

echo "Response: $SCRAPE_RESPONSE"

if echo "$SCRAPE_RESPONSE" | grep -q '"success":true'; then
    echo "✅ Scraping test passed"
    ADVERTISER_ID=$(echo "$SCRAPE_RESPONSE" | grep -o '"advertiserId":"[^"]*"' | cut -d'"' -f4)
    echo "   Advertiser ID: $ADVERTISER_ID"
else
    echo "❌ Scraping test failed"
    echo "Container logs:"
    docker logs scraper-test
    docker stop scraper-test > /dev/null 2>&1
    docker rm scraper-test > /dev/null 2>&1
    exit 1
fi

echo ""
echo "======================================"
echo "✅ All tests passed!"
echo "======================================"
echo ""

# Cleanup
echo "🧹 Cleaning up..."
docker stop scraper-test > /dev/null 2>&1
docker rm scraper-test > /dev/null 2>&1

echo "✅ Container stopped and removed"
echo ""
echo "======================================"
echo "✅ Ready to deploy to Render!"
echo "======================================"
echo ""
echo "Next steps:"
echo "1. Follow instructions in DEPLOY_NOW.md"
echo "2. Deploy to Render"
echo "3. Get your production URL"
echo "4. Update Vercel with SCRAPER_SERVICE_URL"
