import playwright from 'playwright';

/**
 * Extracts Google Ads advertiser ID for a company
 * @param {string} companyName - Company name to search for
 * @returns {Promise<{success: boolean, advertiserId?: string, error?: string}>}
 */
export async function extractAdvertiserId(companyName) {
  let browser = null;

  try {
    console.log(`[Scraper] Launching browser for "${companyName}"`);

    browser = await playwright.chromium.launch({
      headless: true,
      args: [
        '--no-sandbox',
        '--disable-setuid-sandbox',
        '--disable-dev-shm-usage',
        '--disable-accelerated-2d-canvas',
        '--disable-gpu',
      ]
    });

    const page = await browser.newPage();
    await page.setViewportSize({ width: 1280, height: 720 });

    console.log('[Scraper] Navigating to Google Ads Transparency Center...');
    await page.goto('https://adstransparency.google.com/?region=US', {
      waitUntil: 'domcontentloaded',
      timeout: 30000
    });

    // Wait for page to fully render
    await page.waitForTimeout(3000);

    const pageTitle = await page.title();
    console.log(`[Scraper] Page title: ${pageTitle}`);

    // Find search input
    console.log('[Scraper] Looking for search input...');
    const searchInput = await page.$('input[type="text"]');

    if (!searchInput) {
      const bodyHTML = await page.evaluate(() => document.body.innerHTML.substring(0, 1000));
      console.error('[Scraper] No search input found. Page HTML:', bodyHTML);
      throw new Error('Search box not found. Google Ads Transparency Center may have changed their layout.');
    }

    // Type company name
    console.log(`[Scraper] Found search box, typing "${companyName}"...`);
    await searchInput.click();
    await page.waitForTimeout(500);
    await searchInput.type(companyName, { delay: 100 });

    // Wait for dropdown to appear
    console.log('[Scraper] Waiting for dropdown results (8 seconds)...');
    await page.waitForTimeout(8000);

    // Check for dropdown items
    console.log('[Scraper] Looking for dropdown items...');
    let dropdownItems = await page.$$('material-select-item[role="option"]');
    console.log(`[Scraper] Found ${dropdownItems.length} dropdown items`);

    // If no items, wait longer
    if (dropdownItems.length === 0) {
      console.log('[Scraper] No items yet, waiting 5 more seconds...');
      await page.waitForTimeout(5000);
      dropdownItems = await page.$$('material-select-item[role="option"]');
      console.log(`[Scraper] Found ${dropdownItems.length} dropdown items after wait`);
    }

    if (dropdownItems.length === 0) {
      const dropdownHTML = await page.evaluate(() => {
        const dropdown = document.querySelector('material-select-dropdown');
        return dropdown ? dropdown.innerHTML.substring(0, 500) : 'No dropdown found';
      });
      console.log('[Scraper] Dropdown HTML:', dropdownHTML);
      throw new Error(`No advertiser found for "${companyName}". The company may not have Google Ads, or try a different name.`);
    }

    // Get text of first item for logging
    const firstItemText = await page.evaluate(() => {
      const firstItem = document.querySelector('material-select-item[role="option"]');
      return firstItem ? firstItem.textContent.trim() : '';
    });
    console.log(`[Scraper] First result: ${firstItemText}`);

    // Click using JavaScript (more reliable than Playwright click - from v88)
    console.log('[Scraper] Clicking first result with JavaScript...');

    await page.evaluate(() => {
      const firstItem = document.querySelector('material-select-item[role="option"]');
      if (firstItem) {
        firstItem.scrollIntoView({ behavior: 'smooth', block: 'center' });
        firstItem.click();
      }
    });

    console.log('[Scraper] Click executed, waiting for URL change...');

    // Poll for URL change instead of waitForNavigation (v88 approach)
    let advertiserId = null;
    const initialUrl = 'https://adstransparency.google.com/?region=US';

    for (let i = 0; i < 30; i++) { // 30 attempts = 15 seconds max
      await page.waitForTimeout(500);
      const currentUrl = page.url();

      if (currentUrl !== initialUrl) {
        console.log(`[Scraper] URL changed after ${i * 0.5}s: ${currentUrl}`);
        const match = currentUrl.match(/\/advertiser\/([A-Z0-9_-]+)/);
        if (match) {
          advertiserId = match[1];
          break;
        }
      }
    }

    let currentUrl = page.url();
    console.log('[Scraper] Final URL:', currentUrl);

    let match = advertiserId ? { 1: advertiserId } : currentUrl.match(/\/advertiser\/([A-Z0-9_-]+)/);

    // If no advertiser ID in URL, check if we're on search results page
    if (!match) {
      console.log('[Scraper] No advertiser ID in URL. Checking for additional steps...');

      // Check if there's a "View Advertiser" or similar link to click
      const advertiserLink = await page.$('a[href*="/advertiser/"]');

      if (advertiserLink) {
        console.log('[Scraper] Found advertiser link, clicking...');
        await Promise.all([
          page.waitForNavigation({ waitUntil: 'domcontentloaded', timeout: 15000 }),
          advertiserLink.click()
        ]);

        await page.waitForTimeout(2000);
        currentUrl = page.url();
        console.log('[Scraper] New URL after second click:', currentUrl);
        match = currentUrl.match(/\/advertiser\/([A-Z0-9_-]+)/);
      }
    }

    if (!match) {
      throw new Error('Failed to extract advertiser ID from URL');
    }

    if (!advertiserId) {
      advertiserId = match[1];
    }
    console.log(`[Scraper] ✅ Found advertiser ID: ${advertiserId}`);

    return {
      success: true,
      advertiserId,
      advertiserName: firstItemText
    };

  } catch (error) {
    console.error('[Scraper] Error:', error.message);
    return {
      success: false,
      error: error.message
    };
  } finally {
    if (browser) {
      await browser.close();
      console.log('[Scraper] Browser closed');
    }
  }
}
