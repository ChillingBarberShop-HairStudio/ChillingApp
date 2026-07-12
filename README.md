# Chilling Management System

Vue 3 admin application for Chilling Barber Shop. It is intentionally separate from the public landing page so customer-facing and staff-only permissions do not share a frontend deployment.

## Start locally

```powershell
cd C:\Users\Vinh\Desktop\Chilling\chilling-management-system
Copy-Item .env.example .env
npm install
npm run dev
```

Run the SQL migration first:

```txt
supabase/migrations/202607100001_initial_system.sql
```

After creating the first Supabase Auth user, promote it only through the SQL Editor:

```sql
update public.profiles
set role = 'owner', is_active = true
where email = 'owner@your-domain.example';
```

## Security boundaries

- Browser apps only use `VITE_SUPABASE_ANON_KEY`.
- The Cloudflare Worker authorizes the caller with their Supabase session; it does not need a Supabase service-role key.
- A GitHub dispatch token, when used, belongs only in a Cloudflare Worker secret and must never be committed or placed in `VITE_*`.
- Landing bookings call `create_public_booking(jsonb)`; anonymous users receive no direct table permissions.
- The 90-day cleanup applies to operational logs only, not invoices, payments, bookings, or tax records.

## Operations

Read [OPERATIONS_GUIDE.md](OPERATIONS_GUIDE.md) for the online/offline checkout flow, stock handling, commission reconciliation, PDF invoices and secure landing content updates.

## Cloudflare Worker

The worker in `workers/` verifies the logged-in Supabase user and role, then sends a GitHub `repository_dispatch` event. Configure production values with `wrangler secret put`; do not commit `.dev.vars`.
