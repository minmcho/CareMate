//
//  ProfileSettingsView.swift
//  Oppie — My Profile & Settings.
//

import SwiftUI

struct ProfileSettingsView: View {
    var body: some View {
        VStack(spacing: 0) {
            OppieTopBar()
            ScrollView {
                VStack(spacing: OppieSpacing.stackLg) {
                    profileHeader
                    personalizeCard
                    membershipCard
                    accountDetailsCard
                    actions
                    Color.clear.frame(height: 110)
                }
                .padding(.horizontal, OppieSpacing.marginMobile)
                .padding(.top, OppieSpacing.stackMd)
            }
            .background(OppieColor.background)
        }
    }

    private var profileHeader: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                ZStack {
                    Circle().fill(OppieColor.primaryContainer)
                        .overlay(Circle().stroke(OppieColor.surface, lineWidth: 4))
                    Text("M")
                        .font(OppieFont.displayLarge())
                        .foregroundStyle(.white)
                }
                .frame(width: 128, height: 128)
                .oppieElevatedShadow()

                Button { } label: {
                    OppieIcon(.edit, size: 16, weight: .bold)
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(Circle().fill(OppieColor.primary))
                }
                .buttonStyle(.plain)
            }
            VStack(spacing: 2) {
                Text("Margaret Thompson")
                    .font(OppieFont.headlineLargeMobile())
                Text("Member since 2023")
                    .font(OppieFont.bodyMedium())
                    .foregroundStyle(OppieColor.onSurfaceVariant)
            }
        }
    }

    private var personalizeCard: some View {
        Button { } label: {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Personalize Oppie")
                        .font(OppieFont.headlineMedium())
                        .foregroundStyle(OppieColor.onPrimaryContainer)
                    Text("Change your companion's look, voice, and personality.")
                        .font(OppieFont.bodyMedium())
                        .foregroundStyle(OppieColor.onPrimaryContainer.opacity(0.95))
                    HStack(spacing: 8) {
                        Text("Customize Now").font(OppieFont.labelLarge())
                        OppieIcon(.arrowForward, size: 18, weight: .bold)
                    }
                    .foregroundStyle(OppieColor.onPrimaryContainer)
                    .padding(.top, 2)
                }
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white.opacity(0.20))
                    OppieMascot(size: 70)
                }
                .frame(width: 96, height: 96)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: OppieRadius.large, style: .continuous)
                    .fill(OppieColor.primaryContainer)
            )
            .oppieSoftShadow()
        }
        .buttonStyle(.plain)
    }

    private var membershipCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Membership").font(OppieFont.headlineMedium())
                    Text("Premium Member")
                        .font(OppieFont.labelLarge())
                        .padding(.horizontal, 14).padding(.vertical, 5)
                        .background(Capsule().fill(OppieColor.secondaryContainer))
                        .foregroundStyle(OppieColor.onSecondaryContainer)
                }
                Spacer()
                OppieIcon(.verified, size: 30, weight: .bold)
                    .foregroundStyle(OppieColor.secondary)
            }
            Text("You have full access to health tracking, unlimited calls, and premium companions.")
                .font(OppieFont.bodyMedium())
                .foregroundStyle(OppieColor.onSurfaceVariant)

            Button { } label: {
                Text("Manage Subscription")
                    .font(OppieFont.headlineMedium())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundStyle(OppieColor.secondary)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(OppieColor.surfaceContainerLowest)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(OppieColor.secondary, lineWidth: 2)
                            )
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: OppieRadius.large, style: .continuous)
                .fill(OppieColor.surfaceContainerHigh)
                .overlay(
                    RoundedRectangle(cornerRadius: OppieRadius.large, style: .continuous)
                        .stroke(OppieColor.outlineVariant.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private var accountDetailsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Account Details")
                .font(OppieFont.headlineMedium())
                .padding(.leading, 4)
            VStack(spacing: 0) {
                accountRow(label: "Full Name", value: "Margaret Thompson", icon: .chevronRight, divider: true)
                accountRow(label: "Recovery Email", value: "m.thompson@email.com", icon: .chevronRight, divider: true)
                accountRow(label: "Security", value: "Update Password", icon: .lock, divider: false)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: OppieRadius.large, style: .continuous)
                    .fill(.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: OppieRadius.large, style: .continuous)
                            .stroke(OppieColor.surfaceContainerHighest, lineWidth: 1)
                    )
            )
            .oppieSoftShadow()
        }
    }

    private func accountRow(label: String, value: String, icon: MaterialIcon, divider: Bool) -> some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(label.uppercased())
                        .font(OppieFont.labelSmall())
                        .tracking(1.0)
                        .foregroundStyle(OppieColor.onSurfaceVariant)
                    Text(value)
                        .font(OppieFont.bodyLarge().weight(.semibold))
                        .foregroundStyle(OppieColor.onSurface)
                }
                Spacer()
                OppieIcon(icon, size: 22, weight: .semibold)
                    .foregroundStyle(OppieColor.primary)
                    .padding(8)
            }
            if divider {
                Rectangle().fill(OppieColor.surfaceContainer).frame(height: 1)
            }
        }
    }

    private var actions: some View {
        VStack(spacing: 8) {
            Button { } label: {
                HStack(spacing: 10) {
                    OppieIcon(.logout, size: 22, weight: .bold)
                    Text("Sign Out").font(OppieFont.headlineMedium())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous).fill(OppieColor.errorContainer)
                )
                .foregroundStyle(OppieColor.onErrorContainer)
            }
            .buttonStyle(.plain)

            Text("Version 2.4.1 (Stable)")
                .font(OppieFont.bodyMedium())
                .foregroundStyle(OppieColor.onSurfaceVariant.opacity(0.6))
                .padding(.top, 14)
        }
    }
}

#Preview { ProfileSettingsView() }
