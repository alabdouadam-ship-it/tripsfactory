#!/bin/bash

# TripShip Admin Panel Deployment Script
# This script builds and deploys the admin panel with proper cache busting

set -e  # Exit on error

echo "🚀 Starting TripShip Admin Panel Deployment"
echo "========================================"
echo ""

# Step 1: Clean previous build
echo "📦 Step 1: Cleaning previous build..."
cd admin
rm -rf .next out node_modules/.cache 2>/dev/null || true
echo "✅ Clean complete"
echo ""

# Step 2: Build
echo "🔨 Step 2: Building admin panel..."
npm run build
if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi
echo "✅ Build complete"
echo ""

# Step 3: Verify build output
echo "🔍 Step 3: Verifying build output..."
if [ ! -d "out" ]; then
    echo "❌ Build output directory 'out' not found!"
    exit 1
fi

# Check if new code exists
if grep -r "OLD / BEFORE" out/_next/static/chunks/ > /dev/null 2>&1; then
    echo "✅ New diff view code found in build"
else
    echo "⚠️  Warning: Could not verify new code in build output"
fi
echo ""

cd ..

# Step 4: Deploy to Firebase
echo "🚀 Step 4: Deploying to Firebase Hosting..."
firebase deploy --only hosting:admin
if [ $? -ne 0 ]; then
    echo "❌ Deployment failed!"
    exit 1
fi
echo "✅ Deployment complete"
echo ""

# Step 5: Instructions
echo "✨ Deployment Successful!"
echo "========================================"
echo ""
echo "⏳ Please wait 2-3 minutes for CDN propagation"
echo ""
echo "Then, to see the changes:"
echo "  1. Open your admin panel: https://tripship-admin.web.app/audit-log"
echo "  2. Hard refresh: Ctrl+Shift+R (Windows/Linux) or Cmd+Shift+R (Mac)"
echo "  3. Or add ?v=2 to URL: https://tripship-admin.web.app/audit-log?v=2"
echo ""
echo "Expected changes:"
echo "  ✓ Side-by-side diff view (OLD left, NEW right)"
echo "  ✓ RED highlighting for old values"
echo "  ✓ GREEN highlighting for new values"
echo "  ✓ Toggle between 'Diff View' and 'Raw JSON'"
echo ""
echo "If you still see old version after 5 minutes:"
echo "  - Clear browser cache completely"
echo "  - Try incognito/private mode"
echo "  - Wait up to 15 minutes for global CDN propagation"
echo ""
