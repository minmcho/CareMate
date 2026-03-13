import SwiftUI

enum Tab: String, CaseIterable {
    case schedule = "Schedule"
    case medication = "Medication"
    case diet = "Diet"
    case guidance = "Guidance"
    case assistant = "Assistant"

    var icon: String {
        switch self {
        case .schedule:   return "calendar.badge.clock"
        case .medication: return "pills.fill"
        case .diet:       return "fork.knife"
        case .guidance:   return "play.circle.fill"
        case .assistant:  return "bubble.left.and.bubble.right.fill"
        }
    }

    var localizedTitle: String {
        return self.rawValue
    }
}

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: Tab = .schedule

    var body: some View {
        TabView(selection: $selectedTab) {
            ScheduleView()
                .tabItem {
                    Label(Tab.schedule.localizedTitle, systemImage: Tab.schedule.icon)
                }
                .tag(Tab.schedule)

            MedicationView()
                .tabItem {
                    Label(Tab.medication.localizedTitle, systemImage: Tab.medication.icon)
                }
                .tag(Tab.medication)

            DietView()
                .tabItem {
                    Label(Tab.diet.localizedTitle, systemImage: Tab.diet.icon)
                }
                .tag(Tab.diet)

            GuidanceView()
                .tabItem {
                    Label(Tab.guidance.localizedTitle, systemImage: Tab.guidance.icon)
                }
                .tag(Tab.guidance)

            AssistantView()
                .tabItem {
                    Label(Tab.assistant.localizedTitle, systemImage: Tab.assistant.icon)
                }
                .tag(Tab.assistant)
        }
        .accentColor(.blue)
    }
}
