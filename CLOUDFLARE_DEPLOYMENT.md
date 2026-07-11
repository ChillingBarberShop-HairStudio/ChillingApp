# Deploy ChillingApp on Cloudflare

## 1. Deploy the management web app with Cloudflare Pages

In Cloudflare Dashboard, create a Pages project from the GitHub repository:

```txt
ChillingBarberShop-HairStudio/ChillingApp
```

Use these build settings:

```txt
Framework preset: Vite
Build command: npm run build
Build output directory: dist
Node.js version: 20
```

Add these Pages environment variables for both Preview and Production:

```txt
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key
VITE_LANDING_URL=https://chillingbarbershop-hairstudio.github.io/Chilling/
VITE_DEPLOY_WEBHOOK_URL=https://your-worker.workers.dev/deploy-landing
```

`VITE_*` values are visible to the browser by design. Never add a Service Role Key, GitHub token, bank credentials, or Cloudflare API token to Pages variables beginning with `VITE_`.

## 2. Deploy the protected Worker

From `workers/`:

```powershell
npx wrangler login
npx wrangler secret put SUPABASE_URL
npx wrangler secret put SUPABASE_ANON_KEY
npx wrangler secret put GITHUB_TOKEN
npx wrangler secret put GITHUB_OWNER
npx wrangler secret put GITHUB_REPO
npx wrangler secret put ALLOWED_ORIGIN
npx wrangler deploy
```

Set `ALLOWED_ORIGIN` to the exact Cloudflare Pages URL or custom admin domain, for example:

```txt
https://admin.chillingbarber.vn
```

The GitHub token must be fine-grained, newly generated, and limited to the `Chilling` repository with permission to dispatch a repository event. It is held only by the Worker. The Worker verifies the caller's Supabase session and `owner`/`manager` role without storing a Supabase Service Role Key.

## 3. Land the database safely

Run `supabase/migrations/202607100001_initial_system.sql` from this repository in a clean/staging Supabase project first. Create the first Auth user, then make that user an active `owner` through the SQL Editor as documented in `README.md`.

After deploying the Worker, copy its `/deploy-landing` URL into `VITE_DEPLOY_WEBHOOK_URL` in Cloudflare Pages.

## 4. Configure the landing deployment

In the `Chilling` GitHub repository, configure Actions secrets:

```txt
VITE_SUPABASE_URL
VITE_SUPABASE_ANON_KEY
```

The landing workflow already accepts the protected `landing_content_changed` event emitted by the Worker. Do not put Supabase Service Role or a GitHub token in the landing repository or Pages build variables.
