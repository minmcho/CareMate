//
//  Models.swift
//  SwiftData schema — mirrors the backend SQLAlchemy models.
//

import Foundation
import SwiftData

enum AppLanguage: String, Codable, CaseIterable, Identifiable {
    case en, my, th, zh, ja, ko
    var id: String { rawValue }
    var label: String {
        switch self {
        case .en: return "English"
        case .my: return "မြန်မာ"
        case .th: return "ไทย"
        case .zh: return "中文"
        case .ja: return "日本語"
        case .ko: return "한국어"
        }
    }
}

enum WellnessGoal: String, Codable, CaseIterable, Identifiable {
    case stress, sleep, nutrition, movement, mindfulness, hydration
    var id: String { rawValue }
    var emoji: String {
        switch self {
        case .stress: return "🌿"
        case .sleep: return "🌙"
        case .nutrition: return "🥗"
        case .movement: return "🏃"
        case .mindfulness: return "🧘"
        case .hydration: return "💧"
        }
    }
}

enum AgentKind: String, Codable {
    case llama4, qwen35, qwen35vl, fallback
}

@Model
final class WellnessProfile {
    @Attribute(.unique) var id: UUID
    var displayName: String
    var preferredLanguage: String
    var dietaryPreferences: [String]
    var wellnessGoals: [String]
    var comforts: [String]
    var avoid: [String]
    var streakDays: Int
    var streakFreezeAvailable: Bool
    var lastCheckInAt: Date?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        displayName: String,
        preferredLanguage: String = "en",
        wellnessGoals: [String] = []
    ) {
        self.id = id
        self.displayName = displayName
        self.preferredLanguage = preferredLanguage
        self.dietaryPreferences = []
        self.wellnessGoals = wellnessGoals
        self.comforts = []
        self.avoid = []
        self.streakDays = 0
        self.streakFreezeAvailable = true
        self.lastCheckInAt = nil
        self.createdAt = Date()
    }
}

@Model
final class WellnessSession {
    @Attribute(.unique) var id: UUID
    var kind: String
    var title: String
    var summary: String
    var tags: [String]
    var durationSec: Int
    var moodBefore: Int?
    var moodAfter: Int?
    var createdAt: Date
    var synced: Bool

    init(
        kind: String,
        title: String,
        summary: String = "",
        tags: [String] = [],
        durationSec: Int = 0
    ) {
        self.id = UUID()
        self.kind = kind
        self.title = title
        self.summary = summary
        self.tags = tags
        self.durationSec = durationSec
        self.createdAt = Date()
        self.synced = false
    }
}

@Model
final class Habit {
    @Attribute(.unique) var id: UUID
    var title: String
    var emoji: String
    var goal: String
    var targetPerWeek: Int
    var completedThisWeek: Int
    var history: [String] // ISO dates

    init(title: String, emoji: String, goal: WellnessGoal, targetPerWeek: Int = 3) {
        self.id = UUID()
        self.title = title
        self.emoji = emoji
        self.goal = goal.rawValue
        self.targetPerWeek = targetPerWeek
        self.completedThisWeek = 0
        self.history = []
    }
}

@Model
final class ChatMessage {
    @Attribute(.unique) var id: UUID
    var role: String
    var content: String
    var agent: String?
    var safetyFlags: [String]
    var createdAt: Date

    init(role: String, content: String, agent: String? = nil) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.agent = agent
        self.safetyFlags = []
        self.createdAt = Date()
    }
}

@Model
final class VideoAnalysis {
    @Attribute(.unique) var id: UUID
    var mode: String
    var durationSec: Int
    var nutritionEstimate: String?
    var formNotes: [String]
    var highlights: [String]
    var cautions: [String]
    var score: Int
    var safetyFlag: Bool
    var createdAt: Date

    init(mode: String, durationSec: Int) {
        self.id = UUID()
        self.mode = mode
        self.durationSec = durationSec
        self.formNotes = []
        self.highlights = []
        self.cautions = []
        self.score = 0
        self.safetyFlag = false
        self.createdAt = Date()
    }
}

@Model
final class CrisisAudit {
    @Attribute(.unique) var id: UUID
    var triggerHash: String
    var language: String
    var createdAt: Date
    var resolvedAt: Date?

    init(triggerHash: String, language: String) {
        self.id = UUID()
        self.triggerHash = triggerHash
        self.language = language
        self.createdAt = Date()
    }
}
