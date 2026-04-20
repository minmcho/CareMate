import Foundation

struct Medication: Identifiable, Codable {
    var id: String
    var nameEn: String
    var nameMy: String
    var dosage: String
    var time: String
    var taken: Bool
    var notes: String?
    var userId: String
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case nameEn  = "name_en"
        case nameMy  = "name_my"
        case dosage, time, taken, notes
        case userId  = "user_id"
        case createdAt = "created_at"
    }

    func name(for language: String) -> String {
        language == "my" ? nameMy : nameEn
    }

    var isOverdue: Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        guard let medTime = formatter.date(from: time) else { return false }
        let now = formatter.date(from: formatter.string(from: Date())) ?? Date()
        return !taken && now > medTime
    }
}

struct MedicationCreate: Codable {
    var nameEn: String
    var nameMy: String
    var dosage: String
    var time: String
    var notes: String?
    var userId: String

    enum CodingKeys: String, CodingKey {
        case nameEn = "name_en"
        case nameMy = "name_my"
        case dosage, time, notes
        case userId = "user_id"
    }
}
