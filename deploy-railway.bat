@echo off
REM Automated Railway Deployment Script
REM This script deploys the scraper service to Railway

echo.
echo ========================================
echo Railway Deployment Script
echo ========================================
echo.

REM Check if Railway CLI is installed
where railway >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Railway CLI not found
    echo Installing Railway CLI...
    call npm install -g @railway/cli
    if errorlevel 1 (
        echo [ERROR] Failed to install Railway CLI
        exit /b 1
    )
)

echo [OK] Railway CLI is installed
echo.

REM Check if user is logged in
railway whoami >nul 2>&1
if errorlevel 1 (
    echo ========================================
    echo AUTHENTICATION REQUIRED
    echo ========================================
    echo.
    echo Railway needs to authenticate your account.
    echo This will open your browser for login.
    echo.
    echo Please:
    echo 1. Click "Authorize" in the browser
    echo 2. Come back to this window
    echo.
    pause
    echo.
    echo Opening browser for login...
    railway login
    if errorlevel 1 (
        echo [ERROR] Login failed
        exit /b 1
    )
)

echo [OK] Authenticated
echo.

REM Initialize project if not exists
if not exist "railway.json" (
    echo [STEP 1/3] Initializing Railway project...
    echo google-ads-scraper | railway init
    if errorlevel 1 (
        echo [ERROR] Failed to initialize project
        exit /b 1
    )
    echo [OK] Project initialized
) else (
    echo [OK] Project already initialized
)

echo.

REM Deploy
echo [STEP 2/3] Deploying to Railway...
echo This may take 3-5 minutes...
echo.
railway up --detach
if errorlevel 1 (
    echo [ERROR] Deployment failed
    echo Check logs: railway logs
    exit /b 1
)

echo [OK] Deployment started
echo.

REM Wait for deployment
echo Waiting for deployment to complete...
timeout /t 10 /nobreak >nul

REM Get status and URL
echo [STEP 3/3] Getting service URL...
echo.
railway status > railway_status.txt
type railway_status.txt

echo.
echo ========================================
echo DEPLOYMENT COMPLETE!
echo ========================================
echo.

REM Extract URL from status
for /f "tokens=*" %%i in ('railway status ^| findstr "up.railway.app"') do set SERVICE_URL=%%i

if defined SERVICE_URL (
    echo Your scraper service URL:
    echo %SERVICE_URL%
    echo.
    echo Testing health endpoint...
    timeout /t 5 /nobreak >nul
    curl -s %SERVICE_URL%/health
    echo.
    echo.
    echo ========================================
    echo NEXT STEP: Configure Vercel
    echo ========================================
    echo.
    echo 1. Copy this URL:
    echo    %SERVICE_URL%
    echo.
    echo 2. Add to Vercel environment variables:
    echo    Name: SCRAPER_SERVICE_URL
    echo    Value: %SERVICE_URL%
    echo.
    echo 3. Deploy Vercel:
    echo    git checkout main
    echo    git merge adithya-v91
    echo    git push origin main
    echo.
) else (
    echo [INFO] Could not extract URL automatically
    echo Run: railway status
    echo.
)

del railway_status.txt

echo Deployment complete!
echo.
pause
