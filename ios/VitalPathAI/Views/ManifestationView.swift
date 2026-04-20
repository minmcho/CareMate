//
//  ManifestationView.swift
//  Daily affirmations, intentions, gratitude practice & vision board.
//

import SwiftUI
import SwiftData

struct ManifestationView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ManifestationEntry.createdAt, order: .reverse) private var entries: [ManifestationEntry]

    @State private var showingNewEntry = false
    @State private var affirmationIndex = 0

    // Draft state
    @State private var draftIntention   = ""
    @State private var draftGratitude1  = ""
    @State private var draftGratitude2  = ""
    @State private var draftGratitude3  = ""
    @State private var draftVision      = ""
    @State private var draftAffirmation = ""

    static let affirmations: [String] = [
        "I am worthy of vibrant health, joy, and abundance.",
        "Every day I grow stronger, calmer, and more resilient.",
        "I attract positive energy and wellness into every area of my life.",
        "I am grateful for this body that carries me forward each day.",
        "My mind and body are healing, thriving, and becoming whole.",
        "I choose peace, purpose, and vitality — starting right now.",
        "I am fully capable of achieving what I set my heart on.",
        "My wellness journey is unfolding in exactly the right way.",
        "I radiate confidence, clarity, and compassionate strength.",
        "Each breath I take fills me with calm, focus, and clarity.",
        "I release what no longer serves me and welcome new growth.",
        "I deserve deep rest, real nourishment, and gentle movement.",
        "My potential is limitless and my progress is real.",
        "I am becoming the healthiest, happiest version of myself.",
    ]

    private var todayAffirmation: String {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return Self.affirmations[day % Self.affirmations.count]
    }

    private var todayEntry: ManifestationEntry? {
        let cal = Calendar.current
        return entries.first { cal.isDateInToday($0.createdAt) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    affirmationHero
                    if todayEntry == nil {
                        todayEntryForm
                    } else {
                        todayCompletedCard
                    }
                    if entries.count > 1 || (entries.count == 1 && todayEntry == nil) {
                        historySection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 80)
            }
            .navigationTitle("Manifestation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(
                LinearGradient(colors: [Color(red: 0.95, green: 0.75, blue: 0.25), Color.orange],
                               startPoint: .leading, endPoint: .trailing),
                for: .navigationBar
            )
            .toolbarColorScheme(.dark, for: .navigationBar)
            .scrollContentBackground(.hidden)
        }
    }

    // MARK: — Affirmation Hero

    private var affirmationHero: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 1.0, green: 0.65, blue: 0.1),
                                 Color(red: 0.9, green: 0.3, blue: 0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(maxWidth: .infinity)
                .frame(height: 148)
                .shadow(color: .orange.opacity(0.3), radius: 14, x: 0, y: 6)

            // Decorative stars
            Text("✨").font(.system(size: 42)).opacity(0.25).offset(x: 260, y: -90)
            Text("⭐").font(.system(size: 26)).opacity(0.2).offset(x: 300, y: -40)
            Text("🌟").font(.system(size: 20)).opacity(0.18).offset(x: 230, y: -30)

            VStack(alignment: .leading, spacing: 10) {
                Label("Daily Affirmation", systemImage: "star.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.85))
                Text(todayAffirmation)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                Text(Date().formatted(.dateTime.weekday(.wide).month(.wide).day()))
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .clipped()
    }

    // MARK: — Today Entry Form

    private var todayEntryForm: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Today's Practice", icon: "sun.max.fill", color: .orange)

            // Intention
            entryCard {
                VStack(alignment: .leading, spacing: 10) {
                    Label("My Intention", systemImage: "target")
                        .font(.subheadline.bold())
                        .foregroundStyle(.orange)
                    TextField("Today I intend to…", text: $draftIntention, axis: .vertical)
                        .font(.callout)
                        .lineLimit(3...5)
                        .autocorrectionDisabled()
                }
            }

            // Gratitude
            entryCard {
                VStack(alignment: .leading, spacing: 12) {
                    Label("3 Gratitudes", systemImage: "heart.fill")
                        .font(.subheadline.bold())
                        .foregroundStyle(.pink)
                    gratitudeField(number: "1", text: $draftGratitude1, placeholder: "I am grateful for…")
                    Divider()
                    gratitudeField(number: "2", text: $draftGratitude2, placeholder: "I appreciate…")
                    Divider()
                    gratitudeField(number: "3", text: $draftGratitude3, placeholder: "Today I value…")
                }
            }

            // Vision
            entryCard {
                VStack(alignment: .leading, spacing: 10) {
                    Label("My Vision", systemImage: "eye.fill")
                        .font(.subheadline.bold())
                        .foregroundStyle(.purple)
                    TextField("Describe your ideal life, health, goals…", text: $draftVision, axis: .vertical)
                        .font(.callout)
                        .lineLimit(4...8)
                        .autocorrectionDisabled()
                }
            }

            // Save Button
            Button { saveEntry() } label: {
                HStack {
                    Image(systemName: "sparkles")
                    Text("Save Today's Entry")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Color(red: 1.0, green: 0.6, blue: 0.0), Color(red: 0.9, green: 0.3, blue: 0.5)],
                        startPoint: .leading, endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                )
                .foregroundStyle(.white)
                .shadow(color: .orange.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .buttonStyle(.plain)
            .disabled(draftIntention.trimmingCharacters(in: .whitespaces).isEmpty &&
                      draftGratitude1.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    // MARK: — Completed Card

    private var todayCompletedCard: some View {
        guard let entry = todayEntry else { return AnyView(EmptyView()) }
        return AnyView(
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader("Today Complete ✓", icon: "checkmark.seal.fill", color: .green)

                entryCard {
                    VStack(alignment: .leading, spacing: 14) {
                        if !entry.intention.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Label("Intention", systemImage: "target")
                                    .font(.caption.bold()).foregroundStyle(.orange)
                                Text(entry.intention).font(.callout)
                            }
                        }
                        let nonEmptyGratitudes = entry.gratitudes.filter { !$0.isEmpty }
                        if !nonEmptyGratitudes.isEmpty {
                            Divider()
                            VStack(alignment: .leading, spacing: 6) {
                                Label("Gratitudes", systemImage: "heart.fill")
                                    .font(.caption.bold()).foregroundStyle(.pink)
                                ForEach(Array(nonEmptyGratitudes.enumerated()), id: \.offset) { i, g in
                                    HStack(alignment: .top, spacing: 8) {
                                        Text("\(i + 1).")
                                            .font(.caption.bold())
                                            .foregroundStyle(.secondary)
                                        Text(g).font(.callout)
                                    }
                                }
                            }
                        }
                        if !entry.visionText.isEmpty {
                            Divider()
                            VStack(alignment: .leading, spacing: 4) {
                                Label("Vision", systemImage: "eye.fill")
                                    .font(.caption.bold()).foregroundStyle(.purple)
                                Text(entry.visionText).font(.callout)
                            }
                        }
                    }
                }
            }
        )
    }

    // MARK: — History

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Past Entries", icon: "clock.arrow.circlepath", color: .secondary)
            ForEach(entries.filter { !Calendar.current.isDateInToday($0.createdAt) }) { entry in
                entryCard {
                    HStack(alignment: .top, spacing: 12) {
                        VStack(spacing: 2) {
                            Text(dayLabel(entry.createdAt))
                                .font(.headline.bold())
                            Text(monthLabel(entry.createdAt))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: 40)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 6)
                        .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))

                        VStack(alignment: .leading, spacing: 4) {
                            if !entry.intention.isEmpty {
                                Text(entry.intention)
                                    .font(.subheadline)
                                    .lineLimit(2)
                            }
                            let nonEmpty = entry.gratitudes.filter { !$0.isEmpty }
                            if !nonEmpty.isEmpty {
                                Text("✦ " + nonEmpty.first!)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        Spacer()
                    }
                }
            }
        }
    }

    // MARK: — Sub-views

    private func sectionHeader(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(color)
            Text(title)
                .font(.title3.bold())
        }
    }

    private func entryCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.55), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    private func gratitudeField(number: String, text: Binding<String>, placeholder: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(number)
                .font(.subheadline.bold())
                .foregroundStyle(.orange)
                .frame(width: 16)
            TextField(placeholder, text: text, axis: .vertical)
                .font(.callout)
                .lineLimit(2...3)
                .autocorrectionDisabled()
        }
    }

    // MARK: — Actions

    private func saveEntry() {
        let entry = ManifestationEntry(
            affirmation: todayAffirmation,
            intention:   draftIntention.trimmingCharacters(in: .whitespaces),
            gratitudes:  [draftGratitude1, draftGratitude2, draftGratitude3]
                            .map { $0.trimmingCharacters(in: .whitespaces) },
            visionText:  draftVision.trimmingCharacters(in: .whitespaces)
        )
        context.insert(entry)
        draftIntention  = ""
        draftGratitude1 = ""
        draftGratitude2 = ""
        draftGratitude3 = ""
        draftVision     = ""
    }

    private func dayLabel(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f.string(from: date)
    }

    private func monthLabel(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM"
        return f.string(from: date)
    }
}
