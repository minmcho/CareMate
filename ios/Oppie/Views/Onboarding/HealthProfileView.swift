//
//  HealthProfileView.swift
//  Oppie — onboarding health assessment.
//

import SwiftUI

struct HealthProfileView: View {
    var onFinish: () -> Void = {}

    enum Mood { case great, tired }
    @State private var mood: Mood? = nil
    @State private var supportAreas: Set<String> = []

    private let supportItems: [(String, MaterialIcon, Color)] = [
        ("Medication Reminders",   .pill,       OppieColor.healthBlue),
        ("Daily Exercise Goals",   .exercise,   OppieColor.safetyGreen),
        ("Mental Sharpness Puzzles", .psychology, OppieColor.tertiary)
    ]

    var body: some View {
        VStack(spacing: 0) {
            OppieTopBar()

            ScrollView {
                VStack(alignment: .leading, spacing: OppieSpacing.stackMd) {
                    headerBlock

                    moodCard

                    supportCard

                    companionMessage

                    actionsBlock

                    Color.clear.frame(height: 100)
                }
                .padding(.horizontal, OppieSpacing.marginMobile)
                .padding(.top, OppieSpacing.stackLg)
            }
            .background(OppieColor.background)
        }
        .background(OppieColor.background.ignoresSafeArea())
    }

    private var headerBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ASSESSMENT")
                .font(OppieFont.labelLarge())
                .tracking(2.0)
                .foregroundStyle(OppieColor.primary)
            Text("Let's check in on you.")
                .font(OppieFont.displayLarge())
                .foregroundStyle(OppieColor.onSurface)
            Text("Answer a few simple questions so I can help you stay healthy and happy.")
                .font(OppieFont.bodyLarge())
                .foregroundStyle(OppieColor.onSurfaceVariant)
        }
    }

    private var moodCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(OppieColor.primaryContainer)
                    OppieIcon(.directionsRun, size: 24, weight: .semibold)
                        .foregroundStyle(OppieColor.onPrimaryContainer)
                }
                .frame(width: 52, height: 52)

                VStack(alignment: .leading, spacing: 4) {
                    Text("How are you feeling today?")
                        .font(OppieFont.headlineMedium())
                        .foregroundStyle(OppieColor.onSurface)
                    Text("Your energy levels help me suggest the right activities.")
                        .font(OppieFont.bodyMedium())
                        .foregroundStyle(OppieColor.onSurfaceVariant)
                }
            }

            HStack(spacing: 12) {
                moodButton(.great, label: "I feel great!", icon: .sentimentSatisfied, color: OppieColor.healthBlue)
                moodButton(.tired, label: "A bit tired.", icon: .sentimentNeutral, color: OppieColor.tertiary)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(OppieColor.surfaceContainer)
                .overlay(
                    HStack(spacing: 0) {
                        Rectangle().fill(OppieColor.primary).frame(width: 4)
                        Spacer()
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                )
        )
        .oppieSoftShadow()
    }

    private func moodButton(_ value: Mood, label: String, icon: MaterialIcon, color: Color) -> some View {
        let active = mood == value
        return Button { mood = value } label: {
            HStack(spacing: 8) {
                OppieIcon(icon, size: 22, weight: .bold)
                    .foregroundStyle(color)
                Text(label)
                    .font(OppieFont.labelLarge())
                    .foregroundStyle(OppieColor.onSurface)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(active ? OppieColor.primaryContainer.opacity(0.12) : OppieColor.surfaceContainerLowest)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(active ? OppieColor.primary : OppieColor.outlineVariant, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var supportCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(OppieColor.secondaryContainer)
                    OppieIcon(.healthSafety, size: 24, weight: .semibold)
                        .foregroundStyle(OppieColor.onSecondaryContainer)
                }
                .frame(width: 52, height: 52)

                VStack(alignment: .leading, spacing: 4) {
                    Text("What can I help with?")
                        .font(OppieFont.headlineMedium())
                        .foregroundStyle(OppieColor.onSurface)
                    Text("Select all areas where you'd like my support.")
                        .font(OppieFont.bodyMedium())
                        .foregroundStyle(OppieColor.onSurfaceVariant)
                }
            }

            VStack(spacing: 12) {
                ForEach(supportItems, id: \.0) { (title, icon, color) in
                    let active = supportAreas.contains(title)
                    Button {
                        if active { supportAreas.remove(title) } else { supportAreas.insert(title) }
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .stroke(OppieColor.outline, lineWidth: 2)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .fill(active ? OppieColor.primary : Color.clear)
                                    )
                                if active {
                                    OppieIcon(.check, size: 14, weight: .bold)
                                        .foregroundStyle(.white)
                                }
                            }
                            .frame(width: 24, height: 24)

                            OppieIcon(icon, size: 22, weight: .semibold)
                                .foregroundStyle(color)

                            Text(title)
                                .font(OppieFont.bodyLarge())
                                .foregroundStyle(OppieColor.onSurface)

                            Spacer()
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(OppieColor.surfaceContainerLowest)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(OppieColor.outlineVariant, lineWidth: 2)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(OppieColor.surfaceContainer)
        )
        .oppieSoftShadow()
    }

    private var companionMessage: some View {
        HStack(spacing: 16) {
            OppieMascot(size: 80)
            Text("\"You're doing great, neighbor! This information helps me keep our routine safe and fun.\"")
                .font(OppieFont.bodyLarge().italic())
                .foregroundStyle(OppieColor.onSurface)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: OppieRadius.large, style: .continuous)
                .fill(OppieColor.surfaceContainerLow)
        )
        .oppieSoftShadow()
    }

    private var actionsBlock: some View {
        VStack(spacing: 12) {
            Button(action: onFinish) {
                Text("Finish Assessment")
                    .frame(maxWidth: .infinity)
                    .font(OppieFont.headlineMedium())
                    .padding(.vertical, 22)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous).fill(OppieColor.primary)
                    )
                    .foregroundStyle(OppieColor.onPrimary)
                    .oppieSoftShadow()
            }
            .buttonStyle(.plain)

            Button(action: onFinish) {
                Text("Skip for now")
                    .font(OppieFont.labelLarge())
                    .foregroundStyle(OppieColor.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview { HealthProfileView() }
