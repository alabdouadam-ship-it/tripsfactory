@echo off
echo.
echo ========================================
echo 🧪 Testing New Component with Debug Markers
echo ========================================
echo.

cd admin

echo 📦 Step 1: Cleaning ALL cache...
if exist .next rmdir /s /q .next 2>nul
if exist out rmdir /s /q out 2>nul
if exist node_modules\.cache rmdir /s /q node_modules\.cache 2>nul
if exist .turbo rmdir /s /q .turbo 2>nul
echo ✅ Cache cleaned
echo.

echo 🔨 Step 2: Building...
call npm run build
if errorlevel 1 (
    echo ❌ Build failed!
    pause
    exit /b 1
)
echo ✅ Build complete
echo.

echo 🚀 Step 3: Starting dev server...
echo.
echo ========================================
echo IMPORTANT INSTRUCTIONS:
echo ========================================
echo.
echo 1. Open INCOGNITO window (Ctrl+Shift+N)
echo 2. Go to: http://localhost:3000/audit-log
echo 3. Login
echo 4. Click "Inspect" on any audit log entry
echo.
echo YOU SHOULD SEE:
echo   - Purple banner saying "NEW DIFF VIEW COMPONENT LOADED!"
echo   - Toggle buttons: [Diff View] [Raw JSON]
echo   - Side-by-side layout with RED/GREEN highlighting
echo.
echo IF YOU DON'T SEE THE PURPLE BANNER:
echo   - The component is NOT being loaded
echo   - There's a different issue
echo.
echo Press Ctrl+C to stop server when done testing
echo.
pause

call npm run dev
