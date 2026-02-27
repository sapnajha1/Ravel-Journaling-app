# Rocket Journal — Design System

> **How to use this doc**
> Part 1 catalogs every token exactly as it exists in the codebase today.
> Part 2 documents every component — current spec, proposed canonical spec, and where deviations live.
> Proposed changes are marked `→ proposed` and are not yet implemented. Once agreed, they become the source of truth for an implementation pass.

---

## Part 1 — Tokens

### 1.1 Color

Source: [`lib/design_system/app_colors.dart`](../lib/design_system/app_colors.dart)

#### Primary — Coral / Peach
The app's primary CTA color and brand anchor.

| Token | Hex | Usage |
|---|---|---|
| `primaryBase` | `#FF7B6B` | Primary button fill, active nav pill |
| `primaryMedium` | `#FFA899` | — |
| `primaryLight` | `#FFD9D4` | — |
| `primaryDark` | `#B8453A` | ScribbleCoralButton border |

#### Clarity — Purple (Reflect mode)

| Token | Hex | Usage |
|---|---|---|
| `purpleBase` | `#9B7FD9` | Reflect accent, analysis card labels, topic chip borders |
| `purpleMedium` | `#C9B8E8` | — |
| `purpleLight` | `#E9E5F5` | Reflect topic chip fill |
| `purpleDark` | `#4A3D7A` | Reflect badge text |

#### Release — Orange (Rant mode)

| Token | Hex | Usage |
|---|---|---|
| `releaseBase` | `#FFA64D` | Rant accent, analysis card labels, topic chip borders |
| `releaseMedium` | `#FFC480` | — |
| `releaseLight` | `#FFE4C8` | Rant topic chip fill |
| `releaseDark` | `#B8642E` | Rant badge text |

#### Express — Green (Scribble mode)

| Token | Hex | Usage |
|---|---|---|
| `expressBase` | `#48D99A` | — |
| `expressMedium` | `#80E6BB` | — |
| `expressLight` | `#D1F2E3` | — |
| `expressDark` | `#2A8A5F` | Scribble badge text |

#### System

| Token | Hex | Usage |
|---|---|---|
| `successBase` | `#48D99A` | — (same as expressBase) |
| `warningBase` | `#FFB74D` | — |
| `errorBase` | `#EF5350` | Recording stop button, waveform bar color (rant) |

#### Neutrals

| Token | Hex | Usage |
|---|---|---|
| `textPrimary` | `#201B18` | Body text, borders, shadow color |
| `textSecondary` | `#52443F` | Date pills, section headers, subdued text |
| `textTertiary` | `#8F8480` | Time stamps, overflow chip, divider |
| `backgroundBase` | `#FFF9F3` | Scaffold background |
| `backgroundWarm` | `#FFFBF7` | — (available, rarely used) |
| `surfaceVariant` | `#FFF9F7` | Card fill, input fill, secondary button fill |

#### ⚠️ Missing tokens — hardcoded in components

These colors appear in the codebase but have no token. They need to be decided on and added to `app_colors.dart`.

| Proposed token | Hex | Where hardcoded |
|---|---|---|
| `reflectBadgeBg` | `#E6DDFF` | `history_list_widgets.dart:189` |
| `rantBadgeBg` | `#FFD6B5` | `history_list_widgets.dart:192` |
| `scribbleBadgeBg` | `#D3F0D9` | `history_list_widgets.dart:195` |
| `strokePrimary` | `#201B18` | Alias for `textPrimary`, used as border — some places use `Colors.black` instead |

> **Note on `strokePrimary`:** Currently some borders use `Colors.black` (`#000000`) and others use `AppColors.textPrimary` (`#201B18`). These are visually close but technically different. We should align on one. Recommend `textPrimary` everywhere since `Colors.black` is pure black while the design is warm-toned.

---

### 1.2 Typography

Source: [`lib/design_system/app_text_styles.dart`](../lib/design_system/app_text_styles.dart)

**Fonts:** SyneMono (all UI text), GochiHand (handwritten/title accents)

| Token | Font | Size | Line Height | Weight | Color |
|---|---|---|---|---|---|
| `display` | SyneMono | 48px | 1.3 | default | textPrimary |
| `headlineLarge` | SyneMono | 40px | 1.3 | default | textPrimary |
| `headlineSmall` | SyneMono | 32px | 1.3 | default | textPrimary |
| `titleLarge` | SyneMono | 24px | 1.5 | default | textPrimary |
| `titleSmall` | SyneMono | 20px | 1.5 | default | textPrimary |
| `bodyLarge` | SyneMono | 18px | 1.7 | default | textPrimary |
| `bodyMedium` | SyneMono | 16px | 1.7 | default | textPrimary |
| `bodySmall` | SyneMono | 14px | 1.5 | default | textPrimary |
| `label` | SyneMono | 12px | 1.5 | default | textPrimary |
| `handwritten` | GochiHand | 20px | 1.5 | w400 | textPrimary |

#### ⚠️ Missing tokens — sizes used in components without a token

| Proposed token | Font | Size | Line Height | Weight | Where used |
|---|---|---|---|---|---|
| `handwrittenLarge` | GochiHand | 22px | 1.4 | w400 | `entry_analysis_screen.dart:62` (AI title) |
| `labelBold` | SyneMono | 12px | 1.4 | w600 | `entry_analysis_screen.dart:254` (card labels) |

> **Note on SyneMono weight:** SyneMono is a monospaced font — not all weights render visibly different. Most styles leave `fontWeight` at the platform default. Bold (`w700`) is set in several places inline (button labels, dialog titles) rather than as a token variant. Worth discussing whether we want `bodyMediumBold` and `bodySmallBold` variants or just apply `.copyWith(fontWeight: FontWeight.w700)` at the callsite.

> **Note on font size 13px:** Used in `_MoodChip` and `_TopicChip` in `entry_analysis_screen.dart`. This is between `label` (12px) and `bodySmall` (14px). Recommend snapping up to `bodySmall` (14px) or down to `label` (12px).

> **Note on font size 15px:** Used in `HistoryEntryCard` type badge. Not in scale. Recommend snapping to `bodySmall` (14px).

---

### 1.3 Spacing

Source: [`lib/design_system/app_spacing.dart`](../lib/design_system/app_spacing.dart)

8-point grid scale:

| Token | Value | Usage |
|---|---|---|
| `micro` | 8px | Icon gap in nav pill, standard small gap |
| `tight` | 16px | Input vertical padding, screen sections |
| `small` | 24px | Card/dialog padding, screen horizontal padding |
| `medium` | 32px | Screen-level section spacing |
| `large` | 40px | — |
| `xl` | 48px | PrimaryButton / SecondaryButton height |
| `section` | 64px | — |

#### ⚠️ Off-grid values in use

| Value | Where used | Status |
|---|---|---|
| 4px | Chip vertical padding, `HistoryDatePill` padding | → propose `AppSpacing.nano = 4` |
| 6px | Chip spacing (`Wrap.spacing`), profile radio gap | → ⚠️ off-grid — snap to 8px? |
| 10px | `HistorySection` pill-to-card gap, card-to-card gap | → ⚠️ off-grid — snap to 8px? |
| 12px | Dialog button gap, waveform container padding, scribble button vertical padding | → propose `AppSpacing.snug = 12` |
| 14px | Profile text field vertical padding | → ⚠️ off-grid — snap to 16px? |
| 20px | `EntryAnalysisScreen` horizontal padding, `HistoryScreen` list horizontal padding | → ⚠️ off-grid — snap to 16 or 24px? |

**Proposal:** Add two new tokens:
- `nano: 4` — needed for chip vertical padding (8pt would be too tall for a pill chip)
- `snug: 12` — needed for the gap between dialog buttons; common enough to warrant a token

For the others (6, 10, 14, 20), review each callsite and snap to the nearest grid value. 20px horizontal screen padding is the most common — consider whether we want `small` (24px) everywhere or keep 20px as a deliberate in-between.

---

### 1.4 Border Radius

Source: [`lib/design_system/app_radius.dart`](../lib/design_system/app_radius.dart)

| Token | Value | Usage |
|---|---|---|
| `button` | 4px | Defined for buttons — but **not actually used by buttons** (see deviations) |
| `card` | 8px | Cards, dialogs, input fields |
| `circular` | 999px | Fully circular elements (recording stop button, waveform bars) |
| `borderWidth` | 2px | Standard stroke weight (stored in AppRadius — slightly unusual, see note) |

> **Note on `borderWidth` placement:** Storing a stroke width inside `AppRadius` is a bit unconventional. It's used everywhere correctly, but semantically it'd sit better in a dedicated `AppStrokes` class or alongside `AppShadows`. Low priority.

#### ⚠️ Deviations

| Value used | Where | vs. token |
|---|---|---|
| 6px | `ShadowButton`, `WhiteOutlineButton`, `HomeBottomBar` (pill + outer), `ReflectTopBar`, `ScribbleOutlineButton`, `ScribbleCoralButton` | `AppRadius.button = 4` — **token is wrong** |
| 20px | `_MoodChip`, `_TopicChip`, `_HistoryMoodChips` | No pill token |
| 6px | `HistoryEntryCard` type badge | — |

**Proposal:**
- Update `AppRadius.button` from `4` → `6`. Everything that renders a button uses 6. The token doesn't reflect reality.
- Add `AppRadius.pill = 20` for chip-shaped elements.
- The remaining 6px uses (badges, type indicators) would also use `button`.

---

### 1.5 Stroke / Border Width

Currently embedded in `AppRadius.borderWidth = 2`.

| Token | Value | Usage |
|---|---|---|
| `borderWidth` | 2px | Standard border weight on cards, buttons, dialogs, input fields |

#### ⚠️ Deviations

| Value | Where |
|---|---|
| 1.5px | `_MoodChip`, `_TopicChip` (`entry_analysis_screen.dart`), `_HistoryMoodChips` (`history_list_widgets.dart`), `_AnalysisCard` |
| 0.5px | `ScribbleToolIcon` border |

**Proposal:** Add `AppRadius.borderWidthThin = 1.5` — used consistently on chips and content cards to distinguish them from interactive bordered elements.

---

### 1.6 Shadows

Source: [`lib/design_system/app_shadows.dart`](../lib/design_system/app_shadows.dart)

All shadows use color `AppColors.textPrimary` (`#201B18`) with `blurRadius: 0` — giving the app its characteristic hard-shadow / neo-brutalist look.

| Token | Offset | Blur | Usage |
|---|---|---|---|
| `shadow2` | (2, 2) | 0 | `PrimaryButton`, `SecondaryButton` |
| `shadow5` | (3, 5) | 0 | `JournalCard` (onboarding) |
| `shadow5Vertical` | (0, 5) | 0 | — |
| `shadow7` | (4, 7) | 0 | — |

#### ⚠️ Deviations

| Where | Shadow used | vs. token |
|---|---|---|
| `HomeBottomBar` | `BoxShadow(color: Color(0xFF2A2A2A), offset: Offset(4,4))` | Inline, color `#2A2A2A` not `textPrimary` (`#201B18`) |
| `ReflectTopBar` | `BoxShadow(color: Color(0xFF2A2A2A), offset: Offset(0,3))` | Inline, custom offset not in token set |
| `OnboardingActionCard` | `BoxShadow(offset: Offset(0,2), blurRadius: 4, color: black20%)` | Inline **soft** shadow — different aesthetic entirely |

> **Note:** `#2A2A2A` vs `#201B18` — these are both very dark, visually indistinguishable, but technically inconsistent. Recommend aligning to `textPrimary`.
>
> The `OnboardingActionCard` soft shadow is the only place a blurred shadow is used. Worth deciding: should onboarding match the rest of the app's hard shadow style, or is it intentionally different?

---

## Part 2 — Components

Each component shows: **current spec** (what the code does today) → **proposed canonical spec** (what it should do) → **deviations** (specific file references).

---

### Button / Primary (`ShadowButton`, `PrimaryButton`)

**Location:** [`lib/widgets/shared_buttons.dart`](../lib/widgets/shared_buttons.dart), [`lib/presentation/widgets/primary_button.dart`](../lib/presentation/widgets/primary_button.dart)

**Usage:** Primary CTA across all main screens (Reflect, History, Analysis). PrimaryButton used in onboarding full-width layout.

| Property | `ShadowButton` (current) | `PrimaryButton` (current) |
|---|---|---|
| Height | 36px (default, customizable) | 48px (AppSpacing.xl) |
| Width | shrink-to-content | 100% (`double.infinity`) |
| Background | `primaryBase` (#FF7B6B) | `primaryBase` |
| Border | 2px `Colors.black` | 2px `textPrimary` |
| Radius | 6px (hardcoded) | 4px (`AppRadius.button`) |
| Shadow | none | `shadow2` |
| Typography | SyneMono (via `DefaultTextStyle`) | `bodyMedium` (16px, 1.7lh) |
| Text color | — (inherited) | `textPrimary` |

**Proposed canonical spec (unified `AppButton` with `style: AppButtonStyle.primary`):**

| Property | Proposed |
|---|---|
| Height | 40px (on 8pt grid) |
| Width | shrink-to-content by default; `fullWidth` prop for onboarding use |
| Background | `primaryBase` |
| Border | 2px `textPrimary` |
| Radius | 6px (update `AppRadius.button` to 6) |
| Shadow | `shadow2` |
| Typography | `bodyMedium` (16px) with `fontWeight: w700` |
| Text color | `textPrimary` |

**Deviations to fix after canonical spec agreed:**
- [`shared_buttons.dart:12`](../lib/widgets/shared_buttons.dart#L12) — default height 36, no shadow, uses `Colors.black` for border
- [`entry_analysis_screen.dart:138`](../lib/screens/entry_analysis_screen.dart#L138) — `ShadowButton` with hardcoded `height: 44`
- [`reflect_widgets.dart:79`](../lib/widgets/reflect_widgets.dart#L79) — `ShadowButton` used inside dialog (height 36)

---

### Button / Secondary (`WhiteOutlineButton`, `SecondaryButton`)

**Location:** [`lib/widgets/shared_buttons.dart`](../lib/widgets/shared_buttons.dart), [`lib/presentation/widgets/secondary_button.dart`](../lib/presentation/widgets/secondary_button.dart)

**Usage:** Secondary actions in dialogs, alongside primary CTAs.

| Property | `WhiteOutlineButton` (current) | `SecondaryButton` (current) |
|---|---|---|
| Height | 36px (fixed) | 48px (AppSpacing.xl) |
| Width | shrink-to-content | 100% |
| Background | `Colors.white` | `surfaceVariant` |
| Border | 2px `Colors.black` | 2px `textPrimary` |
| Radius | 6px | 4px (`AppRadius.button`) |
| Shadow | none | `shadow2` |
| Typography | SyneMono (inherited) | `bodyMedium` |
| Text color | — (inherited) | `textPrimary` |

**Proposed canonical spec (`AppButton` with `style: AppButtonStyle.secondary`):**

| Property | Proposed |
|---|---|
| Height | 40px |
| Width | shrink-to-content or `fullWidth` |
| Background | `Colors.white` (feels more neutral than surfaceVariant in dialog contexts) |
| Border | 2px `textPrimary` |
| Radius | 6px |
| Shadow | none (secondary should feel lighter than primary) |
| Typography | `bodyMedium` (16px), `fontWeight: w700` |
| Text color | `textPrimary` |

---

### Button / Scribble (`ScribbleOutlineButton`, `ScribbleCoralButton`)

**Location:** [`lib/widgets/scribble_widgets.dart`](../lib/widgets/scribble_widgets.dart)

**Usage:** Buttons inside `ClearCanvasDialog`. These are essentially the same as the secondary/primary button patterns but with vertical-only padding (no fixed height).

| Property | `ScribbleOutlineButton` | `ScribbleCoralButton` |
|---|---|---|
| Height | auto (12px vertical padding) | auto (12px vertical padding) |
| Background | `Colors.white` | `primaryBase` |
| Border | 2px `textPrimary` | 2px `primaryDark` |
| Radius | 6px | 6px |
| Shadow | none | none |
| Typography | SyneMono, `fontSize` param (default 14), w700 | same |
| Text color | `textPrimary` | `Colors.white` ← ⚠️ inconsistent with other buttons |

> **Note:** `ScribbleCoralButton` uses white text while all other primary buttons use `textPrimary`. This is a design decision to make — either standardize on `textPrimary` (dark on coral) or allow white text here. Coral (#FF7B6B) with dark text (#201B18) has better WCAG contrast.

**Proposed:** These collapse into the unified `AppButton` pattern once that exists. The "vertical-only padding / auto-height" behavior is used only inside this one dialog — in the canonical spec, a fixed 40px height in a Row with `Expanded` on each button achieves the same layout.

---

### Bottom Navigation (`HomeBottomBar`)

**Location:** [`lib/widgets/home_bottom_bar.dart`](../lib/widgets/home_bottom_bar.dart)

**Usage:** Main app tab bar — Home, History, Profile.

| Property | Current |
|---|---|
| Container height | 58px |
| Container bg | `Colors.white` |
| Container border | 2px `Colors.black` |
| Container radius | 6px |
| Container shadow | inline: `(4,4)` offset, blur 0, color `#2A2A2A` |
| Container padding | 8px horizontal |
| Active pill height | 42px (`maxHeight` constraint) |
| Active pill bg | `primaryBase` |
| Active pill radius | 6px |
| Active pill padding | 12px horizontal, 8px vertical |
| Active icon size | 18px |
| Active label | SyneMono 16px, w400, `textPrimary` — inline |
| Inactive icon size | 22px |
| Inactive icon color | `Colors.black87` |

**Proposed canonical spec:**

| Property | Proposed | Reason |
|---|---|---|
| Container height | 56px | Snap to grid (nearest: 48xl or 64section — 56 is 7×8, reasonable for nav bar) |
| Container shadow | `AppShadows.shadow7` equiv but use `textPrimary` | Align shadow color to token |
| Active pill height | 40px | Snap to 8pt grid |
| Active label | `AppTextStyles.bodyMedium` | Use token, not inline |
| Inactive icon color | `AppColors.textPrimary` | Align to design system neutral |

---

### Card / Analysis (`_AnalysisCard`)

**Location:** [`lib/screens/entry_analysis_screen.dart:228`](../lib/screens/entry_analysis_screen.dart#L228)

**Usage:** Insight and Topics cards on the analysis screen.

| Property | Current |
|---|---|
| Background | `Colors.white` |
| Border | 1.5px `textPrimary` |
| Radius | 8px (`AppRadius.card`) ✓ |
| Padding | 16px all sides |
| Label typography | SyneMono 12px, h1.4, w600, accent color |
| Content gap | 8px below label |

**Proposed:** This is nearly correct — just the label style needs a token (`labelBold`). The 1.5px thin border is intentional to visually separate content cards from interactive bordered elements.

---

### Card / History Entry (`HistoryEntryCard`)

**Location:** [`lib/widgets/history_list_widgets.dart:81`](../lib/widgets/history_list_widgets.dart#L81)

**Usage:** Each journal entry in the History screen list.

| Property | Current |
|---|---|
| Background | `Color(0xFFFFF9F7)` — inline (= `surfaceVariant`) |
| Padding | 20px all sides |
| Type badge bg | hardcoded per entry type (see missing color tokens above) |
| Type badge radius | 6px |
| Type badge padding | 8px horizontal, 4px vertical |
| Type badge typography | SyneMono 15px, w400 — ⚠️ |
| Title typography | GochiHand 18px, h1.3, w400 (`handwritten` token is 20px — differs) |
| Time typography | SyneMono 14px, w400 (`bodySmall` ✓) |

**Proposed:**
- Use `AppColors.surfaceVariant` instead of inline color
- Snap type badge font size from 15px → 14px (`bodySmall`)
- Align title to `AppTextStyles.handwritten` (20px) or add `handwrittenSmall` at 18px — needs decision

---

### Chip / Mood

**Locations:**
- [`lib/screens/entry_analysis_screen.dart:166`](../lib/screens/entry_analysis_screen.dart#L166) — `_MoodChip`
- [`lib/widgets/history_list_widgets.dart:228`](../lib/widgets/history_list_widgets.dart#L228) — `_HistoryMoodChips`

| Property | Analysis `_MoodChip` | History `_HistoryMoodChips` |
|---|---|---|
| Background | `Colors.white` | `Colors.white` |
| Border | 1.5px `textPrimary` | 1.5px `textPrimary` |
| Radius | 20px | 20px |
| Padding | 12px h, 6px v | 10px h, 4px v |
| Typography | SyneMono 13px, h1.4 | SyneMono 12px, h1.4 |

**Proposed canonical chip spec (mood):**

| Property | Proposed |
|---|---|
| Background | `Colors.white` |
| Border | 1.5px `textPrimary` (`borderWidthThin`) |
| Radius | 20px (`AppRadius.pill`) |
| Padding | 12px h, 6px v (`snug` vertical) |
| Typography | `label` (12px) — simpler, one size for all chips |

> The 2px size difference between analysis (13px) and history (12px) chips is probably unintentional. Snapping both to `label` (12px) gives a consistent pill across the app.

---

### Chip / Topic

**Location:** [`lib/screens/entry_analysis_screen.dart:196`](../lib/screens/entry_analysis_screen.dart#L196) — `_TopicChip`

| Property | Current |
|---|---|
| Background | `accentLightColor` (purpleLight or releaseLight) |
| Border | 1.5px `accentColor` |
| Radius | 20px |
| Padding | 12px h, 6px v |
| Typography | SyneMono 13px, h1.4 |

**Proposed:** Same spec as mood chip except background uses mode-specific `accentLightColor` and border uses `accentColor`. This distinction is intentional and good — keeps topics visually distinct from mood chips.

---

### Chip / Entry Type Badge

**Location:** [`lib/widgets/history_list_widgets.dart:114`](../lib/widgets/history_list_widgets.dart#L114)

| Property | Current |
|---|---|
| Background | `#E6DDFF` / `#FFD6B5` / `#D3F0D9` (hardcoded per type) |
| Text color | `purpleDark` / `releaseDark` / `expressDark` (tokenized ✓) |
| Radius | 6px |
| Padding | 8px h, 4px v |
| Typography | SyneMono 15px, w400 |

**Proposed:**
- Add color tokens `reflectBadgeBg`, `rantBadgeBg`, `scribbleBadgeBg`
- Snap typography to `bodySmall` (14px)

---

### Dialog (`ReflectAlertDialog`)

**Location:** [`lib/widgets/reflect_widgets.dart:8`](../lib/widgets/reflect_widgets.dart#L8)

**Usage:** "Change prompt?" and "Back?" confirmations on reflect screen.

| Property | Current |
|---|---|
| Background | `Colors.white` |
| Border | 2px `Colors.black` |
| Radius | 8px |
| Padding | 24px all sides |
| Title typography | SyneMono 20px, w700, color `Color(0xFFFF6E5A)` — ⚠️ hardcoded coral |
| Message typography | SyneMono 14px, h1.4, `Colors.black87` — ⚠️ inline |
| Button gap | 12px |
| Buttons | `WhiteOutlineButton` + `ShadowButton` side by side |

**Proposed:**
- Title color: `AppColors.primaryBase` (not hardcoded `#FF6E5A` — note `#FF6E5A` ≠ `primaryBase` `#FF7B6B`, subtle difference worth fixing)
- Title style: `AppTextStyles.titleSmall` with `fontWeight: w700`
- Message style: `AppTextStyles.bodySmall`
- Border: `textPrimary` not `Colors.black`
- Button gap: `AppSpacing.snug` (12px) once token exists

---

### Dialog (`ClearCanvasDialog`)

**Location:** [`lib/widgets/scribble_widgets.dart:144`](../lib/widgets/scribble_widgets.dart#L144)

| Property | Current |
|---|---|
| Background | `Colors.white` |
| Border | 2px `primaryBase` — ⚠️ coral border (vs. `textPrimary` used everywhere else) |
| Radius | 8px |
| Padding | 24px |
| Title typography | SyneMono 24px, w700, `textPrimary` |
| Message typography | SyneMono 16px, h1.4, `textPrimary` |

**Proposed:**
- Border color: `textPrimary` — should be consistent with other dialogs. Coral border is unique to this dialog and looks like a button.
- Title style: `AppTextStyles.titleLarge` (24px) ✓
- Message style: `AppTextStyles.bodyMedium` (16px) ✓

---

### Top Bar (`ReflectTopBar`)

**Location:** [`lib/widgets/reflect_widgets.dart:100`](../lib/widgets/reflect_widgets.dart#L100)

**Usage:** Header on reflect screen with back arrow and date.

| Property | Current |
|---|---|
| Height | 60px |
| Background | `Colors.white` |
| Border | 2px `Colors.black` (left, right, bottom — no top) |
| Radius | 6px |
| Shadow | inline: `(0,3)` offset, blur 0, color `#2A2A2A` |
| Padding | 8px horizontal |
| Date typography | SyneMono 12px, w700, inline |

**Proposed:**
- Height: 56px (on 8pt grid — 60 is between xl=48 and section=64)
- Border: `textPrimary`
- Shadow: align color to `textPrimary`; offset `(0,3)` not in token set — either add `shadow3Vertical` or use `shadow2`
- Date style: `AppTextStyles.label` with `fontWeight: w700`

---

### Input Field (`AppInputField`)

**Location:** [`lib/presentation/widgets/app_input_field.dart`](../lib/presentation/widgets/app_input_field.dart)

**Usage:** Text input on auth/onboarding screens (name, email).

| Property | Current |
|---|---|
| Background | `surfaceVariant` (via theme) |
| Border | 2px `textPrimary`, radius 8px |
| Padding | 24px h (`AppSpacing.small`), 16px v (`AppSpacing.tight`) |
| Typography | `AppTextStyles.bodyMedium` |
| Label style | `bodySmall` in `textSecondary` (via theme) |

> This component is the most correct in the app — it uses tokens properly throughout. ✓

---

### Dotted Background (`DottedBackground`)

**Location:** [`lib/widgets/dotted_background.dart`](../lib/widgets/dotted_background.dart)

**Usage:** Applied as a `Positioned.fill` Stack layer on most screens.

| Property | Default |
|---|---|
| Dot color | `Color(0x18FF6E5A)` — 9.4% opacity coral |
| Dot spacing | 18px |
| Dot radius | 1.4px |

> Note: `#FF6E5A` in dot color ≠ `primaryBase` `#FF7B6B`. Minor difference, but worth aligning if we're being precise about tokens. Propose changing to `AppColors.primaryBase.withValues(alpha: 0.09)`.

---

### Waveform (`RecordingWaveform`)

**Location:** [`lib/widgets/recording_waveform.dart`](../lib/widgets/recording_waveform.dart)

**Usage:** Animated voice recording visualization on Reflect screen.

| Property | Current |
|---|---|
| Height | 80px |
| Bar width | 2px |
| Bar spacing | 1.5px |
| Bar color | `#EF5350` (`errorBase`) |
| Bar radius | 2px |
| Max bars | 200 |
| Animation duration | 120ms |

> The bar spacing of 1.5px is fractional / off-grid. Low visual impact but worth noting. The red default bar color is the rant color — on the reflect screen the bar color is overridden to `#E6DDFF` (reflect light purple). Recommend making bar color a required parameter rather than defaulting to red.

---

### Scribble Tool Icon (`ScribbleToolIcon`)

**Location:** [`lib/widgets/scribble_widgets.dart:10`](../lib/widgets/scribble_widgets.dart#L10)

**Usage:** Toolbar buttons on the scribble canvas (pen, eraser, undo, redo, clear).

| Property | Current |
|---|---|
| Size | 40×40px |
| Background | `#201B18` = `textPrimary` |
| Shape | Circle (`BoxShape.circle`) |
| Border | 0.5px self-color (barely visible — effectively none) |
| SVG size | 38×38px |

---

## Summary — Open Questions

Before the implementation pass, these need a decision:

1. **Button height:** Propose 40px for all in-screen buttons. 48px (`xl`) for onboarding full-width CTAs. Agree?

2. **`AppRadius.button` value:** Currently 4px in token but 6px in all actual usage. Update token to 6px?

3. **Font size 13px (chips):** Snap to `label` (12px) or `bodySmall` (14px)?

4. **Font size 15px (history badge):** Snap to `bodySmall` (14px)?

5. **`handwrittenLarge` (22px):** Add as a token, or snap analysis title down to `handwritten` (20px)?

6. **`handwrittenSmall` (18px):** Add for history card titles, or snap up to `handwritten` (20px)?

7. **`AppSpacing.nano = 4`** and **`AppSpacing.snug = 12`:** Add these two tokens?

8. **Spacing values 6/10/14/20px:** Each needs a deliberate snap decision.

9. **`ClearCanvasDialog` coral border:** Change to `textPrimary` for consistency?

10. **`ScribbleCoralButton` white text:** Change to `textPrimary` (dark on coral) for consistency?

11. **Soft shadow on `OnboardingActionCard`:** Should onboarding use the app's hard-shadow style?

12. **`Colors.black` vs `textPrimary` for borders:** Align to `textPrimary` everywhere?

13. **Dot background color:** Align to `primaryBase.withValues(alpha: 0.09)` instead of hardcoded `#FF6E5A`?

14. **Unified `AppButton` component:** Replace the 4 current button classes with one?
