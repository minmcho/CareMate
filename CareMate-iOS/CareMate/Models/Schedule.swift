import Foundation

enum TaskStatus: String, Codable, CaseIterable {
    case pending    = "pending"
    case inProgress = "in-progress"
    case completed  = "completed"

    var next: TaskStatus {
        switch self {
        case .pending:    return .inProgress
        case .inProgress: return .completed
        case .completed:  return .pending
        }
    }

    var displayName: String {
        switch self {
        case .pending:    return "Pending"
        case .inProgress: return "In Progress"
        case .completed:  return "Completed"
        }
    }
}

struct ScheduleTask: Identifiable, Codable {
    var id: String
    var titleEn: String
    var titleMy: String
    var time: String
    var status: TaskStatus
    var userId: String
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case titleEn  = "title_en"
        case titleMy  = "title_my"
        case time, status
        case userId   = "user_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    func title(for language: String) -> String {
        language == "my" ? titleMy : titleEn
    }
}

struct ScheduleTaskCreate: Codable {
    var titleEn: String
    var titleMy: String
    var time: String
    var status: TaskStatus = .pending
    var userId: String

    enum CodingKeys: String, CodingKey {
        case titleEn = "title_en"
        case titleMy = "title_my"
        case time, status
        case userId  = "user_id"
    }
}
