# Google Ads Scraper Service

Standalone Playwright service for scraping Google Ads Transparency Center.

## Local Development

```bash
# Install dependencies
npm install

# Install Playwright browsers
npx playwright install chromium --with-deps

# Start server
npm start
```

Server runs on `http://localhost:8080`

## API Endpoints

### Health Check
```bash
GET /health
```

Response:
```json
{
  "status": "ok",
  "service": "google-ads-scraper",
  "timestamp": "2024-01-01T00:00:00.000Z"
}
```

### Scrape Company
```bash
POST /scrape
Content-Type: application/json

{
  "company_name": "nike"
}
```

Response (success):
```json
{
  "success": true,
  "advertiserId": "AR1234567890",
  "advertiserName": "Nike, Inc."
}
```

Response (error):
```json
{
  "success": false,
  "error": "No advertiser found for \"unknown-company\""
}
```

## Docker

### Build
```bash
docker build -t scraper-service .
```

### Run
```bash
docker run -p 8080:8080 scraper-service
```

### Test
```bash
curl -X POST http://localhost:8080/scrape \
  -H "Content-Type: application/json" \
  -d '{"company_name": "nike"}'
```

## Deployment

### Render (Free Tier)
1. Push to GitHub
2. Go to render.com
3. New Web Service → Connect repo
4. Environment: Docker
5. Plan: Free
6. Deploy

### Fly.io
```bash
fly launch
fly deploy
```

### Railway
```bash
railway login
railway init
railway up
```

## Environment Variables

No environment variables required. Service is stateless.

## Performance

- Cold start: ~2-3s (Playwright launch)
- Average scrape time: 15-20s
- Memory usage: ~400-600MB
- Recommended: 512MB RAM minimum
