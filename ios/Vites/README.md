# Vites iOS

SwiftUI implementation of the Vites mobile UI, built to the design package in
`stitch_comprehensive_application_ui_design/` and the product specs in
`editorspec.md` and `compliance.md`.

## Open the project

```
open ios/Vites/Vites.xcodeproj
```

Requires Xcode 15+; deployment target is iOS 16. The scheme `Vites` builds the
app and runs it on the iPhone simulator.

## What's implemented

Five primary tabs, each rendered with the Vites design system (Soft-Tactile
Minimalism: functional pastel palette, hyper-rounded geometry, ambient
coloured shadows):

| Tab      | View                | Notes                                                                                                  |
|----------|---------------------|--------------------------------------------------------------------------------------------------------|
| Discover | `DiscoverView`      | Trend Discovery feed with heat pills, platform chips, velocity sparkline, generate-brief CTA.          |
| Briefs   | `BriefsView`        | Niche brief detail: audience profile, format patterns, current brief card with AI-generated label.     |
| Review   | `ReviewView`        | Content Review Queue with claims / facts / originality verifier badges and per-status action rows.     |
| Agents   | `AgentsView`        | Agent Hub with mascot avatars, status pills, Mission Control progress, Hatch New Agent callout.        |
| Library  | `LibraryView`       | Verified content bundles with ledger ID, origin / reviewer meta, avatar strip, Open action.            |

Shared:

- `DesignSystem/Theme.swift` – design tokens (colour, radius, spacing, typography fallbacks, ambient shadow).
- `DesignSystem/Components.swift` – chip, card, primary/secondary button, status dot, sparkline, progress bar, top bar.
- `DesignSystem/Mascot.swift` – kawaii-inspired mascot avatar with float and pulse-ring animations (honours reduce-motion).
- `Views/VitesScreen.swift` – screen scaffold (brand top bar + scroll view + surface gradient).
- `Views/RootView.swift` – floating glass tab bar with bouncy press animation and haptic feedback.

## Compliance hooks already wired in

Per `compliance.md` and `editorspec.md` the UI bakes in:

- Accessibility: 44pt minimum tap targets, VoiceOver labels on interactive
  elements, reduce-motion honoured, dynamic type via the SwiftUI font scale.
- Privacy: `Info.plist` carries usage strings for camera / mic / photo / ATT
  that are requested at time-of-use only.
- AI provenance: an "AI Generated" chip rides on every AI-authored block on
  the Briefs and Review surfaces.

## What's stubbed

- Real platform brand glyphs (TikTok, Instagram, etc.) — currently SF Symbols
  as placeholders to keep the build licence-clean.
- Quicksand and Be Vietnam Pro fonts — the project falls back to the rounded
  system font so it always builds. Drop the TTFs in `Vites/Fonts/` and add
  them to `Info.plist > UIAppFonts` to enable the brand voice.
- Network layer / state. All views consume in-file `sample` fixtures.
