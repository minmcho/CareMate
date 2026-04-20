//
//  HomeView.swift
//  Dashboard with streak ring, daily check-in, and today's focus.
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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    greeting
                    streakCard
                    dailyCheckIn
                    focusGrid
                    disclaimer
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 120)
            }
            .navigationTitle("VitalPath")
            .scrollContentBackground(.hidden)
        }
    }

    // MARK: - Sections

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(greetingText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(profiles.first?.displayName ?? "Friend")
                .font(.system(size: 28, weight: .bold, design: .rounded))
        }
    }

    private var streakCard: some View {
        GlassCard {
            HStack(spacing: 20) {
                StreakRing(days: profiles.first?.streakDays ?? 0,
                           goal: max(1, habits.map(\.targetPerWeek).reduce(0, +)),
                           done: habits.map(\.completedThisWeek).reduce(0, +))
                VStack(alignment: .leading, spacing: 6) {
                    Text("STREAK").font(.caption2).foregroundStyle(.secondary)
                    Text("\(profiles.first?.streakDays ?? 0) days")
                        .font(.title3.bold())
                    Button {
                        appState.breathingVisible = true
                    } label: {
                        Label("Start 2-min breathing", systemImage: "wind")
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .tint(.indigo)
                }
            }
        }
    }

    private var dailyCheckIn: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("DAILY CHECK-IN")
                    .font(.caption2).foregroundStyle(.secondary)
                Text(moodLogged ? "Mood logged!" : "How are you feeling?")
                    .font(.headline)
                HStack(spacing: 8) {
                    ForEach(Mood.all) { mood in
                        Button {
                            logMood(mood)
                        } label: {
                            VStack(spacing: 4) {
                                Text(mood.emoji).font(.title2)
                                Text(mood.label).font(.caption2)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                selectedMood == mood.score
                                    ? AnyShapeStyle(LinearGradient(colors: [.indigo, .purple], startPoint: .top, endPoint: .bottom).opacity(0.3))
                                    : AnyShapeStyle(Color.white.opacity(0.001)),
                                in: RoundedRectangle(cornerRadius: 16)
                            )
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(selectedMood == mood.score ? Color.indigo : Color.clear, lineWidth: 2)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func logMood(_ mood: Mood) {
        withAnimation(.spring(response: 0.3)) {
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

    private var focusGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            Button { appState.breathingVisible = true } label: {
                FocusCard(title: "Mindfulness", subtitle: "5-min body scan", icon: "leaf.fill", tint: .purple)
            }
            .buttonStyle(.plain)

            Button { appState.selectedTab = .habits } label: {
                FocusCard(title: "Movement", subtitle: "Stretch flow", icon: "figure.walk", tint: .pink)
            }
            .buttonStyle(.plain)

            Button { appState.selectedTab = .vision } label: {
                FocusCard(title: "Nutrition", subtitle: "Plate method", icon: "leaf", tint: .green)
            }
            .buttonStyle(.plain)

            Button { appState.selectedTab = .insights } label: {
                FocusCard(title: "Sleep", subtitle: "Wind-down", icon: "moon.stars.fill", tint: .indigo)
            }
            .buttonStyle(.plain)
        }
    }

    private var disclaimer: some View {
        Text("VitalPath offers wellness guidance only. For medical concerns, consult a licensed professional.")
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .multilineTextAlignment(.center)
            .padding(.top, 8)
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good morning" }
        if hour < 18 { return "Good afternoon" }
        return "Good evening"
    }
}

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
        Mood(score: 1, emoji: "😢", label: "Low")
    ]
}

struct FocusCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let tint: Color

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(tint.opacity(0.18))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .foregroundStyle(tint)
                }
                Text(title).font(.headline)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct StreakRing: View {
    let days: Int
    let goal: Int
    let done: Int

    var body: some View {
        let progress = min(1.0, Double(done) / Double(max(1, goal)))
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.6), lineWidth: 12)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(colors: [.orange, .pink, .purple],
                                   startPoint: .top, endPoint: .bottom),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 1.1), value: progress)
            VStack(spacing: 2) {
                Image(systemName: "flame.fill").foregroundStyle(.orange)
                Text("\(days)").font(.system(size: 28, weight: .bold, design: .rounded))
                Text("\(done)/\(goal)")
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
        .frame(width: 120, height: 120)
    }
}
