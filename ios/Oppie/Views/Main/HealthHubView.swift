//
//  HealthHubView.swift
//  Oppie — Health Hub: emergency, doctors-online, vitals, medications, caregiver.
//

import SwiftUI

struct HealthHubView: View {
    @State private var medsTaken: Set<String> = []

    private struct Med: Identifiable {
        let id = UUID()
        let name: String
        let dose: String
        let icon: MaterialIcon
        let tint: Color
        let bg: Color
    }

    private let meds: [Med] = [
        .init(name: "Vitamin D", dose: "Take 1 pill · 9:00 AM",
              icon: .pill, tint: OppieColor.onSecondaryFixed, bg: OppieColor.secondaryFixed),
        .init(name: "Blood Pressure", dose: "Take 2 pills · 12:30 PM",
              icon: .medication, tint: OppieColor.onPrimaryFixedVariant, bg: OppieColor.primaryFixed)
    ]

    var body: some View {
        VStack(spacing: 0) {
            OppieTopBar()

            ScrollView {
                VStack(spacing: OppieSpacing.stackLg) {
                    emergencyBanner
                    doctorsHero
                    vitalsBlock
                    medicationsBlock
                    caregiverCard
                    Color.clear.frame(height: 110)
                }
                .padding(.horizontal, OppieSpacing.marginMobile)
                .padding(.top, OppieSpacing.stackLg)
            }
            .background(OppieColor.background)
        }
    }

    private var emergencyBanner: some View {
        Button { } label: {
            HStack(spacing: 16) {
                OppieIcon(.emergency, size: 30, weight: .bold)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Get Help Now")
                        .font(OppieFont.headlineMedium())
                    Text("Call emergency services or family")
                        .font(OppieFont.labelLarge())
                        .opacity(0.95)
                }
                Spacer()
                OppieIcon(.chevronRight, size: 26, weight: .bold)
            }
            .foregroundStyle(.white)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(OppieColor.scamAlertRed)
            )
            .oppieElevatedShadow()
        }
        .buttonStyle(.plain)
    }

    private var doctorsHero: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("Doctors Online Now")
                        .font(OppieFont.labelLarge())
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color.white.opacity(0.18)))

                Text("Talk to a Doctor")
                    .font(OppieFont.headlineLarge())
                Text("Safe, private video calls from the comfort of your home.")
                    .font(OppieFont.bodyLarge())
                    .opacity(0.9)
                    .frame(maxWidth: 320, alignment: .leading)

                Button { } label: {
                    HStack(spacing: 10) {
                        OppieIcon(.videocam, size: 22, weight: .bold)
                        Text("Start Video Call")
                            .font(OppieFont.headlineMedium())
                    }
                    .foregroundStyle(OppieColor.primary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(.white))
                    .oppieSoftShadow()
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
            .foregroundStyle(.white)
            .padding(28)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: OppieRadius.large, style: .continuous)
                    .fill(OppieColor.primaryContainer)
            )
            .oppieElevatedShadow()

            Circle()
                .fill(Color.white.opacity(0.10))
                .frame(width: 200, height: 200)
                .blur(radius: 24)
                .offset(x: 60, y: 60)
                .allowsHitTesting(false)
        }
        .clipShape(RoundedRectangle(cornerRadius: OppieRadius.large, style: .continuous))
    }

    private var vitalsBlock: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Daily Health")
                .font(OppieFont.headlineMedium())
                .padding(.leading, 4)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 16),
                                GridItem(.flexible(), spacing: 16)],
                      spacing: 16) {
                vitalCard(icon: .heartFavorite, color: OppieColor.scamAlertRed,
                          label: "Heart Rate", big: "72", unit: "BPM · Normal", isWide: false)
                vitalCard(icon: .bedtime, color: OppieColor.healthBlue,
                          label: "Sleep", big: "7h 20m", unit: "Last night")
                vitalCard(icon: .steps, color: OppieColor.safetyGreen,
                          label: "Steps", big: "3,450", unit: "Today")
            }
        }
    }

    private func vitalCard(icon: MaterialIcon, color: Color, label: String,
                           big: String, unit: String, isWide: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                OppieIcon(icon, size: 30, weight: .bold)
                    .foregroundStyle(color)
                Spacer()
                Text(label)
                    .font(OppieFont.labelLarge())
                    .foregroundStyle(OppieColor.onSurfaceVariant)
            }
            Spacer(minLength: 6)
            VStack(alignment: .leading, spacing: 2) {
                Text(big)
                    .font(OppieFont.displayLarge())
                    .foregroundStyle(OppieColor.onSurface)
                Text(unit)
                    .font(OppieFont.labelLarge())
                    .foregroundStyle(OppieColor.onSurfaceVariant)
            }
        }
        .padding(20)
        .frame(minHeight: 160, maxHeight: .infinity, alignment: .topLeading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: OppieRadius.large, style: .continuous)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: OppieRadius.large, style: .continuous)
                        .stroke(OppieColor.outlineVariant, lineWidth: 1)
                )
        )
    }

    private var medicationsBlock: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Medications", trailing: "View Schedule")

            VStack(spacing: 12) {
                ForEach(meds) { med in
                    medRow(med)
                }
            }
        }
    }

    private func medRow(_ med: HealthHubView.Med) -> some View {
        let taken = medsTaken.contains(med.name)
        return HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(med.bg)
                OppieIcon(med.icon, size: 24, weight: .semibold)
                    .foregroundStyle(med.tint)
            }
            .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 2) {
                Text(med.name)
                    .font(OppieFont.headlineMedium())
                Text(med.dose)
                    .font(OppieFont.bodyMedium())
                    .foregroundStyle(OppieColor.onSurfaceVariant)
            }

            Spacer()

            Button {
                if taken { medsTaken.remove(med.name) } else { medsTaken.insert(med.name) }
            } label: {
                ZStack {
                    Circle()
                        .stroke(taken ? OppieColor.safetyGreen : OppieColor.outlineVariant, lineWidth: 4)
                        .background(Circle().fill(taken ? OppieColor.safetyGreen : Color.clear))
                    OppieIcon(.check, size: 22, weight: .bold)
                        .foregroundStyle(taken ? .white : OppieColor.outline.opacity(0.6))
                }
                .frame(width: 56, height: 56)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(OppieColor.outlineVariant, lineWidth: 1)
                )
        )
    }

    private var caregiverCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(OppieColor.secondaryContainer)
                Text("S")
                    .font(OppieFont.headlineMedium())
                    .foregroundStyle(.white)
            }
            .frame(width: 56, height: 56)
            .overlay(Circle().stroke(.white, lineWidth: 2))
            .oppieSoftShadow()

            VStack(alignment: .leading, spacing: 2) {
                Text("Primary Caregiver")
                    .font(OppieFont.labelLarge())
                    .foregroundStyle(OppieColor.onSurfaceVariant)
                Text("Sarah (Daughter)")
                    .font(OppieFont.headlineMedium())
            }
            Spacer()
            Button { } label: {
                OppieIcon(.call, size: 22, weight: .bold)
                    .foregroundStyle(.white)
                    .padding(14)
                    .background(Circle().fill(OppieColor.primary))
                    .oppieSoftShadow()
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: OppieRadius.large, style: .continuous)
                .fill(OppieColor.surfaceContainerHighest)
                .overlay(
                    RoundedRectangle(cornerRadius: OppieRadius.large, style: .continuous)
                        .strokeBorder(OppieColor.outlineVariant, style: StrokeStyle(lineWidth: 2, dash: [6, 6]))
                )
        )
    }
}

#Preview { HealthHubView() }
