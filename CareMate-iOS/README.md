# CareMate iOS

SwiftUI iOS application for the CareMate caregiver assistant platform.

## Requirements

- Xcode 15.3+
- iOS 17.0+
- Swift 5.9+
- CareMate Backend running (see `../CareMate-Backend/`)

## Architecture

```
MVVM + SwiftUI
├── Models/         Plain Codable structs (ScheduleTask, Medication, Recipe, ChatMessage…)
├── ViewModels/     @MainActor ObservableObject classes (async/await API calls)
├── Views/          SwiftUI views (ScheduleView, MedicationView, DietView, GuidanceView,
│                   AssistantView, TranslateView)
└── Services/       APIService (generic REST client), SpeechService (STT + TTS playback)
```

## Features

| Screen | Features |
|--------|---------|
| Schedule | Daily task list, status cycling (pending → in-progress → completed), countdown timers |
| Medication | Medication tracker, overdue alerts, toggle taken |
| Diet | Meal plan, recipe library, AI photo recipe extraction |
| Guidance | Caregiver training modules with category/tag filters and video playback |
| Assistant | AI chat with CrewAI agents, voice input (Whisper STT), TTS playback, memory toggle |
| Translate | Bidirectional text & audio translation (EN ↔ MY ↔ TH ↔ AR) |

## Configuration

Set the backend URL in `CareMate/Resources/Info.plist`:

```xml
<key>API_BASE_URL</key>
<string>http://your-backend-host:8080</string>
```

Or set the `API_BASE_URL` environment variable in the Xcode scheme.

## Open in Xcode

```bash
open CareMate.xcodeproj
```

## Supported Languages

- English (EN)
- Myanmar / Burmese (MY)
- Thai (TH)
- Arabic (AR)
