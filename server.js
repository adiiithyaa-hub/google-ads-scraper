import express from 'express';
import { extractAdvertiserId, searchAdvertisers } from './scraper.js';

const app = express();
app.use(express.json());

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    service: 'Google Ads Scraper',
    status: 'running',
    endpoints: {
      health: 'GET /health',
      scrape: 'POST /scrape (body: {company_name})',
      search: 'POST /search (body: {company_name, region})'
    }
  });
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    service: 'google-ads-scraper',
    timestamp: new Date().toISOString()
  });
});

// Main scraping endpoint
app.post('/scrape', async (req, res) => {
  const { company_name } = req.body;

  if (!company_name) {
    return res.status(400).json({
      success: false,
      error: 'company_name is required'
    });
  }

  console.log(`[Server] Received scrape request for: ${company_name}`);
  const startTime = Date.now();

  try {
    const result = await extractAdvertiserId(company_name);
    const duration = Date.now() - startTime;

    console.log(`[Server] Scrape completed in ${duration}ms. Success: ${result.success}`);

    if (result.success) {
      res.json(result);
    } else {
      res.status(404).json(result);
    }
  } catch (error) {
    console.error('[Server] Unexpected error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal scraper error: ' + error.message
    });
  }
});

// Search endpoint - Returns all matches without scraping
app.post('/search', async (req, res) => {
  const { company_name, region = 'US' } = req.body;

  if (!company_name) {
    return res.status(400).json({
      success: false,
      error: 'company_name is required'
    });
  }

  console.log(`[Server] Received search request for: ${company_name} (region: ${region})`);
  const startTime = Date.now();

  try {
    const result = await searchAdvertisers(company_name, region);
    const duration = Date.now() - startTime;

    console.log(`[Server] Search completed in ${duration}ms. Found: ${result.matches?.length || 0} matches`);

    if (result.success) {
      res.json(result);
    } else {
      res.status(404).json(result);
    }
  } catch (error) {
    console.error('[Server] Unexpected error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal scraper error: ' + error.message
    });
  }
});

// Start server
const PORT = process.env.PORT || 8080;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`[Server] 🚀 Scraper service running on port ${PORT}`);
  console.log(`[Server] Health check: http://localhost:${PORT}/health`);
  console.log(`[Server] Scrape endpoint: POST http://localhost:${PORT}/scrape`);
});
