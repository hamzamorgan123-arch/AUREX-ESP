# AUREX-ESP Website

Black-and-gold esports organization website with Supabase email/password auth, editable player profiles, public events/news/social links, and an email-allowlisted admin dashboard.

## Files
- `index.html` — page structure and dialogs
- `styles.css` — responsive black/gold theme
- `app.js` — Supabase client, auth, profiles, content and dashboard
- `supabase-schema.sql` — database tables, trigger and Row Level Security policies

## Setup

### 1. Create a Supabase project
1. Visit https://supabase.com/dashboard and create a project.
2. Open **Project Settings → API** (or **Data API / API Keys**, depending on the dashboard version).
3. Copy the Project URL and the **publishable** key (or legacy `anon` public key). Never use `service_role` or a secret key in website code.

### 2. Configure the website
1. Open `app.js`.
2. Replace `YOUR_SUPABASE_URL` with the Project URL.
3. Replace `YOUR_SUPABASE_ANON_KEY` with the publishable/anon key.
4. Save the file.

### 3. Create the database and admin allowlist
1. In Supabase, open **SQL Editor → New query**.
2. Open `supabase-schema.sql` in this folder and copy all its contents into the SQL Editor.
3. Replace `YOUR_ADMIN_EMAIL@example.com` in the SQL script with the exact email address you will use to administer the website. You can also remove that INSERT and run this separately after the schema:
   ```sql
   insert into public.admin_emails(email) values (lower('you@example.com')) on conflict do nothing;
   ```
4. Click **Run**. Add more admin emails only from SQL Editor, never from the public website.

### 4. Configure authentication URLs
In Supabase, open **Authentication → URL Configuration**:
- Site URL: `https://hamzamorgan123-arch.github.io/aurex-esports/`
- Add this exact URL to **Redirect URLs** as well.

For first testing, you can turn email confirmation off under **Authentication → Providers → Email**. For a public launch, keep email confirmation enabled and configure SMTP/custom email delivery if needed.

### 5. Upload to your existing GitHub repository
1. Open https://github.com/hamzamorgan123-arch/aurex-esports
2. Upload/replace these four files at the repository root: `index.html`, `styles.css`, `app.js`, `supabase-schema.sql`, plus this README.
3. Commit the changes to the `main` branch.
4. Open **Settings → Pages** and ensure deployment source is **Deploy from a branch**, branch `main`, folder `/ (root)`.
5. Wait for GitHub Pages to publish, then open https://hamzamorgan123-arch.github.io/aurex-esports/.

## Security notes
- The frontend contains only the Supabase publishable/anon key. That key is designed to be public; Row Level Security is what protects the data.
- Never put a Supabase `service_role` key or secret key in `app.js`, GitHub, or any browser code.
- Admin permissions are checked by the database function `public.is_admin()` against the private `admin_emails` table. Hiding the dashboard button is only a UI convenience; database RLS is the actual security boundary.
- Members can read public profiles and edit only their own. Admin emails are not readable from the browser.
- Public registration is enabled by Supabase Auth. Users may need to confirm their email before signing in if email confirmation is enabled.

## Notes / current scope
- Player avatars are stored as image URLs (no file upload bucket is configured yet).
- The teams section is currently a designed starter section; the admin dashboard manages events, news, social links and member profile visibility, not team rosters yet.
- No payment/shop features are included.
