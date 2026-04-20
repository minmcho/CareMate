//
//  RootView.swift
//  Top-level tab shell with Apple glass UI + rich motion.
//

import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var appState
    @State private var selection: Tab = .home

    enum Tab: Hashable { case home, plan, insights, chat, vision, habits, journal, community, profile }

    var body: some View {
        ZStack {
            AmbientBackdrop()

            TabView(selection: $selection) {
                HomeView()
                    .tag(Tab.home)
                    .tabItem { Label("Home", systemImage: "house.fill") }

                PlanView()
                    .tag(Tab.plan)
                    .tabItem { Label("Plan", systemImage: "calendar") }

                InsightsView()
                    .tag(Tab.insights)
                    .tabItem { Label("Insights", systemImage: "sparkles") }

                ChatView()
                    .tag(Tab.chat)
                    .tabItem { Label("Coach", systemImage: "message.fill") }

                VisionView()
                    .tag(Tab.vision)
                    .tabItem { Label("Vision", systemImage: "video.fill") }

                HabitsView()
                    .tag(Tab.habits)
                    .tabItem { Label("Habits", systemImage: "flame.fill") }

                JournalView()
                    .tag(Tab.journal)
                    .tabItem { Label("Journal", systemImage: "book.fill") }

                CommunityView()
                    .tag(Tab.community)
                    .tabItem { Label("Community", systemImage: "person.3.fill") }

                ProfileView()
                    .tag(Tab.profile)
                    .tabItem { Label("Profile", systemImage: "person.fill") }
            }
            .tint(.indigo)
            .background(.ultraThinMaterial)

            if appState.breathingVisible {
                BreathingOverlay()
                    .transition(.opacity.combined(with: .scale))
                    .zIndex(10)
            }

            if appState.crisisVisible {
                CrisisModal()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(20)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: appState.breathingVisible)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: appState.crisisVisible)
    }
}

/// Soft drifting gradient orbs behind every screen.
struct AmbientBackdrop: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(.systemIndigo).opacity(0.12),
                         Color(.systemPurple).opacity(0.10),
                         Color(.systemTeal).opacity(0.10)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color.indigo.opacity(0.25))
                .frame(width: 420, height: 420)
                .blur(radius: 100)
                .offset(x: animate ? -80 : -40, y: animate ? -180 : -140)

            Circle()
                .fill(Color.pink.opacity(0.22))
                .frame(width: 440, height: 440)
                .blur(radius: 120)
                .offset(x: animate ? 120 : 60, y: animate ? 280 : 220)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 14).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

/// Reusable glass surface.
struct GlassCard<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .padding(20)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.6), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 24, x: 0, y: 12)
    }
}
