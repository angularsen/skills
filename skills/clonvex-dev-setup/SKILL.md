---
name: clonvex-dev-setup
description: Bootstrap a Clerk + Convex + Next.js project with local and cloud dev modes, npm scripts, environment files, and WebSocket proxy configuration. Use this skill when setting up a new Next.js app with Convex backend and Clerk authentication, or when adding local/cloud dev mode switching to an existing Clerk + Convex project.
metadata:
  author: angularsen
  version: "1.0.0"
license: MIT
---

# Clerk + Convex Dev Setup

Bootstrap a Next.js project with Clerk authentication and Convex backend, configured for both local and cloud development.

## What This Sets Up

- `npm run dev:local` — Next.js dev server pointing at local Convex (`http://127.0.0.1:3210`)
- `npm run dev:cloud` — Next.js dev server pointing at cloud Convex deployment
- `npm run convex:local` — starts the local Convex backend
- `npm run convex:cloud` — runs `convex dev` against cloud deployment
- `npm run convex:clear` — clears local Convex data
- Clerk authentication with `ClerkProvider`
- Convex real-time backend with `ConvexProvider`

## Prerequisites

- Node.js 18, 20, 22, or 24 (Convex does not support 25+)
- A Clerk account and app at https://dashboard.clerk.com
- A Convex account at https://convex.dev

## Step 1: Install Dependencies

Install the required npm packages:

```bash
npm install convex @clerk/nextjs
npm install -D cross-env
```

## Step 2: Environment Files

Create `.env.local` with the following structure. Replace placeholder values with your actual keys.

```bash
# Clerk Authentication (https://dashboard.clerk.com)
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_your-key-here
CLERK_SECRET_KEY=sk_test_your-key-here

# Convex — uncomment ONE of the following pairs:

# Local mode:
CONVEX_DEPLOYMENT=local:local-yourname-yourapp-1
NEXT_PUBLIC_CONVEX_URL=http://127.0.0.1:3210

# Cloud mode:
# CONVEX_DEPLOYMENT=dev:your-deployment-name
# NEXT_PUBLIC_CONVEX_URL=https://your-deployment-name.convex.cloud
```

Add to `.env.local.example` as a template (same content with placeholder values) and ensure `.env.local` is in `.gitignore`.

## Step 3: NPM Scripts

Add these scripts to `package.json`:

```json
{
  "scripts": {
    "predev:local": "node -e \"const http=require('http');const r=http.get('http://127.0.0.1:3210',()=>process.exit(0));r.on('error',()=>{console.error('\\x1b[31mLocal Convex not running! Start with: npm run convex:local\\x1b[0m');process.exit(1)});r.setTimeout(1000,()=>{r.destroy();console.error('\\x1b[31mLocal Convex not running! Start with: npm run convex:local\\x1b[0m');process.exit(1)})\"",
    "dev": "next dev",
    "dev:local": "cross-env NEXT_PUBLIC_CONVEX_URL=http://127.0.0.1:3210 npm run dev",
    "dev:cloud": "cross-env NEXT_PUBLIC_CONVEX_URL=https://your-deployment-name.convex.cloud npm run dev",
    "convex:local": "npx convex dev --local",
    "convex:cloud": "cross-env CONVEX_DEPLOYMENT=dev:your-deployment-name npx convex dev",
    "convex:clear": "npx convex data clear"
  }
}
```

**Important:** Replace `your-deployment-name` with the actual Convex deployment name (e.g. `harmless-pelican-402`).

The `predev:local` script automatically checks that the local Convex backend is running before starting the Next.js dev server.

## Step 4: Next.js Config — WebSocket Proxy

In `next.config.ts`, add a rewrite rule so the browser can reach the local Convex server through the Next.js dev server. This is essential for WebSocket connections when accessing the app via proxies, tunnels, or custom domains.

```typescript
import type { NextConfig } from "next";

const isLocal = process.env.NEXT_PUBLIC_CONVEX_URL?.includes("127.0.0.1");

const nextConfig: NextConfig = {
  async rewrites() {
    if (!isLocal) return [];
    return [
      {
        source: "/convex/:path*",
        destination: "http://127.0.0.1:3210/:path*",
      },
    ];
  },
};

export default nextConfig;
```

## Step 5: Providers

Create a providers component that wraps the app with both Clerk and Convex. When running locally, the Convex client URL is constructed from `window.location.origin` so it goes through the Next.js proxy (Step 4), making it work across any origin (localhost, tunnels, custom domains).

```typescript
// app/providers.tsx
"use client";

import { ClerkProvider } from "@clerk/nextjs";
import { ConvexProvider, ConvexReactClient } from "convex/react";
import { ReactNode } from "react";

const isLocal = process.env.NEXT_PUBLIC_CONVEX_URL?.includes("127.0.0.1");

const convexUrl =
  typeof window !== "undefined" && isLocal
    ? `${window.location.origin}/convex`
    : process.env.NEXT_PUBLIC_CONVEX_URL!;

const convex = new ConvexReactClient(convexUrl);

export function Providers({ children }: { children: ReactNode }) {
  return (
    <ClerkProvider>
      <ConvexProvider client={convex}>
        {children}
      </ConvexProvider>
    </ClerkProvider>
  );
}
```

Wrap your root layout with `<Providers>`:

```typescript
// app/layout.tsx
import { Providers } from "./providers";

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}
```

## Step 6: Convex Schema and Auth

Initialize Convex if not already done:

```bash
npx convex init
```

Set up Clerk as the auth provider for Convex by following the Convex docs for Clerk integration. This typically involves:

1. Creating `convex/auth.config.ts` with your Clerk issuer URL
2. Configuring environment variables in the Convex dashboard

## Running the App

**Local development (two terminals):**

```bash
# Terminal 1 — Convex backend
npm run convex:local

# Terminal 2 — Next.js (wait for "Convex functions ready!" first)
npm run dev:local
```

**Cloud development (two terminals):**

```bash
# Terminal 1 — Convex dev sync
npm run convex:cloud

# Terminal 2 — Next.js
npm run dev:cloud
```

## Switching Modes

Toggle between local and cloud by editing `.env.local`:

**Local:**
```bash
CONVEX_DEPLOYMENT=local:local-yourname-yourapp-1
NEXT_PUBLIC_CONVEX_URL=http://127.0.0.1:3210
```

**Cloud:**
```bash
CONVEX_DEPLOYMENT=dev:your-deployment-name
NEXT_PUBLIC_CONVEX_URL=https://your-deployment-name.convex.cloud
```

Restart both terminals after switching.
