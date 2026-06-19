@echo off
echo.
echo ========================================
echo 🧹 Cleaning Cache and Restarting Dev Server
echo ========================================
echo.

cd admin

echo 📦 Step 1: Cleaning cache directories...
if exist .next rmdir /s /q .next 2>nul
if exist out rmdir /s /q out 2>nul
if exist node_modules\.cache rmdir /s /q node_modules\.cache 2>nul
echo ✅ Cache cleaned
echo.

echo 🚀 Step 2: Starting development server...
echo.
echo IMPORTANT: After server starts:
echo   1. Open http://localhost:3000/audit-log
echo   2. Press Ctrl+Shift+R (hard refresh)
echo   3. Or press Ctrl+F5
echo   4. Check the diff view!
echo.

call npm run dev
