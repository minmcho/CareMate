import SwiftUI
import Combine

class AppState: ObservableObject {
    @Published var language: AppLanguage = .english
    @Published var userId: String = "user_001"   // Replace with auth user ID
    @Published var isAuthenticated: Bool = true   // Placeholder

    enum AppLanguage: String, CaseIterable, Identifiable {
        case english = "en"
        case myanmar = "my"
        case thai    = "th"
        case arabic  = "ar"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .english: return "EN"
            case .myanmar: return "MY"
            case .thai:    return "TH"
            case .arabic:  return "AR"
            }
        }

        var fullName: String {
            switch self {
            case .english: return "English"
            case .myanmar: return "Myanmar"
            case .thai:    return "Thai"
            case .arabic:  return "Arabic"
            }
        }
    }
}
