//
//  Breathwork.swift
//  Breathwork technique catalog + daily / weekly plan generator.
//  Mirrors the web TypeScript `plans.ts` so cross-platform behaviour stays
//  predictable.
//

import Foundation

enum BreathPhase: String, Codable {
    case inhale, hold, exhale, hold2
}

struct BreathworkTechnique: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let summary: String
    /// Phase durations in seconds; same length as `phases`.
    let pattern: [Double]
    let phases: [BreathPhase]
    let rounds: Int
    let benefits: [String]
    let goal: WellnessGoal
}

enum PlanTimeOfDay: String, Codable, CaseIterable {
    case morning, midday, evening, night

    var label: String {
        switch self {
        case .morning: return "Morning"
        case .midday:  return "Midday"
        case .evening: return "Evening"
        case .night:   return "Night"
        }
    }
}

enum PlanKind: String, Codable {
    case breath, movement, mindfulness, hydration, nutrition, reflection, sleep

    var emoji: String {
        switch self {
        case .breath:      return "🌬️"
        case .movement:    return "🏃"
        case .mindfulness: return "🧘"
        case .hydration:   return "💧"
        case .nutrition:   return "🥗"
        case .reflection:  return "📝"
        case .sleep:       return "🌙"
        }
    }

    var label: String {
        switch self {
        case .breath:      return "Breath"
        case .movement:    return "Move"
        case .mindfulness: return "Mind"
        case .hydration:   return "Hydrate"
        case .nutrition:   return "Nourish"
        case .reflection:  return "Reflect"
        case .sleep:       return "Sleep"
        }
    }
}

struct PlanItem: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    var time: PlanTimeOfDay
    var kind: PlanKind
    var title: String
    var summary: String
    var durationMin: Int
    var goal: WellnessGoal
    var techniqueId: String?
    var completed: Bool = false
}

struct DailyPlan: Identifiable, Codable {
    var id: UUID = UUID()
    /// YYYY-MM-DD
    var dateISO: String
    var items: [PlanItem]

    var progress: (done: Int, total: Int, pct: Int) {
        let done = items.filter { $0.completed }.count
        let total = items.count
        let pct = total == 0 ? 0 : Int((Double(done) / Double(total)) * 100.0)
        return (done, total, pct)
    }
}

struct WeeklyPlan: Identifiable, Codable {
    var id: UUID = UUID()
    /// YYYY-MM-DD of the Monday beginning the week.
    var weekStartISO: String
    var focus: [WellnessGoal]
    var days: [DailyPlan]
}

// MARK: - Catalog

enum BreathworkCatalog {
    static let all: [BreathworkTechnique] = [
        BreathworkTechnique(
            id: "box-4-4-4-4",
            name: "Box breathing",
            summary: "Four-count inhale, hold, exhale, hold. Centers focus quickly.",
            pattern: [4, 4, 4, 4],
            phases: [.inhale, .hold, .exhale, .hold2],
            rounds: 6,
            benefits: ["Lowers stress", "Steadies attention", "Pre-meeting reset"],
            goal: .stress
        ),
        BreathworkTechnique(
            id: "four-seven-eight",
            name: "4-7-8 relaxing breath",
            summary: "Long exhale activates the parasympathetic system — ideal before sleep.",
            pattern: [4, 7, 8, 0],
            phases: [.inhale, .hold, .exhale, .hold2],
            rounds: 4,
            benefits: ["Pre-sleep wind-down", "Reduces anxious tension"],
            goal: .sleep
        ),
        BreathworkTechnique(
            id: "coherent-5-5",
            name: "Coherent breathing",
            summary: "Slow 5-in / 5-out rhythm tunes heart-rate variability.",
            pattern: [5, 0, 5, 0],
            phases: [.inhale, .hold, .exhale, .hold2],
            rounds: 12,
            benefits: ["HRV coherence", "Daily grounding"],
            goal: .mindfulness
        ),
        BreathworkTechnique(
            id: "pursed-lip",
            name: "Pursed-lip breathing",
            summary: "In through the nose, out slowly through pursed lips — eases breathlessness.",
            pattern: [2, 0, 4, 0],
            phases: [.inhale, .hold, .exhale, .hold2],
            rounds: 10,
            benefits: ["Post-exertion recovery", "Steady oxygen exchange"],
            goal: .movement
        ),
        BreathworkTechnique(
            id: "extended-exhale",
            name: "Extended exhale",
            summary: "A 4-in / 6-out pattern to gently downshift the nervous system.",
            pattern: [4, 2, 6, 0],
            phases: [.inhale, .hold, .exhale, .hold2],
            rounds: 8,
            benefits: ["Evening calm", "Mindful pause"],
            goal: .mindfulness
        ),
        BreathworkTechnique(
            id: "energizing-bellows",
            name: "Energizing bellows",
            summary: "Fast, short inhales and exhales to kick-start morning alertness.",
            pattern: [1, 0, 1, 0],
            phases: [.inhale, .hold, .exhale, .hold2],
            rounds: 24,
            benefits: ["Wakeful energy", "Clears fog"],
            goal: .movement
        ),
    ]

    static func find(_ id: String?) -> BreathworkTechnique? {
        guard let id else { return nil }
        return all.first(where: { $0.id == id })
    }

    static var `default`: BreathworkTechnique { all[0] }
}

// MARK: - Plan generator

enum PlanBuilder {

    private static let morning: [WellnessGoal: PlanItem] = [
        .stress: PlanItem(time: .morning, kind: .breath,
                          title: "Morning box breathing",
                          summary: "Six rounds of 4-4-4-4 to start calm.",
                          durationMin: 3, goal: .stress, techniqueId: "box-4-4-4-4"),
        .sleep: PlanItem(time: .morning, kind: .mindfulness,
                         title: "Sunlight + stretch",
                         summary: "Two minutes of daylight and a gentle neck stretch anchors the circadian rhythm.",
                         durationMin: 5, goal: .sleep),
        .nutrition: PlanItem(time: .morning, kind: .nutrition,
                             title: "Protein-forward breakfast",
                             summary: "Aim for ~20g of protein + fiber to steady morning energy.",
                             durationMin: 15, goal: .nutrition),
        .movement: PlanItem(time: .morning, kind: .movement,
                            title: "Energizing bellows",
                            summary: "Twenty-four short breaths to wake up the body.",
                            durationMin: 2, goal: .movement, techniqueId: "energizing-bellows"),
        .mindfulness: PlanItem(time: .morning, kind: .mindfulness,
                               title: "Three-breath intention",
                               summary: "Set one kind intention for the day on the third exhale.",
                               durationMin: 2, goal: .mindfulness),
        .hydration: PlanItem(time: .morning, kind: .hydration,
                             title: "Mindful glass of water",
                             summary: "One slow glass before coffee to replace overnight losses.",
                             durationMin: 2, goal: .hydration),
    ]

    private static let midday: [WellnessGoal: PlanItem] = [
        .stress: PlanItem(time: .midday, kind: .breath,
                          title: "2-minute reset",
                          summary: "Coherent 5-5 breathing between tasks.",
                          durationMin: 2, goal: .stress, techniqueId: "coherent-5-5"),
        .sleep: PlanItem(time: .midday, kind: .movement,
                         title: "Stand + stretch",
                         summary: "Five minutes of light movement keeps evening sleepiness earned, not crashed.",
                         durationMin: 5, goal: .sleep),
        .nutrition: PlanItem(time: .midday, kind: .nutrition,
                             title: "Half-plate veggies",
                             summary: "Aim for colour + a palm of protein at lunch.",
                             durationMin: 10, goal: .nutrition),
        .movement: PlanItem(time: .midday, kind: .movement,
                            title: "10-minute walk",
                            summary: "A brisk stroll resets focus and supports metabolism.",
                            durationMin: 10, goal: .movement),
        .mindfulness: PlanItem(time: .midday, kind: .mindfulness,
                               title: "Mindful minute",
                               summary: "Sixty seconds noticing five senses, one at a time.",
                               durationMin: 1, goal: .mindfulness),
        .hydration: PlanItem(time: .midday, kind: .hydration,
                             title: "Refill check-in",
                             summary: "Aim for at least 500ml before lunch is over.",
                             durationMin: 1, goal: .hydration),
    ]

    private static let evening: [WellnessGoal: PlanItem] = [
        .stress: PlanItem(time: .evening, kind: .reflection,
                          title: "Evening unwind",
                          summary: "Write one thing that went well today.",
                          durationMin: 5, goal: .stress),
        .sleep: PlanItem(time: .evening, kind: .breath,
                         title: "4-7-8 wind-down",
                         summary: "Four rounds before lights-out to downshift.",
                         durationMin: 4, goal: .sleep, techniqueId: "four-seven-eight"),
        .nutrition: PlanItem(time: .evening, kind: .nutrition,
                             title: "Gentle dinner",
                             summary: "Finish eating ≥2 hours before bed for better sleep quality.",
                             durationMin: 20, goal: .nutrition),
        .movement: PlanItem(time: .evening, kind: .movement,
                            title: "Pursed-lip recovery",
                            summary: "Ten breaths after any workout to recover smoothly.",
                            durationMin: 3, goal: .movement, techniqueId: "pursed-lip"),
        .mindfulness: PlanItem(time: .evening, kind: .reflection,
                               title: "Gratitude journal",
                               summary: "Three small gratitudes — specific beats grand.",
                               durationMin: 5, goal: .mindfulness),
        .hydration: PlanItem(time: .evening, kind: .hydration,
                             title: "Evening tea",
                             summary: "A caffeine-free cup to end hydrated without disrupting sleep.",
                             durationMin: 5, goal: .hydration),
    ]

    private static let night = PlanItem(
        time: .night, kind: .sleep,
        title: "Screens-off ritual",
        summary: "Dim lights, cool room, book or breathwork — consistency beats duration.",
        durationMin: 10, goal: .sleep
    )

    static func buildDaily(date: Date, goals: [WellnessGoal]) -> DailyPlan {
        let fallback: [WellnessGoal] = [.mindfulness, .movement, .hydration]
        let g = goals.isEmpty ? fallback : goals
        let primary   = g[0]
        let secondary = g.count > 1 ? g[1] : primary
        let tertiary  = g.count > 2 ? g[2] : .hydration

        let items: [PlanItem] = [
            withID(morning[primary]!),
            withID(midday[secondary]!),
            withID(evening[tertiary]!),
            withID(night),
        ]
        return DailyPlan(dateISO: Self.toISO(date), items: items)
    }

    static func buildWeekly(date: Date, goals: [WellnessGoal]) -> WeeklyPlan {
        let start = Self.mondayOf(date)
        let fallback: [WellnessGoal] = [.mindfulness, .movement, .hydration]
        let base = goals.isEmpty ? fallback : goals

        var days: [DailyPlan] = []
        let cal = Calendar.current
        for i in 0..<7 {
            let day = cal.date(byAdding: .day, value: i, to: start) ?? start
            let rotated = Self.rotate(base, by: i)
            days.append(buildDaily(date: day, goals: rotated))
        }
        return WeeklyPlan(
            weekStartISO: Self.toISO(start),
            focus: Array(base.prefix(3)),
            days: days
        )
    }

    // MARK: helpers

    private static func withID(_ item: PlanItem) -> PlanItem {
        var copy = item
        copy.id = UUID()
        copy.completed = false
        return copy
    }

    private static func toISO(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        return f.string(from: date)
    }

    static func mondayOf(_ date: Date) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2 // Monday
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return cal.date(from: comps) ?? date
    }

    private static func rotate<T>(_ arr: [T], by n: Int) -> [T] {
        guard !arr.isEmpty else { return arr }
        let k = ((n % arr.count) + arr.count) % arr.count
        return Array(arr[k...] + arr[..<k])
    }
}
