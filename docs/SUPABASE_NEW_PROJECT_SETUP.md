# Supabase new project setup checklist

When you create a **new** Supabase project and point the app to it (new URL + anon key), you must recreate tables, RLS policies, and the Edge Function. Same table names are not enough—the new project starts with an empty database.

---

## 1. Tables

### `journal_entries`

Create in **Table Editor** (or SQL):

| Column       | Type        | Nullable | Default / Notes        |
|-------------|-------------|----------|-------------------------|
| id          | uuid        | NO       | `gen_random_uuid()`    |
| user_id     | uuid        | NO       | references auth.users  |
| entry_type  | text        | NO       | e.g. 'rant', 'reflection', 'scribble' |
| prompt_id   | text        | YES      |                        |
| title       | text        | YES      |                        |
| content     | text        | NO       |                        |
| entry_date  | date        | NO       |                        |
| created_at  | timestamptz | NO       | `now()`                |

- Primary key: `id`.
- Optional: foreign key `user_id` → `auth.users(id)`.

### `reflection_prompts`

| Column      | Type    | Nullable | Default / Notes     |
|------------|---------|----------|---------------------|
| id         | text    | NO       | primary key         |
| text       | text    | NO       | (or `prompt_text`)  |
| category   | text    | YES      | e.g. 'reflection'   |
| is_active  | boolean | NO       | `true`              |

- The app reads `id`, `text` (or `prompt_text` / `prompt` / `content`), `category`, and filters with `is_active = true`.
- Insert at least one row so prompts are visible (e.g. "What's something that brought a smile to your face today?").

---

## 2. Row Level Security (RLS)

Supabase enables RLS by default. If policies are missing, **SELECT/INSERT/UPDATE/DELETE will fail** even with a valid anon key and login.

### `journal_entries`

- **SELECT**: allow authenticated users to read their own rows  
  `auth.uid() = user_id`
- **INSERT**: allow authenticated users to insert with their own `user_id`  
  `auth.uid() = user_id`
- **UPDATE**: allow authenticated users to update their own rows  
  `auth.uid() = user_id`
- **DELETE**: allow authenticated users to delete their own rows  
  `auth.uid() = user_id`

### `reflection_prompts`

- **SELECT**: allow all (anon + authenticated) so the app can load prompts without a specific user.  
  e.g. `true` or `is_active = true`.

No INSERT/UPDATE/DELETE needed for prompts if only you manage them in the dashboard.

---

## 3. Edge Function (Gemini – punctuate transcript)

- **Deploy** the function to the **new** project:
  ```bash
  supabase link --project-ref YOUR_NEW_PROJECT_REF
  supabase functions deploy punctuate-transcript
  ```
- Set the secret for that project:
  ```bash
  supabase secrets set GEMINI_API_KEY=your_gemini_api_key
  ```
- In the app, the anon key must be the one from this new project (already fixed if login works).

---

## 4. App config

- `lib/config/supabase_config.dart` (or env) must use:
  - **URL**: `https://YOUR_NEW_PROJECT_REF.supabase.co`
  - **Anon key**: from **Project Settings → API → anon public** for this project.

Login working means URL and anon key are correct. Remaining issues are almost always:

1. **Tables missing or wrong columns** in the new project.
2. **RLS** blocking SELECT/INSERT on `journal_entries` or SELECT on `reflection_prompts`.
3. **Empty `reflection_prompts`** (no rows with `is_active = true`).
4. **Edge Function** not deployed or `GEMINI_API_KEY` not set on the new project.

---

## 5. Debugging

After the latest app changes, run the app and watch the **debug console** when you:

- Save a rant/reflection/scribble: look for `[JournalRepository] Sync failed: ...`.
- Open History or load prompts: look for `[JournalRepository] Fetch remote failed: ...` or `[PromptRepository] Fetch reflection_prompts failed: ...`.

Those messages will show the real Supabase error (e.g. "relation journal_entries does not exist", "new row violates row-level security policy", or "permission denied for table journal_entries").

Use that error text to fix either table creation or RLS in the new project.
