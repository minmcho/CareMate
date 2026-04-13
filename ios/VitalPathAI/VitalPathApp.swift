//
//  VitalPathApp.swift
//  VitalPath AI — SwiftUI entry point.
//

import SwiftUI
import SwiftData

@main
struct VitalPathApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .preferredColorScheme(.light)
        }
        .modelContainer(for: [
            WellnessProfile.self,
            WellnessSession.self,
            Habit.self,
            ChatMessage.self,
            VideoAnalysis.self,
            CrisisAudit.self,
            JournalEntry.self,
            CommunityTopic.self,
            CommunityPost.self,
            CommunityReply.self
        ])
    }
}

/// Global app state — observable via iOS 17's @Observable macro.
@Observable
final class AppState {
    var language: AppLanguage = .en
    var crisisVisible: Bool = false
    var breathingVisible: Bool = false
    var onlineMode: OnlineMode = .online

    enum OnlineMode { case online, fallback }
}
