//
//  ScammerSecurityView.swift
//  Oppie — Arrest the Scammer security dashboard.
//

import SwiftUI

struct ScammerSecurityView: View {
    @State private var pulse = false

    private struct LogItem: Identifiable {
        let id = UUID()
        let title: String
        let detail: String
        let icon: MaterialIcon
    }

    private let log: [LogItem] = [
        .init(title: "Suspicious \"Bank\" Link", detail: "Blocked at 10:14 AM Today", icon: .block),
        .init(title: "Unknown International Call", detail: "Silenced at 08:45 AM Today", icon: .callEnd)
    ]

    var body: some View {
        VStack(spacing: 0) {
            OppieTopBar()
            ScrollView {
                VStack(spacing: OppieSpacing.stackMd) {
                    heroStatus
                    summaryGrid
                    blockedLog
                    safetyTip
                    Color.clear.frame(height: 110)
                }
                .padding(.horizontal, OppieSpacing.marginMobile)
                .padding(.top, OppieSpacing.stackMd)
            }
            .background(OppieColor.background)
        }
    }

    private var heroStatus: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle().fill(OppieColor.safetyGreen.opacity(0.10))
                    .scaleEffect(pulse ? 1.25 : 1.0)
                    .opacity(pulse ? 0.0 : 0.9)
                    .animation(.easeOut(duration: 2.0).repeatForever(autoreverses: false), value: pulse)
                Circle().fill(OppieColor.safetyGreen.opacity(0.20))
                    .padding(16)
                Circle().fill(OppieColor.surfaceContainerHighest)
                    .padding(28)
                    .overlay(Circle().stroke(.white, lineWidth: 4).padding(28))
                    .oppieElevatedShadow()
                OppieIcon(.shield, size: 64, weight: .bold).foregroundStyle(OppieColor.safetyGreen)
            }
            .frame(width: 200, height: 200)
            .onAppear { pulse = true }

            VStack(spacing: 6) {
                Text("Your Phone is Secure")
                    .font(OppieFont.headlineLargeMobile())
                Text("Oppie is watching over your calls and messages right now. You're safe.")
                    .font(OppieFont.bodyLarge())
                    .foregroundStyle(OppieColor.onSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding(.top, 8)
    }

    private var summaryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: OppieSpacing.stackSm),
                            GridItem(.flexible(), spacing: OppieSpacing.stackSm)],
                  spacing: OppieSpacing.stackSm) {
            summaryCard(
                icon: .verifiedUser,
                title: "Active Watch",
                detail: "24/7 scanning for fraudulent links and voice-spoofing.",
                fg: OppieColor.onPrimaryContainer,
                bg: OppieColor.primaryContainer
            )
            summaryCard(
                icon: .emergencyHome,
                title: "Emergency Help",
                detail: "Instantly notify your family if you feel unsafe.",
                fg: OppieColor.onErrorContainer,
                bg: OppieColor.errorContainer
            )
        }
    }

    private func summaryCard(icon: MaterialIcon, title: String, detail: String, fg: Color, bg: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            OppieIcon(icon, size: 30, weight: .bold)
            Text(title).font(OppieFont.headlineMedium())
            Text(detail)
                .font(OppieFont.bodyMedium())
                .opacity(0.95)
        }
        .foregroundStyle(fg)
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: OppieRadius.large, style: .continuous).fill(bg)
        )
        .oppieSoftShadow()
    }

    private var blockedLog: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Recently Blocked", trailing: "See All")
            VStack(spacing: 12) {
                ForEach(log) { item in
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(OppieColor.scamAlertRed.opacity(0.10))
                            OppieIcon(item.icon, size: 22, weight: .bold)
                                .foregroundStyle(OppieColor.scamAlertRed)
                        }
                        .frame(width: 48, height: 48)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title).font(OppieFont.labelLarge())
                            Text(item.detail).font(OppieFont.bodyMedium())
                                .foregroundStyle(OppieColor.onSurfaceVariant)
                        }
                        Spacer()
                        OppieIcon(.chevronRight, size: 22, weight: .semibold)
                            .foregroundStyle(OppieColor.onSurfaceVariant)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(OppieColor.surfaceContainerLow)
                    )
                    .oppieSoftShadow()
                }
            }
        }
    }

    private var safetyTip: some View {
        HStack(spacing: 14) {
            OppieMascot(size: 64)
            VStack(alignment: .leading, spacing: 4) {
                Text("Oppie's Safety Tip")
                    .font(OppieFont.headlineMedium())
                Text("\"If someone asks for your password on a phone call, it's always okay to hang up. I'll stay here with you.\"")
                    .font(OppieFont.bodyMedium())
                    .foregroundStyle(OppieColor.onSurfaceVariant)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: OppieRadius.large, style: .continuous)
                .fill(OppieColor.surfaceContainerHighest)
                .overlay(
                    RoundedRectangle(cornerRadius: OppieRadius.large, style: .continuous)
                        .stroke(OppieColor.primary.opacity(0.10), lineWidth: 2)
                )
        )
    }
}

#Preview { ScammerSecurityView() }
