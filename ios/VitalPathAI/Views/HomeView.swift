//
//  HomeView.swift
//  Redesigned dashboard — dynamic hero, mood check-in, focus grid.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var context
    @Query(sort: \WellnessProfile.createdAt, order: .reverse) private var profiles: [WellnessProfile]
    @Query private var habits: [Habit]

    @State private var selectedMood: Int?
    @State private var moodLogged = false
    @State private var heroScale: CGFloat = 1.0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    heroCard
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                    VStack(alignment: .leading, spacing: 20) {
                        statsRow
                        moodCard
                        focusSection
                        disclaimerText
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("VitalPath AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(
                LinearGradient(
                    colors: [Color.indigo, Color.purple],
                    startPoint: .leading, endPoint: .trailing
                ),
                for: .navigationBar
            )
            .toolbarColorScheme(.dark, for: .navigationBar)
            .scrollContentBackground(.hidden)
        }
    }

    // MARK: — Hero Card

    private var heroCard: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.indigo, Color.purple, Color.pink.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(maxWidth: .infinity)
                .frame(height: 190)
                .shadow(color: .indigo.opacity(0.35), radius: 20, x: 0, y: 10)

            // Decorative circles
            Circle()
                .fill(.white.opacity(0.07))
                .frame(width: 160, height: 160)
                .offset(x: 200, y: -30)
            Circle()
                .fill(.white.opacity(0.05))
                .frame(width: 100, height: 100)
                .offset(x: 240, y: 60)

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(greetingText)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                    Text(profiles.first?.displayName ?? "Friend")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    streakPill
                }

                Spacer(minLength: 12)

                Button {
                    appState.breathingVisible = true
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "wind")
                            .font(.title3)
                        Text("Breathe")
                            .font(.caption2.bold())
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(.white.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .clipped()
    }

    private var streakPill: some View {
        let days = profiles.first?.streakDays ?? 0
        let total = max(1, habits.map(\.targetPerWeek).reduce(0, +))
        let done  = habits.map(\.completedThisWeek).reduce(0, +)
        let pct   = CGFloat(done) / CGFloat(total)
        return HStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .font(.caption)
                .foregroundStyle(.orange)
            Text("\(days) day streak")
                .font(.caption.bold())
                .foregroundStyle(.white)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.25)).frame(height: 4)
                    Capsule().fill(.white).frame(width: geo.size.width * min(1, pct), height: 4)
                }
            }
            .frame(width: 44, height: 4)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.white.opacity(0.15), in: Capsule())
    }

    // MARK: — Stats Row

    private var statsRow: some View {
        HStack(spacing: 10) {
            statPill(
                icon: "flame.fill",
                value: "\(profiles.first?.streakDays ?? 0)",
                label: "Streak",
                color: .orange
            )
            statPill(
                icon: "checkmark.circle.fill",
                value: "\(habits.map(\.completedThisWeek).reduce(0, +))",
                label: "Done today",
                color: .green
            )
            statPill(
                icon: "list.bullet",
                value: "\(habits.count)",
                label: "Habits",
                color: .indigo
            )
        }
    }

    private func statPill(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(color)
            Text(value)
                .font(.headline.bold())
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.55), lineWidth: 1)
        )
        .shadow(color: color.opacity(0.1), radius: 6, x: 0, y: 3)
    }

    // MARK: — Mood Card

    private var moodCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("DAILY CHECK-IN")
                        .font(.caption2.bold())
                        .tracking(1.2)
                        .foregroundStyle(.secondary)
                    Text(moodLogged ? "Feeling noted ✓" : "How are you feeling?")
                        .font(.headline)
                }
                Spacer()
                if moodLogged, let score = selectedMood,
                   let mood = Mood.all.first(where: { $0.score == score }) {
                    Text(mood.emoji).font(.title2)
                        .transition(.scale.combined(with: .opacity))
                }
            }

            HStack(spacing: 6) {
                ForEach(Mood.all) { mood in
                    moodButton(mood)
                }
            }
        }
        .padding(18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.6), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 14, x: 0, y: 6)
    }

    private func moodButton(_ mood: Mood) -> some View {
        let isSelected = selectedMood == mood.score
        return Button { logMood(mood) } label: {
            VStack(spacing: 5) {
                Text(mood.emoji)
                    .font(.system(size: 22))
                    .scaleEffect(isSelected ? 1.2 : 1.0)
                Text(mood.label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(isSelected ? Color.indigo : Color.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                isSelected
                    ? AnyShapeStyle(LinearGradient(
                        colors: [.indigo.opacity(0.15), .purple.opacity(0.08)],
                        startPoint: .top, endPoint: .bottom
                    ))
                    : AnyShapeStyle(Color.clear),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? Color.indigo.opacity(0.5) : Color.clear, lineWidth: 1.5)
            )
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(.plain)
    }

    // MARK: — Focus Grid

    private var focusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Focus")
                .font(.title3.bold())
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                spacing: 12
            ) {
                HomeFocusCard(title: "Mindfulness", subtitle: "5-min body scan",
                              icon: "leaf.fill", tint: .purple) {
                    appState.breathingVisible = true
                }
                HomeFocusCard(title: "Movement", subtitle: "Build your habits",
                              icon: "figure.walk", tint: .pink) {
                    appState.navigate(to: .habits)
                }
                HomeFocusCard(title: "Manifestation", subtitle: "Set intentions",
                              icon: "star.fill", tint: .orange) {
                    appState.navigate(to: .manifest)
                }
                HomeFocusCard(title: "Insights", subtitle: "Sleep & mood data",
                              icon: "sparkles", tint: .indigo) {
                    appState.navigate(to: .insights)
                }
            }
        }
    }

    private var disclaimerText: some View {
        Text("VitalPath offers wellness guidance only. Consult a professional for medical concerns.")
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }

    // MARK: — Actions

    private func logMood(_ mood: Mood) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedMood = mood.score
            moodLogged = true
        }
        let session = WellnessSession(kind: "mood_checkin", title: "\(mood.label) — \(mood.emoji)")
        session.moodAfter = mood.score
        context.insert(session)
        if let profile = profiles.first {
            profile.lastCheckInAt = Date()
        }
    }

    private var greetingText: String {
        let h = Calendar.current.component(.hour, from: Date())
        if h < 12 { return "Good morning ☀️" }
        if h < 18 { return "Good afternoon 🌤️" }
        return "Good evening 🌙"
    }
}

// MARK: - Mood

struct Mood: Identifiable {
    let id = UUID()
    let score: Int
    let emoji: String
    let label: String

    static let all: [Mood] = [
        Mood(score: 5, emoji: "😊", label: "Calm"),
        Mood(score: 4, emoji: "🙂", label: "Okay"),
        Mood(score: 3, emoji: "😐", label: "Tired"),
        Mood(score: 2, emoji: "😟", label: "Stressed"),
        Mood(score: 1, emoji: "😢", label: "Low"),
    ]
}

// MARK: - HomeFocusCard

struct HomeFocusCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(tint.opacity(0.14))
                        .frame(width: 38, height: 38)
                    Image(systemName: icon)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(tint)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 108, alignment: .topLeading)
            .padding(15)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.55), lineWidth: 1)
            )
            .shadow(color: tint.opacity(0.13), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - StreakRing (kept for any reuse)

struct StreakRing: View {
    let days: Int
    let goal: Int
    let done: Int

    var body: some View {
        let progress = min(1.0, Double(done) / Double(max(1, goal)))
        ZStack {
            Circle().stroke(Color.white.opacity(0.5), lineWidth: 10)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(colors: [.orange, .pink, .purple],
                                   startPoint: .top, endPoint: .bottom),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 1.1), value: progress)
            VStack(spacing: 2) {
                Image(systemName: "flame.fill").foregroundStyle(.orange)
                Text("\(days)").font(.system(size: 24, weight: .bold, design: .rounded))
                Text("\(done)/\(goal)").font(.caption2).foregroundStyle(.secondary)
            }
        }
        .frame(width: 100, height: 100)
    }
}
