//
//  MeetYourFriendView.swift
//  Oppie — Personalize Your Oppie (name, fur color, voice style).
//

import SwiftUI

struct MeetYourFriendView: View {
    var onContinue: () -> Void = {}

    @State private var name: String = "Oppie"
    @State private var furColor: Color = OppieColor.primaryContainer
    @State private var voice: VoiceStyle = .calm

    enum VoiceStyle: String, CaseIterable {
        case calm = "Calm", energetic = "Energetic", gentle = "Gentle"
        var icon: MaterialIcon {
            switch self {
            case .calm: return .spa
            case .energetic: return .bolt
            case .gentle: return .favorite
            }
        }
    }

    private let palette: [Color] = [
        OppieColor.primaryContainer,
        OppieColor.companionFur,
        OppieColor.secondary,
        OppieColor.healthBlue,
        OppieColor.safetyGreen
    ]

    var body: some View {
        VStack(spacing: 0) {
            OppieTopBar()

            ScrollView {
                VStack(spacing: OppieSpacing.stackLg) {
                    heroSection
                    cards
                    voicePreview
                    Color.clear.frame(height: 110)
                }
                .padding(.horizontal, OppieSpacing.marginMobile)
                .padding(.top, OppieSpacing.stackMd)
            }
            .background(OppieColor.background)
        }
        .background(OppieColor.background.ignoresSafeArea())
        .overlay(alignment: .bottom) {
            VStack {
                Button(action: onContinue) {
                    HStack {
                        Text("Finish Setup")
                        OppieIcon(.arrowForward, size: 22, weight: .bold)
                    }
                }
                .buttonStyle(TactileButtonStyle())
                .padding(.horizontal, OppieSpacing.marginMobile)
                .padding(.bottom, 32)
            }
            .padding(.top, 32)
            .background(
                LinearGradient(colors: [Color.clear, OppieColor.background, OppieColor.background],
                               startPoint: .top, endPoint: .bottom)
            )
        }
    }

    private var heroSection: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                ZStack {
                    Circle()
                        .fill(OppieColor.primaryFixed.opacity(0.5))
                        .blur(radius: 36)
                    OppieMascot(furColor: furColor, size: 200)
                        .padding(20)
                        .background(
                            Circle()
                                .fill(OppieColor.warmSurface)
                                .overlay(Circle().stroke(OppieColor.surfaceContainerHighest, lineWidth: 4))
                                .oppieSoftShadow()
                        )
                }
                .frame(width: 240, height: 240)

                ZStack {
                    Circle().fill(OppieColor.primary)
                    OppieIcon(.edit, size: 18, weight: .bold)
                        .foregroundStyle(OppieColor.onPrimary)
                }
                .frame(width: 44, height: 44)
                .oppieSoftShadow()
                .offset(x: -8, y: -8)
            }

            VStack(spacing: 4) {
                Text("Personalize Your Oppie")
                    .font(OppieFont.headlineMedium())
                    .foregroundStyle(OppieColor.onSurface)
                Text("Your supportive friend is ready to be customized.")
                    .font(OppieFont.bodyMedium())
                    .foregroundStyle(OppieColor.onSurfaceVariant)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var cards: some View {
        VStack(spacing: OppieSpacing.gutter) {
            // Name card
            customizationCard(icon: .badge, title: "GIVE A NAME", iconColor: OppieColor.primary) {
                TextField("Type a name…", text: $name)
                    .textFieldStyle(.plain)
                    .font(OppieFont.bodyLarge())
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(OppieColor.surfaceBright)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(OppieColor.surfaceContainerHighest, lineWidth: 2)
                            )
                    )
                Text("\"\(name)\" is a great choice!")
                    .font(OppieFont.bodyMedium().italic())
                    .foregroundStyle(OppieColor.onSurfaceVariant)
            }

            // Color card
            customizationCard(icon: .palette, title: "CHOOSE COLOR", iconColor: OppieColor.secondary) {
                HStack(spacing: 12) {
                    ForEach(palette.indices, id: \.self) { idx in
                        let color = palette[idx]
                        Button { furColor = color } label: {
                            Circle()
                                .fill(color)
                                .frame(width: 40, height: 40)
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                .overlay(
                                    Circle().stroke(furColor == color ? OppieColor.primary : Color.clear, lineWidth: 3)
                                        .padding(-4)
                                )
                                .oppieSoftShadow()
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity)
                    }
                }
                Text("Tap to change the fur color.")
                    .font(OppieFont.bodyMedium())
                    .foregroundStyle(OppieColor.onSurfaceVariant)
            }

            // Voice card
            customizationCard(icon: .voiceOver, title: "VOICE STYLE", iconColor: OppieColor.tertiary) {
                HStack(spacing: 10) {
                    ForEach(VoiceStyle.allCases, id: \.self) { v in
                        let active = voice == v
                        Button { voice = v } label: {
                            VStack(spacing: 6) {
                                OppieIcon(v.icon, size: 26, weight: .semibold)
                                Text(v.rawValue)
                                    .font(OppieFont.labelLarge())
                            }
                            .foregroundStyle(active ? OppieColor.onPrimary : OppieColor.onSurfaceVariant)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(active ? OppieColor.primary : OppieColor.surfaceBright)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .stroke(active ? OppieColor.primary.opacity(0.25) : OppieColor.surfaceContainerHighest, lineWidth: 2)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func customizationCard<Content: View>(
        icon: MaterialIcon,
        title: String,
        iconColor: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                OppieIcon(icon, size: 20, weight: .semibold)
                Text(title)
                    .font(OppieFont.labelLarge())
                    .tracking(1.5)
            }
            .foregroundStyle(iconColor)
            content()
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: OppieRadius.large, style: .continuous)
                .fill(OppieColor.surfaceContainerLow)
                .overlay(
                    RoundedRectangle(cornerRadius: OppieRadius.large, style: .continuous)
                        .stroke(OppieColor.surfaceContainerHighest, lineWidth: 1)
                )
        )
        .oppieSoftShadow()
    }

    private var voicePreview: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(OppieColor.primary)
                OppieIcon(.volumeUp, size: 22, weight: .semibold)
                    .foregroundStyle(OppieColor.onPrimary)
            }
            .frame(width: 48, height: 48)
            Text("\"Hello! I'm so happy to meet you. I'll be here whenever you need me.\"")
                .font(OppieFont.bodyMedium().italic())
                .foregroundStyle(OppieColor.onSurface)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: OppieRadius.large, style: .continuous)
                .fill(OppieColor.primaryContainer.opacity(0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: OppieRadius.large, style: .continuous)
                        .stroke(OppieColor.primaryContainer, lineWidth: 2)
                )
        )
    }
}

#Preview { MeetYourFriendView() }
