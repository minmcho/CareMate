//
//  InsightsView.swift
//  Sleep, mood, AI insights, and challenges dashboard.
//

import SwiftUI
import SwiftData

struct InsightsView: View {
    @Environment(AppState.self) private var appState
    @Query private var profiles: [WellnessProfile]

    enum Tab: String, CaseIterable, Identifiable {
        case overview, sleep, mood, challenges
        var id: String { rawValue }
        var label: String {
            switch self {
            case .overview:   return "Overview"
            case .sleep:      return "Sleep"
            case .mood:       return "Mood"
            case .challenges: return "Challenges"
            }
        }
    }

    @State private var tab: Tab = .overview
    @State private var showSleepForm = false
    @State private var showMoodForm = false
    @State private var sleepHours: Double = 7.0
    @State private var moodScore: Int = 3
    @State private var moodEnergy: Int = 3

    @State private var sleepLogs: [SleepEntry] = []
    @State private var moodEntries: [MoodRecord] = []
    @State private var challenges: [WellnessChallenge] = WellnessChallenge.defaults

    private let moodEmojis = ["😔", "😕", "🙂", "😊", "😄"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    tabPicker
                    switch tab {
                    case .overview:   overviewSection
                    case .sleep:      sleepSection
                    case .mood:       moodSection
                    case .challenges: challengesSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 120)
            }
            .navigationTitle("Insights")
            .scrollContentBackground(.hidden)
        }
    }

    private var tabPicker: some View {
        Picker("Tab", selection: $tab) {
            ForEach(Tab.allCases) { t in
                Text(t.label).tag(t)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: Overview

    private var overviewSection: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                statCard(icon: "moon.fill", value: sleepAvgLabel, label: "Avg Sleep", color: .indigo)
                statCard(icon: "brain.filled.head.profile", value: moodAvgLabel, label: "Avg Mood", color: .green)
                statCard(icon: "chart.line.uptrend.xyaxis", value: "\(profiles.first?.streakDays ?? 0)", label: "Streak", color: .orange)
            }

            GlassCard {
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(LinearGradient(colors: [.indigo, .purple], startPoint: .top, endPoint: .bottom))
                        .frame(width: 44, height: 44)
                        .overlay(Image(systemName: "sparkles").foregroundStyle(.white))
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("AI Insight").font(.headline)
                            Text("DeepSeek R1")
                                .font(.caption2.bold())
                                .padding(.horizontal, 8).padding(.vertical, 2)
                                .background(Color.indigo.opacity(0.12), in: Capsule())
                                .foregroundStyle(.indigo)
                        }
                        Text(insightText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }
            }

            HStack(spacing: 12) {
                Button { showSleepForm = true; tab = .sleep } label: {
                    Label("Log Sleep", systemImage: "moon.fill")
                        .font(.caption.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(LinearGradient(colors: [.indigo, .purple], startPoint: .leading, endPoint: .trailing), in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.white)
                }
                Button { showMoodForm = true; tab = .mood } label: {
                    Label("Log Mood", systemImage: "brain.filled.head.profile")
                        .font(.caption.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(LinearGradient(colors: [.green, .teal], startPoint: .leading, endPoint: .trailing), in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Sleep

    private var sleepSection: some View {
        VStack(spacing: 14) {
            HStack {
                Text("Sleep Log").font(.headline)
                Spacer()
                Button { showSleepForm.toggle() } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.indigo)
                }
            }

            if showSleepForm {
                GlassCard {
                    VStack(spacing: 12) {
                        HStack {
                            Text("Hours:").font(.subheadline)
                            Slider(value: $sleepHours, in: 0...14, step: 0.5)
                            Text(String(format: "%.1f", sleepHours))
                                .font(.subheadline.bold()).frame(width: 36)
                        }
                        Button {
                            let entry = SleepEntry(
                                hours: sleepHours,
                                date: Date()
                            )
                            sleepLogs.insert(entry, at: 0)
                            showSleepForm = false
                        } label: {
                            Text("Save")
                                .font(.caption.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(.indigo, in: RoundedRectangle(cornerRadius: 12))
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if sleepLogs.isEmpty {
                Text("No sleep data yet. Log your first night.")
                    .font(.callout).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity).padding(30)
            } else {
                ForEach(sleepLogs) { log in
                    GlassCard {
                        HStack {
                            Image(systemName: "moon.fill")
                                .font(.title2).foregroundStyle(.indigo)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(log.dateLabel).font(.subheadline.bold())
                                Text(String(format: "%.1f hours", log.hours))
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(log.quality)%")
                                .font(.title3.bold())
                        }
                    }
                }
            }
        }
    }

    // MARK: Mood

    private var moodSection: some View {
        VStack(spacing: 14) {
            HStack {
                Text("Mood Check-in").font(.headline)
                Spacer()
                Button { showMoodForm.toggle() } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.green)
                }
            }

            if showMoodForm {
                GlassCard {
                    VStack(spacing: 16) {
                        Text("How are you feeling?").font(.subheadline.bold())
                        HStack(spacing: 12) {
                            ForEach(0..<5) { i in
                                Button { moodScore = i + 1 } label: {
                                    Text(moodEmojis[i])
                                        .font(.title)
                                        .scaleEffect(moodScore == i + 1 ? 1.2 : 1.0)
                                        .opacity(moodScore == i + 1 ? 1.0 : 0.5)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        HStack {
                            Text("Energy:").font(.caption)
                            ForEach(1..<6) { e in
                                Button { moodEnergy = e } label: {
                                    Image(systemName: "bolt.fill")
                                        .foregroundStyle(e <= moodEnergy ? Color.orange : Color.secondary.opacity(0.3))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        Button {
                            let entry = MoodRecord(score: moodScore, energy: moodEnergy, date: Date())
                            moodEntries.insert(entry, at: 0)
                            showMoodForm = false
                        } label: {
                            Text("Save")
                                .font(.caption.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(.green, in: RoundedRectangle(cornerRadius: 12))
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if moodEntries.isEmpty {
                Text("No mood data yet. Log how you feel.")
                    .font(.callout).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity).padding(30)
            } else {
                ForEach(moodEntries) { entry in
                    GlassCard {
                        HStack(spacing: 12) {
                            Text(moodEmojis[entry.score - 1]).font(.title)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.dateLabel).font(.subheadline.bold())
                                HStack(spacing: 2) {
                                    ForEach(1..<6) { e in
                                        Image(systemName: "bolt.fill")
                                            .font(.caption2)
                                            .foregroundStyle(e <= entry.energy ? Color.orange : Color.secondary.opacity(0.2))
                                    }
                                }
                            }
                            Spacer()
                        }
                    }
                }
            }
        }
    }

    // MARK: Challenges

    private var challengesSection: some View {
        VStack(spacing: 14) {
            Text("Challenges").font(.headline).frame(maxWidth: .infinity, alignment: .leading)
            ForEach(Array(challenges.enumerated()), id: \.element.id) { idx, ch in
                GlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 12) {
                            Text(ch.icon).font(.title)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(ch.title).font(.headline)
                                Text(ch.description)
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 0)
                            Button {
                                challenges[idx].joined.toggle()
                            } label: {
                                Text(ch.joined ? "Joined" : "Join")
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 12).padding(.vertical, 6)
                                    .background(
                                        ch.joined
                                        ? AnyShapeStyle(Color.green.opacity(0.15))
                                        : AnyShapeStyle(LinearGradient(colors: [.indigo, .purple], startPoint: .leading, endPoint: .trailing)),
                                        in: Capsule()
                                    )
                                    .foregroundStyle(ch.joined ? Color.green : Color.white)
                            }
                            .buttonStyle(.plain)
                        }
                        if ch.joined {
                            ProgressView(value: Double(ch.progressDays) / Double(ch.targetDays))
                                .tint(.green)
                            Text("\(ch.progressDays)/\(ch.targetDays) days")
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: Helpers

    private func statCard(icon: String, value: String, label: String, color: Color) -> some View {
        GlassCard {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3).foregroundStyle(color)
                Text(value).font(.title3.bold())
                Text(label).font(.caption2).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var sleepAvgLabel: String {
        guard !sleepLogs.isEmpty else { return "—" }
        let avg = sleepLogs.reduce(0.0) { $0 + $1.hours } / Double(sleepLogs.count)
        return String(format: "%.1fh", avg)
    }

    private var moodAvgLabel: String {
        guard !moodEntries.isEmpty else { return "—" }
        let avg = Double(moodEntries.reduce(0) { $0 + $1.score }) / Double(moodEntries.count)
        return String(format: "%.1f", avg)
    }

    private var insightText: String {
        if sleepLogs.isEmpty && moodEntries.isEmpty {
            return "Start logging sleep and mood to receive AI-powered wellness insights tailored to your patterns."
        }
        return "Based on your recent data, your wellness rhythm looks steady. Keep up your mindful breathing practice and aim for consistent sleep times."
    }
}

// MARK: - Data models

struct SleepEntry: Identifiable {
    let id = UUID()
    let hours: Double
    let date: Date
    var quality: Int {
        let totalMin = Int(hours * 60)
        var q = 0
        if totalMin >= 420 && totalMin <= 540 { q += 40 }
        else if totalMin >= 300 { q += 25 }
        else if totalMin > 0 { q += 10 }
        q += Swift.min(30, totalMin / 15)
        q += 20
        return Swift.min(q, 100)
    }
    var dateLabel: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }
}

struct MoodRecord: Identifiable {
    let id = UUID()
    let score: Int
    let energy: Int
    let date: Date
    var dateLabel: String {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d, h:mm a"
        return f.string(from: date)
    }
}

struct WellnessChallenge: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let category: String
    let icon: String
    let targetDays: Int
    var joined: Bool = false
    var progressDays: Int = 0

    static let defaults: [WellnessChallenge] = [
        WellnessChallenge(title: "7-Day Mindfulness", description: "Meditate or breathe mindfully every day for a week.", category: "mindfulness", icon: "🧘", targetDays: 7),
        WellnessChallenge(title: "Hydration Hero", description: "Drink 8 glasses of water daily for 5 days.", category: "hydration", icon: "💧", targetDays: 5),
        WellnessChallenge(title: "Sleep Reset", description: "Follow a screens-off ritual for 7 consecutive nights.", category: "sleep", icon: "🌙", targetDays: 7),
        WellnessChallenge(title: "Move More Month", description: "Log 30 minutes of movement 5 days per week.", category: "movement", icon: "🏃", targetDays: 30),
        WellnessChallenge(title: "Gratitude Streak", description: "Write 3 gratitudes daily for 14 days.", category: "mindfulness", icon: "📝", targetDays: 14),
        WellnessChallenge(title: "Balanced Plate Week", description: "Eat veggies at every meal for 7 days.", category: "nutrition", icon: "🥗", targetDays: 7),
    ]
}
