//
//  RootView.swift
//  Oppie — top-level container with onboarding / main tab navigation.
//

import SwiftUI

@MainActor
final class OppieAppState: ObservableObject {
    @Published var hasOnboarded: Bool = false
    @Published var selectedTab: OppieTab = .home
}

struct RootView: View {
    @StateObject private var state = OppieAppState()

    var body: some View {
        Group {
            if state.hasOnboarded {
                MainTabView()
            } else {
                OnboardingFlowView()
            }
        }
        .environmentObject(state)
        .preferredColorScheme(.light)
    }
}

struct MainTabView: View {
    @EnvironmentObject var state: OppieAppState

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch state.selectedTab {
                case .home:    HomeView()
                case .health:  HealthHubView()
                case .social:  SocialHubView()
                case .fun:     FunEntertainmentView()
                case .profile: ProfileSettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(OppieColor.background.ignoresSafeArea())

            OppieBottomNav(selected: $state.selectedTab)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

#Preview { RootView() }
