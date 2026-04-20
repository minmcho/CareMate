import SwiftUI

enum Tab: String, CaseIterable {
    case schedule  = "Schedule"
    case medication = "Medication"
    case diet      = "Diet"
    case guidance  = "Guidance"
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
}

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: Tab = .schedule

    var body: some View {
        ZStack(alignment: .bottom) {
            // Global glass background
            GlassBackground()
                .ignoresSafeArea()

            // Content
            Group {
                switch selectedTab {
                case .schedule:   ScheduleView()
                case .medication: MedicationView()
                case .diet:       DietView()
                case .guidance:   GuidanceView()
                case .assistant:  AssistantView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Floating glass tab bar
            GlassTabBar(selectedTab: $selectedTab)
        }
    }
}

// MARK: - Glass Tab Bar

struct GlassTabBar: View {
    @Binding var selectedTab: Tab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 20, weight: selectedTab == tab ? .semibold : .regular))
                            .symbolEffect(.bounce, value: selectedTab == tab)
                        Text(tab.rawValue)
                            .font(.system(size: 10, weight: selectedTab == tab ? .semibold : .regular))
                    }
                    .foregroundStyle(selectedTab == tab ? .blue : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background {
                        if selectedTab == tab {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(.blue.opacity(0.12))
                                .padding(.horizontal, 6)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 4)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28))
        .overlay {
            RoundedRectangle(cornerRadius: 28)
                .stroke(.white.opacity(0.4), lineWidth: 0.8)
        }
        .shadow(color: .black.opacity(0.12), radius: 20, x: 0, y: 8)
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }
}

// MARK: - Global Glass Background

struct GlassBackground: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            if colorScheme == .dark {
                Color(red: 0.05, green: 0.07, blue: 0.12)
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.82, green: 0.91, blue: 1.0),
                        Color(red: 0.91, green: 0.86, blue: 1.0),
                        Color(red: 0.86, green: 0.95, blue: 0.98)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }

            // Soft blobs
            Circle()
                .fill(Color.blue.opacity(colorScheme == .dark ? 0.12 : 0.18))
                .frame(width: 320)
                .blur(radius: 60)
                .offset(x: -80, y: -200)

            Circle()
                .fill(Color.purple.opacity(colorScheme == .dark ? 0.10 : 0.15))
                .frame(width: 280)
                .blur(radius: 60)
                .offset(x: 120, y: 200)
        }
    }
}

// MARK: - Shared Glass Card Modifier

struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = 20
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(.white.opacity(0.35), lineWidth: 0.8)
            }
            .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 20, padding: CGFloat = 16) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius, padding: padding))
    }
}
