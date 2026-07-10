# Supabase and Cloudflare Setup

1. Create a new Supabase project (recommended) and enable Email/Password authentication. If the current project already has `bookings`, `booking_services`, or `services`, export/back up those tables and test this migration in a staging project first; the operational schema deliberately replaces the old direct-client booking model.
2. Run `supabase/migrations/202607100001_initial_system.sql` in the SQL Editor.
3. Create the first Auth user, then set that account to `owner` and `is_active = true` using the command in the project README.
4. In Supabase Dashboard, enable the `pg_cron` extension. Re-run the last scheduling block of the migration if it was executed before the extension was enabled.
5. Create `chilling-management-system/.env` from `.env.example` and add only the project URL plus Anon Key.
6. Add `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` as GitHub Actions repository secrets for the landing repository.
7. Deploy `workers/` to Cloudflare. Configure `SUPABASE_SERVICE_ROLE_KEY` and `GITHUB_TOKEN` using `wrangler secret put`; never put either value in an `.env` file used by Vite.

The worker's GitHub token requires only permission to dispatch the deployment event for the landing repository. Configure an allowlist/CORS origin before production if the management system has a fixed domain.

Tax configuration stores business identity and audited assumptions. It does not auto-file tax or make a legally binding tax calculation; review the applicable taxpayer model and current official guidance with a qualified tax professional before use.
