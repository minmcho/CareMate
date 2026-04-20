//
//  PlanView.swift
//  Daily & weekly wellness plan + breathwork — with full CRUD.
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
    @State private var daily: DailyPlan  = PlanBuilder.buildDaily(date: Date(), goals: [])
    @State private var weekly: WeeklyPlan = PlanBuilder.buildWeekly(date: Date(), goals: [])

    // CRUD state
    @State private var showingItemSheet = false
    @State private var editingItemID: UUID? = nil
    @State private var draftTitle = ""
    @State private var draftSummary = ""
    @State private var draftKind: PlanKind = .mindfulness
    @State private var draftTime: PlanTimeOfDay = .morning
    @State private var draftDuration = 10

    private var profileGoals: [WellnessGoal] {
        profiles.first?.wellnessGoals.compactMap { WellnessGoal(rawValue: $0) } ?? []
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    modeSegment
                    content
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 100)
            }
            .navigationTitle(headerTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .sheet(isPresented: $showingItemSheet) { itemSheet }
            .onAppear { refresh() }
            .scrollContentBackground(.hidden)
        }
    }

    // MARK: — Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if mode == .daily {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 14) {
                    Button {
                        editingItemID = nil
                        resetDraft()
                        showingItemSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    Button { regenerate() } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        } else if mode == .weekly {
            ToolbarItem(placement: .topBarTrailing) {
                Button { regenerate() } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
    }

    // MARK: — Add/Edit Sheet

    private var itemSheet: some View {
        NavigationStack {
            Form {
                Section("Activity") {
                    TextField("Title", text: $draftTitle)
                        .autocorrectionDisabled()
                    TextField("Description (optional)", text: $draftSummary)
                        .autocorrectionDisabled()
                }
                Section("Details") {
                    Picker("Type", selection: $draftKind) {
                        ForEach(PlanKind.allCases, id: \.self) { k in
                            Label(k.label, systemImage: kindIcon(k)).tag(k)
                        }
                    }
                    Picker("Time of day", selection: $draftTime) {
                        ForEach(PlanTimeOfDay.allCases, id: \.self) { t in
                            Text(t.label).tag(t)
                        }
                    }
                    Stepper("Duration: \(draftDuration) min", value: $draftDuration, in: 1...120, step: 5)
                }
            }
            .navigationTitle(editingItemID == nil ? "New Activity" : "Edit Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { showingItemSheet = false }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(editingItemID == nil ? "Add" : "Save") {
                        saveItem()
                        showingItemSheet = false
                    }
                    .fontWeight(.semibold)
                    .disabled(draftTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func saveItem() {
        let trimmed = draftTitle.trimmingCharacters(in: .whitespaces)
        if let id = editingItemID,
           let idx = daily.items.firstIndex(where: { $0.id == id }) {
            daily.items[idx].title      = trimmed
            daily.items[idx].summary    = draftSummary
            daily.items[idx].kind       = draftKind
            daily.items[idx].time       = draftTime
            daily.items[idx].durationMin = draftDuration
        } else {
            let item = PlanItem(
                time: draftTime,
                kind: draftKind,
                title: trimmed,
                summary: draftSummary,
                durationMin: draftDuration,
                goal: .mindfulness
            )
            daily.items.append(item)
        }
    }

    private func populateDraft(from item: PlanItem) {
        draftTitle    = item.title
        draftSummary  = item.summary
        draftKind     = item.kind
        draftTime     = item.time
        draftDuration = item.durationMin
    }

    private func resetDraft() {
        draftTitle    = ""
        draftSummary  = ""
        draftKind     = .mindfulness
        draftTime     = .morning
        draftDuration = 10
    }

    private func kindIcon(_ k: PlanKind) -> String {
        switch k {
        case .breath:      return "wind"
        case .movement:    return "figure.walk"
        case .mindfulness: return "leaf.fill"
        case .hydration:   return "drop.fill"
        case .nutrition:   return "fork.knife"
        case .reflection:  return "book.fill"
        case .sleep:       return "moon.fill"
        }
    }

    // MARK: — Header / Content

    private var headerTitle: String {
        switch mode {
        case .daily:      return "Today's Plan"
        case .weekly:     return "This Week"
        case .breathwork: return "Breathwork"
        }
    }

    private var modeSegment: some View {
        Picker("Mode", selection: $mode) {
            ForEach(Mode.allCases) { m in Text(m.label).tag(m) }
        }
        .pickerStyle(.segmented)
        .padding(.top, 4)
    }

    @ViewBuilder
    private var content: some View {
        switch mode {
        case .daily:      dailyView
        case .weekly:     weeklyView
        case .breathwork: breathworkView
        }
    }

    // MARK: — Daily

    private var dailyView: some View {
        VStack(alignment: .leading, spacing: 14) {
            progressCard
            if daily.items.isEmpty {
                emptyState("No activities yet.\nTap + to add one or use ↺ to generate.")
            } else {
                ForEach(Array(daily.items.enumerated()), id: \.element.id) { idx, item in
                    PlanItemRow(
                        item: item,
                        onToggle: { toggleItem(at: idx) },
                        onStartBreath: item.techniqueId.map { id in { launchTechnique(id) } },
                        onEdit: {
                            populateDraft(from: item)
                            editingItemID = item.id
                            showingItemSheet = true
                        },
                        onDelete: { deleteItem(id: item.id) }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal:   .move(edge: .leading).combined(with: .opacity)
                    ))
                }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: daily.items.count)
    }

    private var progressCard: some View {
        GlassCard {
            HStack(spacing: 16) {
                ProgressRing(pct: daily.progress.pct)
                VStack(alignment: .leading, spacing: 4) {
                    Text("TODAY")
                        .font(.caption2.bold())
                        .tracking(1.4)
                        .foregroundStyle(.secondary)
                    Text("\(daily.progress.done) of \(daily.progress.total) complete")
                        .font(.title3.bold())
                    Text(focusLine)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var focusLine: String {
        let goals = profileGoals.prefix(3).map { $0.rawValue.capitalized }
        return goals.isEmpty ? "Wellness balance" : "Focus: " + goals.joined(separator: " · ")
    }

    private func toggleItem(at index: Int) {
        withAnimation { daily.items[index].completed.toggle() }
    }

    private func deleteItem(id: UUID) {
        withAnimation { daily.items.removeAll { $0.id == id } }
    }

    // MARK: — Weekly

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
            HStack(spacing: 14) {
                DayBadge(iso: day.dateISO, isToday: isToday)
                VStack(alignment: .leading, spacing: 4) {
                    Text(Self.weekdayLabel(day.dateISO))
                        .font(.subheadline.bold())
                    Text(day.items.map { $0.kind.emoji }.joined(separator: "  "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(day.progress.done)/\(day.progress.total)")
                        .font(.caption2).foregroundStyle(.secondary)
                    ProgressView(value: Double(day.progress.pct) / 100.0)
                        .tint(LinearGradient(colors: [.indigo, .purple],
                                             startPoint: .leading, endPoint: .trailing))
                        .frame(width: 60)
                }
            }
        }
    }

    // MARK: — Breathwork

    private var breathworkView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose a breathing pattern")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.leading, 2)
            ForEach(BreathworkCatalog.all) { tech in
                GlassCard {
                    HStack(alignment: .top, spacing: 14) {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(LinearGradient(colors: [.indigo, .purple],
                                                 startPoint: .top, endPoint: .bottom))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: "wind").foregroundStyle(.white)
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
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(tech.benefits, id: \.self) { b in
                                        Text(b)
                                            .font(.caption2.bold())
                                            .padding(.horizontal, 8).padding(.vertical, 3)
                                            .background(Color.secondary.opacity(0.1), in: Capsule())
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        Button { launchTechnique(tech.id) } label: {
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

    // MARK: — Helpers

    private func emptyState(_ message: String) -> some View {
        Text(message)
            .font(.callout)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
    }

    private func refresh() {
        let today = Date()
        let goals = profileGoals
        if daily.dateISO != PlanBuilder.todayISO() || daily.items.isEmpty {
            daily = PlanBuilder.buildDaily(date: today, goals: goals)
        }
        let mondayISO = PlanBuilder.isoString(PlanBuilder.mondayOf(today))
        if weekly.weekStartISO != mondayISO {
            weekly = PlanBuilder.buildWeekly(date: today, goals: goals)
        }
    }

    private func regenerate() {
        let goals = profileGoals
        withAnimation {
            if mode == .weekly {
                weekly = PlanBuilder.buildWeekly(date: Date(), goals: goals)
            } else {
                daily = PlanBuilder.buildDaily(date: Date(), goals: goals)
            }
        }
    }

    private func launchTechnique(_ id: String) {
        appState.breathingTechniqueID = id
        appState.breathingVisible = true
    }

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

// MARK: - Plan Item Row

private struct PlanItemRow: View {
    let item: PlanItem
    let onToggle: () -> Void
    let onStartBreath: (() -> Void)?
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        GlassCard {
            HStack(alignment: .top, spacing: 14) {
                Button(action: onToggle) {
                    Image(systemName: item.completed ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(item.completed ? .green : .secondary)
                        .animation(.spring(response: 0.25), value: item.completed)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text(item.time.label.uppercased())
                            .font(.caption2.bold())
                            .tracking(1.1)
                            .foregroundStyle(.secondary)
                        Text("·").foregroundStyle(.tertiary)
                        Text("\(item.kind.emoji) \(item.kind.label)")
                            .font(.caption2.bold())
                            .foregroundStyle(.indigo)
                    }
                    Text(item.title)
                        .font(.subheadline.bold())
                        .strikethrough(item.completed, color: .secondary)
                        .foregroundStyle(item.completed ? .secondary : .primary)
                    if !item.summary.isEmpty {
                        Text(item.summary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
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
        .contextMenu {
            Button { onEdit() } label: { Label("Edit", systemImage: "pencil") }
            Button(role: .destructive) { onDelete() } label: { Label("Delete", systemImage: "trash") }
        }
    }
}

// MARK: - Progress Ring

private struct ProgressRing: View {
    let pct: Int

    var body: some View {
        ZStack {
            Circle().stroke(Color.secondary.opacity(0.18), lineWidth: 7)
            Circle()
                .trim(from: 0, to: CGFloat(pct) / 100.0)
                .stroke(
                    LinearGradient(colors: [.indigo, .purple],
                                   startPoint: .top, endPoint: .bottom),
                    style: StrokeStyle(lineWidth: 7, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.8), value: pct)
            Text("\(pct)%")
                .font(.subheadline.bold())
        }
        .frame(width: 64, height: 64)
    }
}

// MARK: - Day Badge

private struct DayBadge: View {
    let iso: String
    let isToday: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(
                isToday
                    ? AnyShapeStyle(LinearGradient(colors: [.indigo, .purple],
                                                   startPoint: .top, endPoint: .bottom))
                    : AnyShapeStyle(Color.white.opacity(0.65))
            )
            .frame(width: 44, height: 44)
            .overlay(
                Text("\(dayNumber())")
                    .font(.headline)
                    .foregroundStyle(isToday ? Color.white : Color.primary)
            )
    }

    private func dayNumber() -> Int {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        let d = f.date(from: iso) ?? Date()
        return Calendar.current.component(.day, from: d)
    }
}

// MARK: - PlanBuilder extensions

extension PlanBuilder {
    static func todayISO() -> String { isoString(Date()) }

    static func isoString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f.string(from: date)
    }
}

private extension PlanKind {
    static var allCases: [PlanKind] {
        [.breath, .movement, .mindfulness, .hydration, .nutrition, .reflection, .sleep]
    }
}
