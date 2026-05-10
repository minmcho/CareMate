//
//  WelcomeToOppieView.swift
//  Oppie — splash / welcome screen with hero mascot, get-started + sign-in.
//

import SwiftUI

struct WelcomeToOppieView: View {
    var onContinue: () -> Void = {}

    var body: some View {
        ZStack(alignment: .bottom) {
            RadialGradient(
                colors: [OppieColor.surfaceContainer, OppieColor.background],
                center: .topTrailing,
                startRadius: 80,
                endRadius: 600
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 32)

                    OppieMascot(size: 220)
                        .padding(.bottom, OppieSpacing.stackLg)

                    VStack(spacing: 12) {
                        Text("Welcome Home")
                            .font(OppieFont.displayLarge())
                            .foregroundStyle(OppieColor.primary)
                            .multilineTextAlignment(.center)

                        Text("Your warm AI companion is ready to meet you.")
                            .font(OppieFont.bodyLarge())
                            .foregroundStyle(OppieColor.onSurfaceVariant)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 360)
                    }
                    .padding(.bottom, 48)

                    quotedCard
                        .padding(.horizontal, OppieSpacing.marginMobile)
                        .padding(.bottom, OppieSpacing.stackMd)

                    VStack(spacing: 12) {
                        Button(action: onContinue) {
                            HStack {
                                Text("Get Started")
                                OppieIcon(.chevronRight, size: 22, weight: .bold)
                            }
                        }
                        .buttonStyle(TactileButtonStyle())
                        .padding(.horizontal, OppieSpacing.marginMobile)

                        VStack(spacing: 6) {
                            Text("Already have an account?")
                                .font(OppieFont.bodyMedium())
                                .foregroundStyle(OppieColor.onSurfaceVariant)
                            Button("Sign In") { }
                                .font(OppieFont.labelLarge())
                                .foregroundStyle(OppieColor.primaryContainer)
                        }
                        .padding(.top, 8)
                    }
                    .padding(.bottom, 48)

                    trustRow
                        .padding(.bottom, 80)
                }
                .padding(.top, 24)
            }

            // Bottom gradient bar
            LinearGradient(
                colors: [OppieColor.primary, OppieColor.secondaryContainer, OppieColor.primaryContainer],
                startPoint: .leading, endPoint: .trailing
            )
            .frame(height: 4)
            .opacity(0.25)
            .ignoresSafeArea(edges: .bottom)
        }
    }

    private var quotedCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(OppieColor.primaryContainer)
                OppieIcon(.heartFavorite, size: 22, weight: .bold)
                    .foregroundStyle(OppieColor.onPrimaryContainer)
            }
            .frame(width: 48, height: 48)

            Text("\"I'm here to help you stay connected, safe, and happy every day.\"")
                .font(OppieFont.bodyMedium())
                .foregroundStyle(OppieColor.onSurface)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(OppieColor.surfaceContainerLow)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(OppieColor.surfaceContainerHigh, lineWidth: 1)
                )
        )
        .oppieSoftShadow()
    }

    private var trustRow: some View {
        HStack(spacing: 24) {
            trustItem(.verified, "Secure", color: OppieColor.safetyGreen)
            trustItem(.accessibility, "Accessible", color: OppieColor.healthBlue)
            trustItem(.volunteerActivism, "Kind", color: OppieColor.secondary)
        }
        .opacity(0.7)
    }

    private func trustItem(_ icon: MaterialIcon, _ title: String, color: Color) -> some View {
        HStack(spacing: 6) {
            OppieIcon(icon, size: 18, weight: .semibold)
                .foregroundStyle(color)
            Text(title)
                .font(OppieFont.labelLarge())
                .foregroundStyle(OppieColor.onSurfaceVariant)
        }
    }
}

#Preview { WelcomeToOppieView() }
