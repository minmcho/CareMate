import Foundation

enum MessageRole: String, Codable {
    case user      = "user"
    case assistant = "assistant"
    case system    = "system"
}

struct ChatMessage: Identifiable, Codable {
    var id: UUID = UUID()
    var role: MessageRole
    var content: String
    var timestamp: Date
    var agentUsed: String?
    var audioBase64: String?
    var isMemoryHit: Bool = false

    enum CodingKeys: String, CodingKey {
        case role, content, timestamp
        case agentUsed   = "agent_used"
        case audioBase64 = "audio_base64"
        case isMemoryHit = "memory_hit"
    }
}

struct ConversationRequest: Codable {
    var userId: String
    var message: String
    var language: String
    var audioBase64: String?
    var useMemory: Bool = true

    enum CodingKeys: String, CodingKey {
        case userId      = "user_id"
        case message, language
        case audioBase64 = "audio_base64"
        case useMemory   = "use_memory"
    }
}

struct ConversationResponse: Codable {
    var reply: String
    var replyAudioBase64: String?
    var agentUsed: String
    var reasoningSteps: [String]?
    var memoryHit: Bool

    enum CodingKeys: String, CodingKey {
        case reply
        case replyAudioBase64 = "reply_audio_base64"
        case agentUsed        = "agent_used"
        case reasoningSteps   = "reasoning_steps"
        case memoryHit        = "memory_hit"
    }
}
