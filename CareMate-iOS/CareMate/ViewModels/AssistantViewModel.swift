import SwiftUI
import AVFoundation

@MainActor
class AssistantViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading = false
    @Published var isRecording = false
    @Published var errorMessage: String?
    @Published var useMemory = true

    let speechService = SpeechService()
    private let api = APIService.shared
    private var recordingData: Data?

    // MARK: - Send text message

    func sendMessage(userId: String, language: String) async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputText = ""

        let userMsg = ChatMessage(
            role: .user,
            content: text,
            timestamp: Date()
        )
        messages.append(userMsg)
        await performRequest(userId: userId, text: text, language: language, audioBase64: nil)
    }

    // MARK: - Send voice message

    func startRecording() {
        Task {
            let granted = await speechService.requestPermissions()
            guard granted else {
                errorMessage = "Microphone permission denied"
                return
            }
            do {
                _ = try speechService.startAudioRecording()
                isRecording = true
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func stopRecordingAndSend(userId: String, language: String) async {
        isRecording = false
        guard let audioData = speechService.stopAudioRecording() else {
            errorMessage = "No audio recorded"
            return
        }
        let b64 = audioData.base64EncodedString()

        let userMsg = ChatMessage(
            role: .user,
            content: "[Voice message]",
            timestamp: Date()
        )
        messages.append(userMsg)
        await performRequest(userId: userId, text: "", language: language, audioBase64: b64)
    }

    // MARK: - Core request

    private func performRequest(userId: String, text: String, language: String, audioBase64: String?) async {
        isLoading = true
        defer { isLoading = false }

        let req = ConversationRequest(
            userId: userId,
            message: text,
            language: language,
            audioBase64: audioBase64,
            useMemory: useMemory
        )

        do {
            let response: ConversationResponse = try await api.post("/api/assistant/chat", body: req)

            // Update last user message text if it was a voice message
            if let last = messages.last, last.content == "[Voice message]", audioBase64 != nil {
                // The backend transcribed it — we don't have the transcript back, keep as-is
            }

            let assistantMsg = ChatMessage(
                role: .assistant,
                content: response.reply,
                timestamp: Date(),
                agentUsed: response.agentUsed,
                audioBase64: response.replyAudioBase64,
                isMemoryHit: response.memoryHit
            )
            messages.append(assistantMsg)

            // Auto-play TTS
            if let audio = response.replyAudioBase64 {
                try? speechService.playAudio(base64: audio)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clearHistory(userId: String) async {
        do {
            try await api.delete("/api/assistant/history/\(userId)")
            messages.removeAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
