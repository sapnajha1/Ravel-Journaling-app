# Feature: AI Analysis Toggle (Skip Analysis)

**Status:** Proposed — for team review
**Date:** 2026-02-24

---

## The Problem

We were considering putting an "AI analysis on/off" toggle on the Reflect writing screen. But this creates an unintended side effect:

> *Knowing the AI will analyze your words changes what you write — even before you decide whether to skip it.*

The act of choosing becomes a performance. People will self-edit to avoid being "seen" by the AI. This is the opposite of what a journal should do.

---

## Proposed Solution: Toggle Lives After Writing

**Placement:** On the loading screen (the spinner that appears after tapping "End Session"), show a quiet "Skip analysis" option below the spinner.

**Why this timing:**
- The writing screen stays clean — no toggle visible while writing
- The user writes freely, then decides
- Mirrors the philosophy already in Rant mode: *speak first, make sense later*
- The entry is already saved by the time the spinner appears, so nothing is lost either way

**Default:** Analysis runs by default. Skipping is an explicit opt-out in the moment.

**After skipping:** User goes to the Home tab. The entry is saved and visible in History, just without AI-generated moods/insight/topics.

---

## User Flow

```
Write reflection → End Session
  → Entry saved to Hive + Supabase (always happens)
  → Spinner screen appears

  Option A: Do nothing → AI analysis runs → Analysis screen shown
  Option B: Tap "Skip analysis" → Spinner dismisses → User goes to /home
                                    → Entry in History has no AI data (moods/insight/topics = null)
```

---

## What Changes in Code

### 1. `lib/screens/entry_analysis_loading_screen.dart`
- Add an optional `onSkip` callback parameter
- Render a quiet "Skip analysis" text button below the spinner
- Tapping it calls `onSkip`, which dismisses the screen and cancels the AI call

### 2. `lib/screens/reflect_screen.dart` — `_endSession()`
- Pass an `onSkip` callback to `EntryAnalysisLoadingScreen`
- Inside the callback: set a local `_skipAnalysis = true` flag + pop the loading screen
- After the AI call (or skip), check the flag:
  - If skipped → `Navigator.popUntil(root)` → home
  - If not → continue to `EntryAnalysisScreen` as today

### 3. `lib/views/rantView/rant_recording_screen.dart`
- Same pattern — Rant has the same loading → analysis flow

### No model changes needed
`JournalEntry` already supports null `moods`, `insight`, and `topics`. A skipped entry simply leaves those as null — no new database fields required.

---

## What Does NOT Change

- The writing screen UI (Reflect or Rant) — completely unchanged
- The analysis screen itself — unchanged
- How entries are saved — unchanged
- The default behavior — analysis still runs unless the user actively skips

---

## Open Questions for the Team

1. **Copy:** "Skip analysis" is the proposed label. Alternatives: "No thanks", "Just save it", "Skip AI". What tone fits the app?

2. **Persistence:** Should "skip" be a one-time decision each session, or should we eventually add a persistent preference in Settings ("never analyze my reflections")? The current proposal is one-time only — simpler to start.

3. **Rant parity:** The skip option would appear in both Reflect and Rant flows. Does it make sense for Rant too, or is Rant inherently the "raw, unanalyzed" mode where skipping feels redundant?

4. **Empty analysis screen:** Right now if the AI call fails, the analysis screen still shows (with empty data). After this change, "skip" and "AI error" result in the same destination (/home with no analysis). Should there be a difference in how those two cases are communicated to the user?

---

## Scope Estimate

Small. ~3 files touched, no new models, no database changes. The loading screen already exists — it just needs a button and a callback.
