@echo off
REM Test Scraper Service Locally (Windows)
REM Run this before deploying to verify everything works

echo.
echo Testing Scraper Service Locally
echo ======================================
echo.

REM Check if Docker is running
docker info >nul 2>&1
if errorlevel 1 (
    echo X Docker is not running. Please start Docker Desktop.
    exit /b 1
)

echo [OK] Docker is running
echo.

REM Build image
echo Building Docker image...
docker build -t scraper-test . --quiet
if errorlevel 1 (
    echo X Build failed
    exit /b 1
)

echo [OK] Image built successfully
echo.

REM Start container
echo Starting container...
docker run -d -p 8080:8080 --name scraper-test scraper-test >nul
if errorlevel 1 (
    echo X Failed to start container
    exit /b 1
)

REM Wait for service to start
echo Waiting for service to start (5 seconds)...
timeout /t 5 /nobreak >nul

echo.
echo ======================================
echo Testing Endpoints
echo ======================================
echo.

REM Test health endpoint
echo 1. Testing health endpoint...
curl -s http://localhost:8080/health > temp_response.txt
type temp_response.txt
findstr /C:"\"status\":\"ok\"" temp_response.txt >nul
if errorlevel 1 (
    echo.
    echo X Health check failed
    docker logs scraper-test
    docker stop scraper-test >nul 2>&1
    docker rm scraper-test >nul 2>&1
    del temp_response.txt
    exit /b 1
)

echo [OK] Health check passed
echo.

REM Test scraping endpoint
echo 2. Testing scraping endpoint (takes ~20 seconds)...
echo    Scraping 'nike'...
curl -s -X POST http://localhost:8080/scrape -H "Content-Type: application/json" -d "{\"company_name\": \"nike\"}" > temp_scrape.txt
type temp_scrape.txt
findstr /C:"\"success\":true" temp_scrape.txt >nul
if errorlevel 1 (
    echo.
    echo X Scraping test failed
    docker logs scraper-test
    docker stop scraper-test >nul 2>&1
    docker rm scraper-test >nul 2>&1
    del temp_response.txt temp_scrape.txt
    exit /b 1
)

echo [OK] Scraping test passed
echo.

REM Cleanup
echo ======================================
echo [OK] All tests passed!
echo ======================================
echo.
echo Cleaning up...
docker stop scraper-test >nul 2>&1
docker rm scraper-test >nul 2>&1
del temp_response.txt temp_scrape.txt

echo [OK] Container stopped and removed
echo.
echo ======================================
echo [OK] Ready to deploy to Render!
echo ======================================
echo.
echo Next steps:
echo 1. Follow instructions in DEPLOY_NOW.md
echo 2. Deploy to Render
echo 3. Get your production URL
echo 4. Update Vercel with SCRAPER_SERVICE_URL
echo.
pause
