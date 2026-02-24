-- Create user_encryption_keys table for client-side journal encryption.
-- Each user has one row with their 256-bit key (base64-encoded).
-- RLS ensures only the authenticated user can access their own key.

create table if not exists public.user_encryption_keys (
  user_id uuid primary key references auth.users(id) on delete cascade,
  key text not null,
  created_at timestamptz default now()
);

alter table public.user_encryption_keys enable row level security;

create policy "Users can read own key"
  on public.user_encryption_keys for select
  using (auth.uid() = user_id);

create policy "Users can insert own key"
  on public.user_encryption_keys for insert
  with check (auth.uid() = user_id);
