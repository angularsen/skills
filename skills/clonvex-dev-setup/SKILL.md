---
name: clonvex-dev-setup
description: Bootstrap a Clerk + Convex project with local and cloud dev modes, npm scripts, and environment files. Use this skill when setting up a new app with Convex backend and Clerk authentication, or when adding local/cloud dev mode switching to an existing Clerk + Convex project. Framework-agnostic — works with Next.js, Vite, Remix, etc.
metadata:
  author: angularsen
  version: "1.1.0"
license: MIT
---

# Clerk + Convex Dev Setup

Bootstrap a project with Clerk authentication and Convex backend, configured for both local and cloud development. Framework-agnostic — adapt the examples to whichever framework the project uses.

## What This Sets Up

- `npm run dev:local` — dev server pointing at local Convex (`http://127.0.0.1:3210`)
- `npm run dev:cloud` — dev server pointing at cloud Convex deployment
- `npm run convex:local` — starts the local Convex backend
- `npm run convex:cloud` — runs `convex dev` against cloud deployment
- `npm run convex:clear` — clears local Convex data
- Clerk authentication provider
- Convex real-time backend provider
- Environment files for local and cloud modes

## Prerequisites

- Node.js 18, 20, 22, or 24 (Convex does not support 25+)
- A Clerk account and app at https://dashboard.clerk.com
- A Convex account at https://convex.dev

## Step 1: Install Dependencies

```bash
npm install convex @clerk/nextjs    # or the Clerk SDK for your framework
npm install -D cross-env
```

Use the appropriate Clerk package for your framework (e.g. `@clerk/nextjs`, `@clerk/clerk-react`, `@clerk/remix`, etc.).

## Step 2: Environment Files

Create `.env.local` (or `.env` depending on framework conventions). Replace placeholder values with your actual keys.

```bash
# Clerk Authentication (https://dashboard.clerk.com)
# Env var names may differ by framework — use your Clerk SDK's conventions
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

Create `.env.local.example` (same content with placeholder values) and ensure `.env.local` is in `.gitignore`.

**Note:** The `NEXT_PUBLIC_` prefix is a Next.js convention. For Vite use `VITE_`, for Remix check your setup. Adjust the env var names to match your framework.

## Step 3: NPM Scripts

Add these scripts to `package.json`. Replace `your-deployment-name` with the actual Convex deployment name and adjust the `dev` script to your framework's dev command.

```json
{
  "scripts": {
    "predev:local": "node -e \"const http=require('http');const r=http.get('http://127.0.0.1:3210',()=>process.exit(0));r.on('error',()=>{console.error('\\x1b[31mLocal Convex not running! Start with: npm run convex:local\\x1b[0m');process.exit(1)});r.setTimeout(1000,()=>{r.destroy();console.error('\\x1b[31mLocal Convex not running! Start with: npm run convex:local\\x1b[0m');process.exit(1)})\"",
    "dev": "<framework dev command here, e.g. next dev, vite dev, remix dev>",
    "dev:local": "cross-env NEXT_PUBLIC_CONVEX_URL=http://127.0.0.1:3210 npm run dev",
    "dev:cloud": "cross-env NEXT_PUBLIC_CONVEX_URL=https://your-deployment-name.convex.cloud npm run dev",
    "convex:local": "npx convex dev --local",
    "convex:cloud": "cross-env CONVEX_DEPLOYMENT=dev:your-deployment-name npx convex dev",
    "convex:clear": "npx convex data clear"
  }
}
```

The `predev:local` script checks that local Convex is running before starting the dev server.

**Note:** Adjust the env var name in `dev:local` and `dev:cloud` to match your framework's convention (e.g. `VITE_CONVEX_URL` for Vite).

## Step 4: Dev Server Proxy (for WebSocket support)

When accessing the app through a proxy, tunnel, or custom domain (not plain `localhost`), the browser needs to reach the local Convex server through the dev server. Set up a proxy rule from `/convex/*` to `http://127.0.0.1:3210/*`, only in local mode.

**Next.js** — in `next.config.ts`:
```typescript
const isLocal = process.env.NEXT_PUBLIC_CONVEX_URL?.includes("127.0.0.1");

const nextConfig = {
  async rewrites() {
    if (!isLocal) return [];
    return [{ source: "/convex/:path*", destination: "http://127.0.0.1:3210/:path*" }];
  },
};
export default nextConfig;
```

**Vite** — in `vite.config.ts`:
```typescript
export default defineConfig({
  server: {
    proxy: {
      "/convex": { target: "http://127.0.0.1:3210", changeOrigin: true, rewrite: (path) => path.replace(/^\/convex/, ""), ws: true },
    },
  },
});
```

Adapt to your framework's proxy mechanism.

## Step 5: Convex Client Provider

Create a providers component that wraps the app with both Clerk and Convex. When running locally, construct the Convex client URL from `window.location.origin` so it goes through the dev server proxy (Step 4), making it work across any origin.

```typescript
import { ConvexReactClient } from "convex/react";

// Adjust env var name to match your framework (NEXT_PUBLIC_, VITE_, etc.)
const isLocal = import.meta.env.VITE_CONVEX_URL?.includes("127.0.0.1")
  ?? process.env.NEXT_PUBLIC_CONVEX_URL?.includes("127.0.0.1");

const convexUrl =
  typeof window !== "undefined" && isLocal
    ? `${window.location.origin}/convex`
    : (import.meta.env.VITE_CONVEX_URL ?? process.env.NEXT_PUBLIC_CONVEX_URL);

const convex = new ConvexReactClient(convexUrl);
```

Wrap this in your framework's provider pattern alongside the Clerk provider, then mount both at the root of your app.

## Step 6: Convex Init and Auth

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
# Terminal 1 — start Convex backend
npm run convex:local

# Terminal 2 — start dev server (wait for "Convex functions ready!" first)
npm run dev:local
```

**Cloud development (two terminals):**

```bash
# Terminal 1 — start Convex dev sync
npm run convex:cloud

# Terminal 2 — start dev server
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
