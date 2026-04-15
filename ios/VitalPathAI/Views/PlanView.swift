//
//  PlanView.swift
//  Daily & weekly wellness plan + breathwork library.
//

import SwiftUI
import SwiftData

struct PlanView: View {
    @Environment(AppState.self) private var appState
    @Query private var profiles: [WellnessProfile]

    enum Mode: String, CaseIterable, Identifiable {
        case daily, weekly, breathwork
        var id: String { rawValue }
        var label: String {
            switch self {
            case .daily:      return "Today"
            case .weekly:     return "Week"
            case .breathwork: return "Breathwork"
            }
        }
    }

    @State private var mode: Mode = .daily
    @State private var daily: DailyPlan = PlanBuilder.buildDaily(
        date: Date(), goals: []
    )
    @State private var weekly: WeeklyPlan = PlanBuilder.buildWeekly(
        date: Date(), goals: []
    )

    private var profileGoals: [WellnessGoal] {
        profiles.first?.wellnessGoals.compactMap { WellnessGoal(rawValue: $0) } ?? []
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    modeSwitch
                    content
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 120)
            }
            .navigationTitle(headerTitle)
            .toolbar {
                if mode != .breathwork {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            regenerate()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
            }
            .onAppear { refresh() }
            .scrollContentBackground(.hidden)
        }
    }

    private var headerTitle: String {
        switch mode {
        case .daily:      return "Today's plan"
        case .weekly:     return "This week"
        case .breathwork: return "Breathwork"
        }
    }

    private var modeSwitch: some View {
        Picker("Mode", selection: $mode) {
            ForEach(Mode.allCases) { m in
                Text(m.label).tag(m)
            }
        }
        .pickerStyle(.segmented)
    }

    @ViewBuilder
    private var content: some View {
        switch mode {
        case .daily:      dailyView
        case .weekly:     weeklyView
        case .breathwork: breathworkView
        }
    }

    // MARK: Daily

    private var dailyView: some View {
        VStack(alignment: .leading, spacing: 14) {
            GlassCard {
                HStack(spacing: 14) {
                    ProgressRing(pct: daily.progress.pct)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("TODAY")
                            .font(.caption2.bold())
                            .tracking(1.4)
                            .foregroundStyle(.secondary)
                        Text("\(daily.progress.done)/\(daily.progress.total) complete")
                            .font(.title3.bold())
                        Text(focusLine)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }
            }
            if daily.items.isEmpty {
                Text("Tap refresh to build today's plan.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(30)
            } else {
                ForEach(Array(daily.items.enumerated()), id: \.element.id) { idx, item in
                    PlanItemRow(
                        item: item,
                        onToggle: { toggle(at: idx) },
                        onStartBreath: item.techniqueId.map { id in
                            { launchTechnique(id) }
                        }
                    )
                }
            }
        }
    }

    private var focusLine: String {
        let goals = profileGoals.prefix(3).map { $0.rawValue.capitalized }
        return goals.isEmpty ? "Wellness balance" : "Focus: " + goals.joined(separator: " · ")
    }

    // MARK: Weekly

    private var weeklyView: some View {
        VStack(spacing: 12) {
            ForEach(weekly.days) { day in
                weekRow(day)
            }
        }
    }

    private func weekRow(_ day: DailyPlan) -> some View {
        let isToday = day.dateISO == PlanBuilder.todayISO()
        return GlassCard {
            HStack(spacing: 12) {
                DayBadge(iso: day.dateISO, isToday: isToday)
                VStack(alignment: .leading, spacing: 3) {
                    Text(Self.weekdayLabel(day.dateISO))
                        .font(.subheadline.bold())
                    Text(day.items.map { $0.kind.emoji }.joined(separator: "  "))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(day.progress.done)/\(day.progress.total)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    ProgressView(value: Double(day.progress.pct) / 100.0)
                        .tint(LinearGradient(colors: [.indigo, .purple],
                                             startPoint: .leading, endPoint: .trailing))
                        .frame(width: 64)
                }
            }
        }
    }

    // MARK: Breathwork

    private var breathworkView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose a pattern")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)
            ForEach(BreathworkCatalog.all) { tech in
                GlassCard {
                    HStack(alignment: .top, spacing: 12) {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(LinearGradient(colors: [.indigo, .purple],
                                                 startPoint: .top, endPoint: .bottom))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: "wind")
                                    .foregroundStyle(.white)
                            )
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Text(tech.name).font(.headline)
                                Text(tech.pattern.map { String(format: "%.0f", $0) }.joined(separator: "·"))
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 8).padding(.vertical, 2)
                                    .background(Color.indigo.opacity(0.12), in: Capsule())
                                    .foregroundStyle(.indigo)
                            }
                            Text(tech.summary)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            HStack(spacing: 6) {
                                ForEach(tech.benefits, id: \.self) { b in
                                    Text(b)
                                        .font(.caption2.bold())
                                        .padding(.horizontal, 8).padding(.vertical, 2)
                                        .background(Color.secondary.opacity(0.12), in: Capsule())
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        Spacer(minLength: 0)
                        Button {
                            launchTechnique(tech.id)
                        } label: {
                            Image(systemName: "play.fill")
                                .font(.caption.bold())
                                .padding(10)
                                .background(
                                    LinearGradient(colors: [.indigo, .purple],
                                                   startPoint: .leading, endPoint: .trailing),
                                    in: Circle()
                                )
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: Intents

    private func refresh() {
        let today = Date()
        let goals = profileGoals
        if daily.dateISO != PlanBuilder.todayISO() || daily.items.isEmpty {
            daily = PlanBuilder.buildDaily(date: today, goals: goals)
        }
        let monday = PlanBuilder.mondayOf(today)
        let mondayISO = PlanBuilder.isoString(monday)
        if weekly.weekStartISO != mondayISO {
            weekly = PlanBuilder.buildWeekly(date: today, goals: goals)
        }
    }

    private func regenerate() {
        let today = Date()
        let goals = profileGoals
        if mode == .weekly {
            weekly = PlanBuilder.buildWeekly(date: today, goals: goals)
        } else {
            daily = PlanBuilder.buildDaily(date: today, goals: goals)
        }
    }

    private func toggle(at index: Int) {
        daily.items[index].completed.toggle()
    }

    private func launchTechnique(_ id: String) {
        appState.breathingTechniqueID = id
        appState.breathingVisible = true
    }

    // MARK: helpers

    private static func weekdayLabel(_ iso: String) -> String {
        let inFmt = DateFormatter()
        inFmt.dateFormat = "yyyy-MM-dd"
        inFmt.locale = Locale(identifier: "en_US_POSIX")
        let date = inFmt.date(from: iso) ?? Date()
        let outFmt = DateFormatter()
        outFmt.dateFormat = "EEEE, MMM d"
        return outFmt.string(from: date)
    }
}

// MARK: - Row + helpers

private struct PlanItemRow: View {
    let item: PlanItem
    let onToggle: () -> Void
    let onStartBreath: (() -> Void)?

    var body: some View {
        GlassCard {
            HStack(alignment: .top, spacing: 12) {
                Button(action: onToggle) {
                    Image(systemName: item.completed ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(item.completed ? .green : .secondary)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text(item.time.label.uppercased())
                            .font(.caption2.bold())
                            .tracking(1.2)
                            .foregroundStyle(.secondary)
                        Text("·").foregroundStyle(.tertiary)
                        Text("\(item.kind.emoji) \(item.kind.label)")
                            .font(.caption2.bold())
                            .foregroundStyle(.indigo)
                    }
                    Text(item.title)
                        .font(.headline)
                        .strikethrough(item.completed, color: .secondary)
                        .foregroundStyle(item.completed ? .secondary : .primary)
                    Text(item.summary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 12) {
                        Label("\(item.durationMin) min", systemImage: "clock")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        if let start = onStartBreath {
                            Button(action: start) {
                                Label("Start breathwork", systemImage: "wind")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.indigo)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                Spacer(minLength: 0)
            }
        }
    }
}

private struct ProgressRing: View {
    let pct: Int

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: 6)
            Circle()
                .trim(from: 0, to: CGFloat(pct) / 100.0)
                .stroke(
                    LinearGradient(colors: [.indigo, .purple],
                                   startPoint: .top, endPoint: .bottom),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            Text("\(pct)%")
                .font(.subheadline.bold())
        }
        .frame(width: 64, height: 64)
    }
}

private struct DayBadge: View {
    let iso: String
    let isToday: Bool

    var body: some View {
        let day = dayNumber()
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(
                isToday
                ? AnyShapeStyle(LinearGradient(colors: [.indigo, .purple],
                                               startPoint: .top, endPoint: .bottom))
                : AnyShapeStyle(Color.white.opacity(0.7))
            )
            .frame(width: 44, height: 44)
            .overlay(
                Text("\(day)")
                    .font(.headline)
                    .foregroundStyle(isToday ? Color.white : Color.primary)
            )
    }

    private func dayNumber() -> Int {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        let date = f.date(from: iso) ?? Date()
        return Calendar.current.component(.day, from: date)
    }
}

// MARK: - Small extras on PlanBuilder used by the view

extension PlanBuilder {
    static func todayISO() -> String {
        isoString(Date())
    }

    static func isoString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f.string(from: date)
    }
}
