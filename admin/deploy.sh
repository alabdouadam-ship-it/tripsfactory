#!/bin/bash

# Admin Panel Deployment Script
# This script builds the Next.js admin panel with environment variables
# and deploys it to Firebase Hosting

set -e  # Exit on error

echo "🚀 Starting admin panel deployment..."

# Check if .env.local exists
if [ ! -f ".env.local" ]; then
    echo "❌ Error: .env.local file not found!"
    echo "Please create .env.local with NEXT_PUBLIC_SUPABASE_URL and NEXT_PUBLIC_SUPABASE_ANON_KEY"
    exit 1
fi

# Load environment variables from .env.local
export $(cat .env.local | grep -v '^#' | xargs)

# Verify required environment variables
if [ -z "$NEXT_PUBLIC_SUPABASE_URL" ]; then
    echo "❌ Error: NEXT_PUBLIC_SUPABASE_URL is not set in .env.local"
    exit 1
fi

if [ -z "$NEXT_PUBLIC_SUPABASE_ANON_KEY" ]; then
    echo "❌ Error: NEXT_PUBLIC_SUPABASE_ANON_KEY is not set in .env.local"
    exit 1
fi

echo "✅ Environment variables loaded"
echo "📦 Building admin panel..."

# Build the Next.js app
npm run build

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

echo "✅ Build successful"
echo "🚀 Deploying to Firebase Hosting..."

# Deploy to Firebase (run from parent directory)
cd ..
firebase deploy --only hosting:admin

if [ $? -ne 0 ]; then
    echo "❌ Deployment failed!"
    exit 1
fi

echo "✅ Deployment successful!"
echo "🎉 Admin panel is now live at https://tripsfactory-admin.web.app"
