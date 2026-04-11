//
//  ChatViewModel.swift
//  Observable view-model for the coach chat surface.
//

import Foundation
import Observation

@Observable
@MainActor
final class ChatViewModel {
    var messages: [ChatDTO] = []
    var input: String = ""
    var busy: Bool = false
    var rewriteNotice: String?
    var crisisTriggered: Bool = false

    private let client: GraphQLClient
    private let tokenProvider: () -> String?

    init(client: GraphQLClient, tokenProvider: @escaping () -> String?) {
        self.client = client
        self.tokenProvider = tokenProvider
    }

    func send() async {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !busy else { return }
        input = ""
        rewriteNotice = nil

        // Pre-processing safety sweep on-device.
        let scan = SafetyValidator.scanUserInput(trimmed)
        if scan.category == .crisis {
            crisisTriggered = true
            messages.append(ChatDTO(role: "assistant",
                                    content: "I'm glad you reached out. Please reach a trained helpline.",
                                    agent: "fallback"))
            return
        }

        messages.append(ChatDTO(role: "user", content: scan.sanitized, agent: nil))
        busy = true
        defer { busy = false }

        let query = """
        mutation Ask($text: String!) {
          askCoach(text: $text) {
            content
            agent
            crisisTriggered
            safetyRewritten
          }
        }
        """
        do {
            let result: AskResult = try await client.perform(
                query: query,
                variables: ["text": scan.sanitized],
                token: tokenProvider()
            )
            let reply = result.askCoach
            let outScan = SafetyValidator.scanAssistantOutput(reply.content)
            messages.append(ChatDTO(role: "assistant",
                                    content: outScan.sanitized,
                                    agent: reply.agent))
            if reply.crisisTriggered { crisisTriggered = true }
            if reply.safetyRewritten || !outScan.passed {
                rewriteNotice = "A response was rewritten to stay within wellness guidance."
            }
        } catch GraphQLError.circuitOpen {
            messages.append(ChatDTO(role: "assistant",
                                    content: "Gentle breath: inhale 4, hold 4, exhale 4, hold 4.",
                                    agent: "fallback"))
        } catch {
            messages.append(ChatDTO(role: "assistant",
                                    content: "I'm offline right now — here's a small wellness tip: sip water and stretch your shoulders.",
                                    agent: "fallback"))
        }
    }

    struct ChatDTO: Identifiable {
        let id = UUID()
        let role: String
        let content: String
        let agent: String?
    }

    private struct AskResult: Decodable {
        let askCoach: AskCoach
        struct AskCoach: Decodable {
            let content: String
            let agent: String
            let crisisTriggered: Bool
            let safetyRewritten: Bool
        }
    }
}
