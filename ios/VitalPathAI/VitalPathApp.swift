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
            CommunityReply.self,
            ManifestationEntry.self,
        ])
    }
}

// MARK: - Tab definitions

enum AppTab: String, Hashable, Codable, CaseIterable, Identifiable {
    case home, plan, insights, chat, vision, habits, journal, community, manifest, profile, more

    var id: String { rawValue }

    var label: String {
        switch self {
        case .home:      return "Home"
        case .plan:      return "Plan"
        case .insights:  return "Insights"
        case .chat:      return "Coach"
        case .vision:    return "Vision"
        case .habits:    return "Habits"
        case .journal:   return "Journal"
        case .community: return "Community"
        case .manifest:  return "Manifest"
        case .profile:   return "Profile"
        case .more:      return "More"
        }
    }

    var icon: String {
        switch self {
        case .home:      return "house.fill"
        case .plan:      return "calendar"
        case .insights:  return "sparkles"
        case .chat:      return "message.fill"
        case .vision:    return "video.fill"
        case .habits:    return "flame.fill"
        case .journal:   return "book.fill"
        case .community: return "person.3.fill"
        case .manifest:  return "star.fill"
        case .profile:   return "person.fill"
        case .more:      return "ellipsis.circle"
        }
    }

    static var editable: [AppTab] {
        allCases.filter { $0 != .more }
    }

    static var defaultVisible: [AppTab] {
        [.home, .plan, .insights, .chat, .habits]
    }
}

// MARK: - App State

@Observable
final class AppState {
    var language: AppLanguage = .en
    var crisisVisible: Bool = false
    var breathingVisible: Bool = false
    var onlineMode: OnlineMode = .online
    var selectedTab: AppTab = .home
    var breathingTechniqueID: String = BreathworkCatalog.default.id

    var visibleTabs: [AppTab] = AppTab.defaultVisible

    var hiddenTabs: [AppTab] {
        AppTab.editable.filter { !visibleTabs.contains($0) }
    }

    enum OnlineMode { case online, fallback }

    init() { loadTabs() }

    func navigate(to tab: AppTab) {
        if visibleTabs.contains(tab) {
            selectedTab = tab
        } else {
            selectedTab = .more
        }
    }

    func saveTabs() {
        guard let data = try? JSONEncoder().encode(visibleTabs) else { return }
        UserDefaults.standard.set(data, forKey: "vp_visible_tabs")
    }

    func loadTabs() {
        guard let data = UserDefaults.standard.data(forKey: "vp_visible_tabs"),
              let tabs = try? JSONDecoder().decode([AppTab].self, from: data),
              tabs.count >= 5
        else { return }
        visibleTabs = tabs
    }
}
