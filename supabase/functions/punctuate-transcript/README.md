# punctuate-transcript Edge Function

Adds punctuation and capitalization to raw speech-to-text (English/Hinglish) using Google Gemini.

## Fix for "models/gemini-1.5-flash is not found"

The error happens because `gemini-1.5-flash` is not available for the v1beta API. This function uses **`gemini-2.5-flash`** (or you can switch to `gemini-2.0-flash` if needed).

If you already have this function in Supabase and only want to fix the 404:

1. Open **Supabase Dashboard** → **Edge Functions** → **punctuate-transcript**.
2. Find where the Gemini model is set (e.g. `gemini-1.5-flash`).
3. Change it to **`gemini-2.5-flash`** or **`gemini-2.0-flash`**.
4. Save and redeploy.

## Deploy from this repo

1. Install [Supabase CLI](https://supabase.com/docs/guides/cli) and link the project:
   ```bash
   supabase link --project-ref ipptzbihuzbgriixerld
   ```
2. Set the Gemini API key (from [Google AI Studio](https://aistudio.google.com/apikey)):
   ```bash
   supabase secrets set GEMINI_API_KEY=your_api_key
   ```
3. Deploy:
   ```bash
   supabase functions deploy punctuate-transcript
   ```
   If the app gets **401 Unauthorized** when calling this function (common with Supabase’s ES256 JWT signing), redeploy with:
   ```bash
   supabase functions deploy punctuate-transcript --no-verify-jwt
   ```

## Request / response

- **Request:** `POST` with JSON `{ "transcript": "raw text here" }`.
- **Response:** `{ "text": "Punctuated and cleaned text." }`.
