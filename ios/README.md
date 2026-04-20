# VitalPath AI — iOS (SwiftUI)

The native iOS companion to the VitalPath AI wellness platform.

## Architecture

- **iOS 17+** with the `@Observable` macro for reactive state.
- **SwiftUI + MVVM + Clean Architecture** — `Views` are dumb, `ViewModels`
  coordinate, `Services` hold the business logic, `Networking` handles
  transport.
- **SwiftData** for on-device persistence. Models in
  `Models/Models.swift` mirror the backend SQLAlchemy schema so the sync
  engine can map 1:1.
- **Apple Liquid Glass UI** — `.ultraThinMaterial` surfaces, radial/linear
  gradients, gentle spring animations, and `matchedGeometryEffect` for tab
  transitions.
- **Localization** — `AppLanguage` covers EN, MY, TH, ZH, JA, KO via
  `Localizable.strings`.

## Safety layer (mirrors backend)

`Services/SafetyValidator.swift` runs pre- and post-processing safety sweeps
on-device before any network call. Crisis events are only ever stored as
SHA-256 digests via `hashForAudit`.

## Networking

`Networking/GraphQLClient.swift` implements:

- Exponential backoff retry (1s → 2s → 4s).
- A Hystrix-style circuit breaker (opens after 5 failures, 20s cooldown,
  half-open probe).
- Strawberry GraphQL-compatible envelope decoding.

## Project layout

```
ios/
├── VitalPathAI.xcodeproj/        # Xcode project (open this)
│   ├── project.pbxproj
│   ├── project.xcworkspace/
│   └── xcshareddata/xcschemes/VitalPathAI.xcscheme
└── VitalPathAI/
    ├── VitalPathApp.swift        # @main + SwiftData container
    ├── Models/Models.swift       # SwiftData models
    ├── Services/SafetyValidator.swift
    ├── Networking/GraphQLClient.swift
    ├── ViewModels/ChatViewModel.swift
    ├── Views/
    │   ├── RootView.swift        # Glass tab shell + ambient backdrop
    │   ├── HomeView.swift        # Streak ring, mood, focus grid
    │   ├── ChatView.swift        # Coach bubbles, typing, safety notice
    │   ├── VisionView.swift      # Meal / movement analysis
    │   ├── HabitsView.swift      # Habit list + freeze streak
    │   ├── ProfileView.swift     # Preferences, language, privacy
    │   ├── AdminView.swift       # Ops metrics + App Store readiness
    │   ├── CrisisModal.swift     # Localized crisis hotlines
    │   └── BreathingOverlay.swift
    ├── Assets.xcassets/          # AppIcon + AccentColor
    └── Preview Content/
        └── Preview Assets.xcassets
```

## Running

Open `ios/VitalPathAI.xcodeproj` in Xcode 15 or later. The project targets
iOS 17+, uses `GENERATE_INFOPLIST_FILE = YES` (no hand-edited `Info.plist`),
and ships a shared scheme so `xcodebuild -scheme VitalPathAI` works out of
the box. Bundle identifier: `ai.vitalpath.VitalPathAI`.

Before shipping:

1. Point `GraphQLClient` at your backend (see `Views/ChatView.swift` init).
2. Wire a Supabase JWT provider into `ChatViewModel`'s `tokenProvider`.
3. Replace the placeholder `AppIcon` in `Assets.xcassets` with your artwork.
