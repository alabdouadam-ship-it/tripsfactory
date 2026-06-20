@echo off
REM TripsFactory Admin Panel Deployment Script (Windows)
REM This script builds and deploys the admin panel with proper cache busting

echo.
echo ========================================
echo 🚀 Starting TripsFactory Admin Panel Deployment
echo ========================================
echo.

REM Step 1: Clean previous build
echo 📦 Step 1: Cleaning previous build...
cd admin
if exist .next rmdir /s /q .next 2>nul
if exist out rmdir /s /q out 2>nul
if exist node_modules\.cache rmdir /s /q node_modules\.cache 2>nul
echo ✅ Clean complete
echo.

REM Step 2: Build
echo 🔨 Step 2: Building admin panel...
call npm run build
if errorlevel 1 (
    echo ❌ Build failed!
    cd ..
    exit /b 1
)
echo ✅ Build complete
echo.

REM Step 3: Verify build output
echo 🔍 Step 3: Verifying build output...
if not exist "out" (
    echo ❌ Build output directory 'out' not found!
    cd ..
    exit /b 1
)

REM Check if new code exists (simplified check for Windows)
findstr /s /m "OLD / BEFORE" out\_next\static\chunks\*.js >nul 2>&1
if errorlevel 1 (
    echo ⚠️  Warning: Could not verify new code in build output
) else (
    echo ✅ New diff view code found in build
)
echo.

cd ..

REM Step 4: Deploy to Firebase
echo 🚀 Step 4: Deploying to Firebase Hosting...
call firebase deploy --only hosting:admin
if errorlevel 1 (
    echo ❌ Deployment failed!
    exit /b 1
)
echo ✅ Deployment complete
echo.

REM Step 5: Instructions
echo ========================================
echo ✨ Deployment Successful!
echo ========================================
echo.
echo ⏳ Please wait 2-3 minutes for CDN propagation
echo.
echo Then, to see the changes:
echo   1. Open your admin panel: https://tripsfactory-admin.web.app/audit-log
echo   2. Hard refresh: Ctrl+Shift+R or Ctrl+F5
echo   3. Or add ?v=2 to URL: https://tripsfactory-admin.web.app/audit-log?v=2
echo.
echo Expected changes:
echo   ✓ Side-by-side diff view (OLD left, NEW right)
echo   ✓ RED highlighting for old values
echo   ✓ GREEN highlighting for new values
echo   ✓ Toggle between 'Diff View' and 'Raw JSON'
echo.
echo If you still see old version after 5 minutes:
echo   - Clear browser cache completely
echo   - Try incognito/private mode
echo   - Wait up to 15 minutes for global CDN propagation
echo.
pause
