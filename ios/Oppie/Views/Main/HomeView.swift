//
//  HomeView.swift
//  Oppie — Home with greeting, mascot, voice mic, and quick actions.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var state: OppieAppState

    var body: some View {
        VStack(spacing: 0) {
            OppieTopBar()

            ScrollView {
                VStack(spacing: OppieSpacing.stackLg) {
                    greetingHeader
                    voiceHero
                    quickActions
                    Color.clear.frame(height: 100)
                }
                .padding(.horizontal, OppieSpacing.marginMobile)
                .padding(.top, OppieSpacing.stackLg)
            }
            .background(OppieColor.background)
        }
    }

    private var greetingHeader: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Good morning, James")
                    .font(OppieFont.headlineLargeMobile())
                    .foregroundStyle(OppieColor.onSurface)
                Text("It's a beautiful day to start fresh.")
                    .font(OppieFont.bodyMedium())
                    .foregroundStyle(OppieColor.onSurfaceVariant)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("09:15")
                    .font(OppieFont.displayLarge())
                    .foregroundStyle(OppieColor.primary)
                HStack(spacing: 4) {
                    OppieIcon(.sunny, size: 18, weight: .semibold)
                    Text("72°F").font(OppieFont.labelLarge())
                }
                .foregroundStyle(OppieColor.onSurfaceVariant)
            }
        }
    }

    private var voiceHero: some View {
        VStack(spacing: OppieSpacing.stackMd) {
            ZStack {
                Circle()
                    .fill(OppieColor.primaryContainer.opacity(0.10))
                    .frame(width: 240, height: 240)
                OppieMascot(size: 200)
            }

            VoiceWaveform()

            PulseMicButton()

            Text("\"Hey Oppie, what's my schedule?\"")
                .font(OppieFont.bodyMedium().italic())
                .foregroundStyle(OppieColor.onSurfaceVariant)
        }
    }

    private var quickActions: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: OppieSpacing.gutter),
                            GridItem(.flexible(), spacing: OppieSpacing.gutter)],
                  spacing: OppieSpacing.gutter) {
            QuickActionCard(icon: .medicalServices, title: "Medicine",
                            subtitle: "Take Vitamin D", tint: OppieColor.healthBlue)
                .onTapGesture { state.selectedTab = .health }
            QuickActionCard(icon: .call, title: "Call Family",
                            subtitle: "Sarah is online", tint: OppieColor.secondary)
            QuickActionCard(icon: .musicNote, title: "Play Music",
                            subtitle: "Relaxing Jazz", tint: OppieColor.primary)
                .onTapGesture { state.selectedTab = .fun }
            QuickActionCard(icon: .restaurant, title: "Order Food",
                            subtitle: "Lunch at 12:30", tint: OppieColor.tertiary)
        }
    }
}

#Preview {
    HomeView().environmentObject(OppieAppState())
}
