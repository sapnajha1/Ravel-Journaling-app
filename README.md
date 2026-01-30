# journal_app

A Flutter journal app with Supabase magic link (OTP) authentication.

## Authentication (Supabase Magic Link)

1. **Create a Supabase project** at [supabase.com](https://supabase.com) and get your project URL and anon key (Project Settings → API).

2. **Configure the app** in `lib/config/supabase_config.dart`:
   - Replace `SUPABASE_URL` default with your project URL.
   - Replace `SUPABASE_ANON_KEY` default with your anon key.

3. **Add redirect URL in Supabase Dashboard** (Authentication → URL Configuration → Redirect URLs):
   - Add: `journalapp://auth/callback`
   - This lets the magic link open the app instead of the browser.

4. **Magic link flow**: User enters email → taps "Send Magic Link" → receives email → taps link → app opens and signs in. Session is persisted locally and survives app restarts.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
