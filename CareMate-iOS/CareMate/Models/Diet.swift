import Foundation

enum MealType: String, Codable, CaseIterable {
    case breakfast = "breakfast"
    case lunch     = "lunch"
    case dinner    = "dinner"
    case snack     = "snack"

    var displayName: String { rawValue.capitalized }

    var icon: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch:     return "sun.max.fill"
        case .dinner:    return "moon.fill"
        case .snack:     return "leaf.fill"
        }
    }
}

struct Recipe: Identifiable, Codable {
    var id: String
    var title: String
    var cookingTime: String
    var ingredientsEn: [String]
    var ingredientsMy: [String]
    var instructionsEn: [String]
    var instructionsMy: [String]
    var imageUrl: String?
    var userId: String
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, title
        case cookingTime   = "cooking_time"
        case ingredientsEn = "ingredients_en"
        case ingredientsMy = "ingredients_my"
        case instructionsEn = "instructions_en"
        case instructionsMy = "instructions_my"
        case imageUrl  = "image_url"
        case userId    = "user_id"
        case createdAt = "created_at"
    }

    func ingredients(for language: String) -> [String] {
        language == "my" ? ingredientsMy : ingredientsEn
    }

    func instructions(for language: String) -> [String] {
        language == "my" ? instructionsMy : instructionsEn
    }
}

struct Meal: Identifiable, Codable {
    var id: String
    var type: MealType
    var title: String
    var time: String
    var userId: String
}
