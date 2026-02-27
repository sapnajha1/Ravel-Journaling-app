# Journal — Project Summary

**Last updated:** 2026-02-27
**Branch:** AI-design-session
**Status:** Active development — core journaling loop complete, AI analysis shipped

---

## What This App Is

Journal is a multi-modal journaling app for iOS and Android. The core thesis: different moods call for different ways of getting thoughts out. Some days you want to sit with a question. Some days you need to vent. Some days words aren't it at all.

Three modes handle this:

- **Reflect** — A daily question you answer in text or voice. Thoughtful, structured.
- **Rant** — Continuous voice recording. No editing, no judgment. Speak first, make sense later.
- **Scribble** — Freehand canvas drawing. When words fail entirely.

After a session, Gemini reads what you wrote (or said) and returns a short analysis: a title, mood labels, an insight, topic tags. This is optional — users can turn it off.

The design philosophy is offline-first. Entries go to Hive locally before Supabase. The app works without internet; sync happens when it can.

---

## Three Journaling Modes

### Reflect — Guided Text/Voice Journaling

The user sees a daily question fetched from Supabase. They can type a response or speak it (via Deepgram STT). If they speak, the raw transcript goes through a Gemini Edge Function that adds punctuation and fixes capitalization before it appears in the text field.

**Why a daily question?** Blank pages are hard. A specific prompt removes the activation energy of "what do I even write about." Questions rotate from a curated Supabase table (`reflection_prompts`, filtered by `is_active`).

**Go Deeper** — The big recent feature. After answering, the user can tap "Go Deeper" instead of finishing. This calls a `generate-followup` Edge Function that reads the entry so far and returns a single follow-up question. The user answers that too. They can keep going — each turn locks the previous response and adds a new AI question. All turns accumulate into a single entry. This creates a lightweight journaling conversation without requiring the user to know what questions to ask themselves.

The design decision here was to treat the entire session as one entry, not multiple. The accumulated content (all turns) is what gets sent to analysis at the end, and what gets stored. Splitting into separate entries felt artificial — it's one session of thought.

**Analysis preference check** — Users can set whether analysis always runs, whether to ask each time, or to never run. This is checked at the point of tapping "Done." If "ask," a confirmation step is shown. This preference is stored in Hive locally (not synced to profile), reinforcing the offline-first approach.

---

### Rant — Continuous Voice Recording

Tap the mic. Talk. Tap stop. That's it.

Gemini cleans up the transcript. Entry saves. Analysis option appears.

The UX here is deliberately minimal. The rant screen is mostly a large waveform visualization (animated red/orange bars) and a live transcription field below. No formatting options, no prompts, no structure. The point is immediacy and lack of friction.

**Why this exists separately from Reflect:** The recording-first, no-prompt approach is functionally and psychologically different from sitting with a question. Some people journal best when they're wound up about something — they need to release before they can reflect. Rant serves that need.

The transcript cleanup via `punctuate-transcript` Edge Function is important here because raw STT output is rough. Run-on sentences, no commas, weird capitalizations. Gemini at temperature 0.2 fixes this while preserving the user's actual words.

---

### Scribble — Freehand Canvas

A full-screen drawing canvas with pen tools (4 colors), eraser, brush size, eraser size, undo/redo, and a clear button.

**Why?** Journaling isn't always verbal. This is for the mind maps, the venting-via-doodle, the thing you can't describe in words but can draw. It's also the lowest-friction mode — no AI, no recording setup.

**Storage decision:** Scribble entries are saved as base64-encoded PNG strings directly in the database. No separate file storage (no S3, no Supabase Storage). This simplifies the architecture considerably. The trade-off is entry size — a dense scribble will be larger than a text entry. For a personal journaling app, this is an acceptable trade-off.

**Library:** `flutter_painter_v2` handles the canvas (not the older `flutter_painter` — a build fix was needed when this was initially set up).

---

## AI Pipeline

```
Voice input  →  STT (Deepgram / manual_speech_to_text)
             →  punctuate-transcript Edge Function (Gemini, temperature 0.2)
             →  Cleaned transcript synced to text field

Entry text   →  analyze-entry Edge Function (Gemini, temperature 0.4)
             →  { title, moods[], insight, topics }
             →  Hive + Supabase updated with AI fields
             →  EntryAnalysisScreen rendered
```

### Edge Functions

Three TypeScript functions deployed to Supabase:

**`punctuate-transcript`** — Cleans raw STT output. English and Hinglish supported. Takes `{transcript}`, returns cleaned text. Falls back to raw transcript on error so users always get something.

**`analyze-entry`** — Full entry analysis. Takes `{content, entryType}`. Returns:

- `title` — ≤10 words, captures the entry's main theme
- `moods` — 1–3 labels, constrained to the Yale Mood Meter list (65 moods across 4 quadrants: high/low energy × pleasant/unpleasant)
- `insight` — 2–4 sentences, second person ("You..."), empathetic not prescriptive
- `topics` — 2–5 short tags

**Why Yale Mood Meter?** Constraining Gemini to a predefined mood vocabulary prevents hallucinated or overly clinical labels. The Yale list is validated psychologically and covers a meaningful range without being overwhelming. The 65 moods are loaded from `assets/yale_mood_meter.csv` at function time (the CSV is included in the Edge Function bundle). Gemini is explicitly told to only pick from this list.

**`generate-followup`** — Called for Go Deeper. Takes `{content}` (accumulated reflection text), returns one sentence acknowledging what was written and one open-ended follow-up question. Temperature 0.7 — slightly more creative than the other functions, because good follow-up questions sometimes require unexpected angles. Falls back to "What else is on your mind?" if the API fails.

**No Gemini Flutter SDK** — All AI is accessed via HTTP to Supabase Edge Functions, not directly from the client. This keeps the API key off-device, keeps concerns separated (Flutter handles UI/data, Edge Functions handle AI), and lets us update prompts without shipping an app update.

---

## Auth & Onboarding

**Auth flow:** Passwordless email (magic link) via Supabase Auth.

1. User enters email → "Send magic link" button
2. Supabase sends email with link
3. User taps link → app receives deep link (`journalapp://auth/callback`)
4. GoRouter detects deep link, calls `detectSessionInUri` to complete auth
5. First-time users → Ask Name screen (set display name, required before home)
6. Returning users → directly to home

The Ask Name screen exists because Supabase auth gives us an email but no display name. We want to greet the user by name on the home screen and in prompts. It's a one-time step after first login.

**Onboarding:** Three screens for new users explaining what the app is (Welcome → Actions → Privacy). The `onboarded` flag is stored in SharedPreferences — once set, never shown again. Users can skip directly to login from any onboarding screen.

**GoRouter guards:** The `redirect` function in `appRouterProvider` checks state in order: onboarding → auth → display name → home. This means the correct screen always loads regardless of which deep link or state the app starts in.

---

## History & Profile

### History Screen

All entries, grouped by date (Today, Yesterday, Last Week, Older). Each card shows:

- Entry type badge (reflect/rant/scribble) with mode color
- Title (from AI analysis, or first line of content if no analysis ran)
- Mood chips (if analysis ran)
- Timestamp and truncated preview

Tapping a card opens a detail screen with full content, moods, insight, and topics. From the detail screen, users can edit the entry content and re-save. Edit updates both Hive and Supabase.

**HistoryViewModel** uses `ChangeNotifier` (legacy state management) and refreshes the list on return from detail view, so edits are immediately visible.

### Profile Screen

- Display name (editable inline with pencil icon)
- Email (read-only)
- Analysis preference toggle: Always / Ask each time / Never
- Sign out button

**Analysis preference** is stored in Hive's `app_settings` box — not in the Supabase user profile. This is intentional. The preference is device-local and doesn't need to sync. If the user gets a new phone, the preference defaults to "Always" — which is the right default.

---

## Architecture Decisions

### Offline-first with Hive

Every entry is written to Hive before Supabase. On save:

1. Entry inserted into local Hive box immediately
2. Async call to Supabase (non-blocking)
3. On success: entry marked `isSynced: true`
4. On failure: entry stays in Hive, available locally

History fetches from Supabase when online; falls back to Hive. Local-first means the app works on a plane.

### Riverpod (new) + Provider (legacy) coexistence

New screens (Reflect, Scribble, auth/onboarding) use Riverpod `StateNotifier` providers. Older screens (History, Home, Rant) use `ChangeNotifier` with `Provider`. These coexist without conflict.

This was a pragmatic decision — rewriting working screens in Riverpod just to standardize would have introduced bugs and cost time. The migration is ongoing, not forced.

### GoRouter for auth guards

Centralized route protection in `appRouterProvider`. The `redirect` function runs on every navigation event and sends users to the right screen based on auth + onboarding state. This replaces ad-hoc `if (!loggedIn) Navigator.push(login)` logic scattered through screens.

### Yale Mood Meter as AI constraint

Without a constrained vocabulary, Gemini tends to use clinical or overly specific mood labels that aren't meaningful to users ("ambivalent," "dysthymic," "circumspect"). The Yale Mood Meter gives a rich, validated set of everyday mood words. Constraining the AI to this list produces more relatable, consistent output.

### Base64 PNG for Scribble

No file storage bucket needed. Scribble content is stored as a base64 string directly in the `journal_entries` table. This adds ~50–200KB per entry depending on drawing density. For a personal app, this is acceptable and dramatically simplifies the architecture.

### Analysis runs async, UI doesn't block

The loading screen (`EntryAnalysisLoadingScreen`) is shown while the Gemini call is in-flight. If the user skips or backs out, the entry is still saved without AI fields. The analysis screen only shows if the call succeeds — on error, user returns to home with a saved (unanalyzed) entry. This ensures a network error never loses the user's work.

---

## Design System

### Typography

- **SyneMono** — All UI text (labels, buttons, body). Monospace, modern, consistent character widths.
- **GochiHand** — Handwritten style for headings and entry content. Makes the text feel personal and un-corporate.

### Colors

| Name                 | Hex       | Usage                                             |
| -------------------- | --------- | ------------------------------------------------- |
| primaryBase (Coral)  | `#FF7B6B` | Main CTA buttons, nav pill active state           |
| purpleBase           | `#9B7FD9` | Reflect mode accent, topic chips, analysis screen |
| releaseBase (Orange) | `#FFA64D` | Rant mode accent, topic chips                     |
| expressBase (Green)  | `#48D99A` | Scribble mode, success states                     |
| backgroundBase       | `#FFF9F3` | All screen backgrounds (warm off-white)           |
| textPrimary          | `#201B18` | Primary text (warm dark, not pure black)          |

### UI Aesthetic — Neo-Brutalist

- **Hard shadows:** (2, 2) offset, 0 blur on cards and buttons. Nothing floats softly — everything has weight.
- **Black borders:** 2px on primary buttons, 1.5px on cards. Clean, direct.
- **Rounded but geometric:** 8px radius on cards, 6px on buttons. Rounded enough to feel approachable, angular enough to feel intentional.

### Layout Patterns

- **Dotted background:** Semi-transparent coral dots on the warm background, on every screen. Creates visual continuity across modes.
- **Cards:** White fill, black border, 8px radius, 16px padding. Used for analysis insight, entry detail, profile settings.
- **Mood/topic chips:** Pill shape (20px radius), small padding, mode-specific border colors.
- **Bottom nav:** 58px tab bar with a soft active pill indicator, not a sharp underline.

### Documented Inconsistencies (to clean up)

These are tracked in [design-system.md](./design-system.md):

- Border color: some use `Colors.black`, others `AppColors.textPrimary` (should be unified)
- Typography sizes 13px, 15px, 20px are off the defined scale
- Button radius: token specifies 4px, all buttons use 6px — token should be updated
- One dialog uses coral border instead of dark border
- 4 new color tokens needed for badge backgrounds (not yet added to `AppColors`)

---

## What's Built (as of 2026-02-27)

### Complete

- Three journaling modes (Reflect, Rant, Scribble) — end-to-end
- Speech-to-text → Gemini punctuation cleanup pipeline
- AI analysis screen (title, moods, insight, topics)
- Go Deeper iterative reflection flow
- Analysis preference toggle (always/ask/never)
- Auth (magic link), onboarding (3 screens), display name setup
- History with date grouping, entry detail, entry editing
- Profile screen with settings
- Offline-first architecture (Hive + Supabase sync)
- GoRouter with auth/onboarding guards
- Design system with documented color, typography, and layout tokens

### Known Gaps / Ongoing

- Design token inconsistencies documented in `design-system.md` — cleanup pass needed
- Scribble has no AI analysis (intentional for now — unclear what AI would say about a drawing)
- Riverpod migration incomplete — History and Rant still use Provider/ChangeNotifier
- No push notifications (daily reminder to journal)
- No search/filter in History

---

## File Map

| Area                   | Path                                             |
| ---------------------- | ------------------------------------------------ |
| Core models            | `lib/data/models/`                               |
| Repositories           | `lib/data/repositories/`                         |
| Reflect controller     | `lib/features/reflect/reflect_controller.dart`   |
| Scribble controller    | `lib/features/scribble/scribble_controller.dart` |
| History viewmodel      | `lib/viewmodels/history_view_model.dart`         |
| Rant viewmodel         | `lib/viewmodels/rant_view_model.dart`            |
| Entry analysis service | `lib/services/entry_analysis_service.dart`       |
| Reflect screen         | `lib/screens/reflect_screen.dart`                |
| Rant screen            | `lib/views/rantView/rant_recording_screen.dart`  |
| Scribble screen        | `lib/screens/scribble_screen.dart`               |
| History screen         | `lib/screens/history_screen.dart`                |
| Profile screen         | `lib/screens/profile_screen.dart`                |
| Analysis loading       | `lib/screens/entry_analysis_loading_screen.dart` |
| Analysis screen        | `lib/screens/entry_analysis_screen.dart`         |
| Router                 | `lib/presentation/app_router.dart`               |
| Design system          | `lib/design_system/`                             |
| Edge Functions         | `supabase/functions/`                            |
| Design system doc      | `docs/design-system.md`                          |
| AI toggle doc          | `docs/ai-analysis-toggle.md`                     |
