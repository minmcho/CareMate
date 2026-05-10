//
//  SharedComponents.swift
//  Oppie — TopBar, BottomNav and small reusable cards used across screens.
//

import SwiftUI
import UIKit

// MARK: - Top App Bar

struct OppieTopBar: View {
    var onSettings: () -> Void = {}

    var body: some View {
        HStack {
            HStack(spacing: 12) {
                OppieAvatar(size: 40)
                Text("Oppie")
                    .font(OppieFont.headlineLargeMobile())
                    .foregroundStyle(OppieColor.primary)
            }
            Spacer()
            Button(action: onSettings) {
                OppieIcon(.settings, size: 26, weight: .medium)
                    .foregroundStyle(OppieColor.primary)
                    .padding(8)
                    .background(Color.clear)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, OppieSpacing.marginMobile)
        .padding(.vertical, 12)
        .background(OppieColor.surfaceContainerLow)
        .oppieSoftShadow()
    }
}

// MARK: - Bottom Navigation

enum OppieTab: String, CaseIterable, Identifiable {
    case home, health, social, fun, profile
    var id: String { rawValue }

    var label: String {
        switch self {
        case .home:    return "Home"
        case .health:  return "Health"
        case .social:  return "Social"
        case .fun:     return "Fun"
        case .profile: return "Profile"
        }
    }

    var icon: MaterialIcon {
        switch self {
        case .home:    return .home
        case .health:  return .medicalServices
        case .social:  return .group
        case .fun:     return .theaters
        case .profile: return .person
        }
    }
}

struct OppieBottomNav: View {
    @Binding var selected: OppieTab

    var body: some View {
        HStack(spacing: 4) {
            ForEach(OppieTab.allCases) { tab in
                tabButton(tab: tab)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 12)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity)
        .background(
            OppieColor.surfaceContainerLow
                .clipShape(RoundedCornerShape(corners: [.topLeft, .topRight], radius: 24))
                .ignoresSafeArea(edges: .bottom)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: -4)
    }

    @ViewBuilder
    private func tabButton(tab: OppieTab) -> some View {
        let isActive = selected == tab
        Button { selected = tab } label: {
            VStack(spacing: 4) {
                OppieIcon(tab.icon, size: 22, weight: isActive ? .semibold : .regular)
                Text(tab.label)
                    .font(OppieFont.labelLarge())
            }
            .foregroundStyle(isActive ? OppieColor.onPrimaryContainer : OppieColor.onSurfaceVariant)
            .padding(.horizontal, isActive ? 20 : 8)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isActive ? OppieColor.primaryContainer : Color.clear)
            )
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Rounded corner shape (selective corners)

struct RoundedCornerShape: Shape {
    var corners: UIRectCorner
    var radius: CGFloat

    func path(in rect: CGRect) -> Path {
        let p = UIBezierPath(roundedRect: rect,
                             byRoundingCorners: corners,
                             cornerRadii: CGSize(width: radius, height: radius))
        return Path(p.cgPath)
    }
}

// MARK: - Quick Action Card

struct QuickActionCard: View {
    let icon: MaterialIcon
    let title: String
    let subtitle: String
    let tint: Color

    var body: some View {
        Button { } label: {
            VStack(alignment: .leading, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(tint.opacity(0.12))
                    OppieIcon(icon, size: 28, weight: .semibold)
                        .foregroundStyle(tint)
                }
                .frame(width: 56, height: 56)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(OppieFont.headlineMedium())
                        .foregroundStyle(OppieColor.onSurface)
                    Text(subtitle)
                        .font(OppieFont.labelLarge())
                        .foregroundStyle(OppieColor.onSurfaceVariant)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: OppieRadius.large, style: .continuous)
                    .fill(OppieColor.surfaceContainerLow)
            )
            .oppieSoftShadow()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tactile Button (matches `tactile-button` from web)

struct TactileButtonStyle: ButtonStyle {
    var background: Color = OppieColor.primary
    var foreground: Color = .white
    var shadowColor: Color = OppieColor.onPrimaryFixedVariant

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .padding(.horizontal, 24)
            .font(OppieFont.headlineMedium())
            .foregroundStyle(foreground)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(background)
            )
            .offset(y: configuration.isPressed ? 2 : 0)
            .shadow(color: shadowColor,
                    radius: 0,
                    x: 0,
                    y: configuration.isPressed ? 2 : 4)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Section header

struct SectionHeader: View {
    let title: String
    var trailing: String? = nil
    var trailingAction: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(OppieFont.headlineMedium())
                .foregroundStyle(OppieColor.onSurface)
            Spacer()
            if let trailing {
                Button(action: { trailingAction?() }) {
                    Text(trailing)
                        .font(OppieFont.labelLarge())
                        .foregroundStyle(OppieColor.primary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Animated waveform (used for voice / mic UI)

struct VoiceWaveform: View {
    @State private var animate = false
    private let bars = 5
    private let baseDelays: [Double] = [0.1, 0.3, 0.5, 0.2, 0.4]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<bars, id: \.self) { i in
                RoundedRectangle(cornerRadius: 3)
                    .fill(OppieColor.primary)
                    .frame(width: 6, height: animate ? 48 : 12)
                    .animation(
                        .easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true)
                            .delay(baseDelays[i]),
                        value: animate
                    )
            }
        }
        .frame(height: 56)
        .onAppear { animate = true }
    }
}

// MARK: - Pulsing tap-to-speak button

struct PulseMicButton: View {
    var label: String = "Tap to Speak"
    var action: () -> Void = {}
    @State private var pulsing = false

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .stroke(OppieColor.primaryContainer, lineWidth: 4)
                    .scaleEffect(pulsing ? 1.4 : 0.95)
                    .opacity(pulsing ? 0 : 0.8)
                    .animation(.easeOut(duration: 2.5).repeatForever(autoreverses: false), value: pulsing)
                HStack(spacing: 14) {
                    OppieIcon(.mic, size: 30, weight: .bold)
                    Text(label)
                        .font(OppieFont.headlineMedium())
                }
                .foregroundStyle(OppieColor.onPrimaryContainer)
                .padding(.horizontal, 36)
                .padding(.vertical, 22)
                .background(
                    Capsule().fill(OppieColor.primaryContainer)
                )
                .oppieSoftShadow()
            }
        }
        .buttonStyle(.plain)
        .onAppear { pulsing = true }
    }
}
