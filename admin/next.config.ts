import type { NextConfig } from "next";
import path from "path";
import fs from "fs";

// Ensure .env.local is loaded before Next/Turbopack runs (fixes Turbopack not loading NEXT_PUBLIC_* in some setups)
const envLocalPath = path.join(__dirname, ".env.local");
if (fs.existsSync(envLocalPath)) {
  const content = fs.readFileSync(envLocalPath, "utf8");
  for (const line of content.split("\n")) {
    const m = line.match(/^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)\s*$/);
    if (m) {
      const key = m[1];
      const value = m[2].replace(/^["']|["']$/g, "").trim();
      if (key.startsWith("NEXT_PUBLIC_") && !process.env[key]) process.env[key] = value;
    }
  }
}

const nextConfig: NextConfig = {
  // Frontend-only SPA: no Next.js server runtime. The backend is Supabase
  // (RLS + Edge Functions). Static export produces a fully client-rendered
  // bundle with no API routes, no Server Actions, no SSR.
  //
  // Compatible because every page is `'use client'` and uses runtime data
  // fetching (supabase.auth + supabase.from + supabase.functions.invoke).
  // The map page already uses dynamic({ ssr: false }).
  //
  // To re-enable a Node runtime locally for debugging, comment this line.
  output: "export",

  // Disable image optimization since static export doesn't run the
  // optimizer. Admin doesn't rely on next/image for now.
  images: {
    unoptimized: true,
  },

  // Use admin directory as project root so Tailwind and deps resolve from admin/node_modules
  turbopack: {
    root: path.resolve(process.cwd()),
  },
  // Expose env so client bundle gets them (helps when Turbopack doesn't load .env.local in time)
  env: {
    NEXT_PUBLIC_SUPABASE_URL: process.env.NEXT_PUBLIC_SUPABASE_URL || "",
    NEXT_PUBLIC_SUPABASE_ANON_KEY: process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || "",
  },
};

export default nextConfig;
