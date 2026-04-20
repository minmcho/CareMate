//
//  HabitsView.swift
//  Habit tracking with streaks and "freeze" rest-day.
//

import SwiftUI
import SwiftData

struct HabitsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Habit.title) private var habits: [Habit]
    @Query private var profiles: [WellnessProfile]

    @State private var showingAdd = false
    @State private var draftTitle = ""
    @State private var draftGoal: WellnessGoal = .mindfulness
    @State private var draftTarget = 3

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    summary
                    ForEach(habits) { habit in
                        HabitRow(habit: habit, onToggle: { toggleToday(habit) })
                    }
                    if habits.isEmpty {
                        Text("No habits yet. Tap + to add one.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(40)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 80)
            }
            .navigationTitle("Habits")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                addSheet
            }
            .scrollContentBackground(.hidden)
        }
    }

    private var summary: some View {
        let freezeAvailable = profiles.first?.streakFreezeAvailable ?? false
        return GlassCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("STREAK").font(.caption2).foregroundStyle(.secondary)
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill").foregroundStyle(.orange)
                        Text("\(profiles.first?.streakDays ?? 0) days")
                            .font(.title.bold())
                    }
                }
                Spacer()
                Button {
                    freezeStreak()
                } label: {
                    Label(freezeAvailable ? "Freeze" : "Frozen", systemImage: "snowflake")
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .disabled(!freezeAvailable)
            }
        }
    }

    private func freezeStreak() {
        guard let profile = profiles.first, profile.streakFreezeAvailable else { return }
        profile.streakFreezeAvailable = false
        let session = WellnessSession(kind: "streak_freeze", title: "Rest day — streak preserved")
        context.insert(session)
    }

    private var addSheet: some View {
        NavigationStack {
            Form {
                Section("Habit") {
                    TextField("Title", text: $draftTitle)
                    Picker("Goal", selection: $draftGoal) {
                        ForEach(WellnessGoal.allCases) { g in
                            Text(g.rawValue.capitalized).tag(g)
                        }
                    }
                    Stepper("Target: \(draftTarget)/week", value: $draftTarget, in: 1...7)
                }
            }
            .navigationTitle("New habit")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        addHabit()
                        showingAdd = false
                    }
                    .disabled(draftTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { showingAdd = false }
                }
            }
        }
    }

    private func addHabit() {
        let habit = Habit(
            title: draftTitle.trimmingCharacters(in: .whitespaces),
            emoji: draftGoal.emoji,
            goal: draftGoal,
            targetPerWeek: draftTarget
        )
        context.insert(habit)
        draftTitle = ""
        draftGoal = .mindfulness
        draftTarget = 3
    }

    private func toggleToday(_ habit: Habit) {
        let today = ISO8601DateFormatter().string(from: Date()).prefix(10)
        if let idx = habit.history.firstIndex(of: String(today)) {
            habit.history.remove(at: idx)
            habit.completedThisWeek = max(0, habit.completedThisWeek - 1)
        } else {
            habit.history.append(String(today))
            habit.completedThisWeek += 1
            if let profile = profiles.first {
                profile.streakDays += 1
                profile.lastCheckInAt = Date()
            }
        }
    }
}

struct HabitRow: View {
    let habit: Habit
    let onToggle: () -> Void

    var body: some View {
        let pct = min(1.0, Double(habit.completedThisWeek) / Double(max(1, habit.targetPerWeek)))
        return GlassCard {
            HStack(spacing: 14) {
                Button(action: onToggle) {
                    Text(habit.emoji)
                        .font(.title2)
                        .frame(width: 48, height: 48)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 6) {
                    Text(habit.title).font(.headline)
                    Text(habit.goal.uppercased()).font(.caption2).foregroundStyle(.secondary)
                    ProgressView(value: pct)
                        .tint(LinearGradient(colors: [.indigo, .purple, .pink],
                                             startPoint: .leading, endPoint: .trailing))
                }
            }
        }
    }
}
