# Journal App — Encryption

This document describes the client-side encryption added to the project for journal content stored in Supabase.

---

## 1. Overview

| Item | Details |
|------|---------|
| **Purpose** | Encrypt journal **content** and **title** before sending to Supabase. Protects against casual access and external breaches. |
| **Scope** | **Remote only** — Supabase `journal_entries` table. Local Hive storage remains plaintext. |
| **Algorithm** | AES-256-GCM (via `cryptography` package). |
| **Key storage** | One 256-bit key per user, stored in Supabase table `user_encryption_keys`. Keys are in Supabase so admins with full DB access can decrypt if needed. |

---

## 2. What Is Encrypted

| Field | Encrypted in Supabase? | Notes |
|-------|------------------------|--------|
| `content` | Yes | Reflection/rant text, or scribble base64 image. |
| `title` | Yes | Only if non-empty. |
| `entry_date`, `entry_type`, `prompt_id`, `user_id`, `moods`, `insight`, `topics`, etc. | No | Stored in plaintext. |

---

## 3. Encryption Format

- **Prefix:** `enc:v1:` — used to tell encrypted values from legacy plaintext.
- **Payload:** Base64 of the AES-GCM concatenation (nonce + ciphertext + MAC).
- **Legacy:** Values without the `enc:v1:` prefix are treated as plaintext and returned as-is on decrypt.

---

## 4. Key Management

| Item | Details |
|------|---------|
| **Table** | `public.user_encryption_keys` |
| **Columns** | `user_id` (UUID, PK, FK to `auth.users`), `key` (text, base64), `created_at` |
| **Per user** | One row per user; key is created on first use. |
| **Cache** | In-memory map in `EncryptionService` (`_keyCache`) to avoid repeated Supabase reads. |
| **Clear on sign out** | Call `EncryptionService.clearCache()` when the user signs out so keys are not kept in memory. |

---

## 5. Files and Roles

| File | Role |
|------|------|
| `lib/services/encryption_service.dart` | Fetches/creates key, encrypt/decrypt with AES-256-GCM, legacy plaintext handling, key cache, `clearCache()`. |
| `lib/data/repositories/journal_repository.dart` | Uses `EncryptionService` in `_insertRemote`, `_updateRemoteEntry`, `_fetchRemoteEntries`, and `_syncEntry`. |
| `supabase/migrations/20250224000000_create_user_encryption_keys.sql` | Creates `user_encryption_keys` and RLS policies (users can only read/insert their own key). |

---

## 6. Where Encryption Is Used in Code

| Location | Operation | Behavior |
|----------|------------|----------|
| `_insertRemote` | Insert new entry | Encrypts `content` and `title` before `journal_entries` insert. |
| `_updateRemoteEntry` | Update existing entry | Encrypts `content` and `title` in the update payload; other fields (e.g. `moods`, `insight`, `topics`) sent in plaintext. |
| `_fetchRemoteEntries` | Load history from Supabase | Decrypts `content` and `title` for each row; legacy rows without `enc:v1:` are left as-is. |
| `_syncEntry` | Sync unsynced entry to Supabase | Encrypts `content` and `title` from `toRemoteInsert()` before insert. |

---

## 7. Dependencies

| Package | Use |
|---------|-----|
| `cryptography: ^2.9.0` | AES-256-GCM (`AesGcm.with256bits()`), `SecretKey`, `SecretBox`. |
| `connectivity_plus` | Used by `JournalRepository` for connectivity; required by the repository constructor after the encryption merge (not used inside `EncryptionService`). |

---

## 8. Supabase Setup

1. **Run migration**
   - Apply `supabase/migrations/20250224000000_create_user_encryption_keys.sql` so the table and RLS exist.

2. **RLS**
   - Users can **select** and **insert** only their own row in `user_encryption_keys` (no update/delete policy; key is create-once).

3. **No extra env vars** for encryption; it uses the same Supabase client and auth.

---

## 9. Local vs Remote

| Storage | Content/Title |
|---------|----------------|
| **Hive (local)** | Stored in **plaintext** (same as before encryption). |
| **Supabase (remote)** | Stored **encrypted** (with `enc:v1:` + base64 blob). |

So data is encrypted in transit and at rest in Supabase; on device it is plaintext in Hive.

---

## 10. Security Notes

- Keys live in Supabase, so anyone with full DB access (e.g. admins) can decrypt.
- Key is 32 bytes (256 bits), base64-encoded in the DB.
- Empty strings are not encrypted; they are returned as-is.
- On sign out, call `EncryptionService.clearCache()` to drop in-memory keys.

---

## 11. Summary Table

| Info | Value |
|------|--------|
| Algorithm | AES-256-GCM |
| Key size | 256 bits (32 bytes), base64 in DB |
| Encrypted fields | `content`, `title` (in Supabase only) |
| Key table | `user_encryption_keys` |
| Format prefix | `enc:v1:` |
| Legacy plaintext | Supported (no prefix → no decrypt) |
| Service | `lib/services/encryption_service.dart` |
| Migration | `supabase/migrations/20250224000000_create_user_encryption_keys.sql` |
