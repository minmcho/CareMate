//
//  SafetyValidator.swift
//  Client-side mirror of the backend safety validator.
//  Runs on-device before any network call and on every received response.
//

import Foundation
import CryptoKit

enum SafetyCategory: String, Codable {
    case ok, crisis, medicalClaim, pii
}

struct SafetyResult: Equatable {
    let passed: Bool
    let category: SafetyCategory
    let matches: [String]
    let sanitized: String
}

enum SafetyValidator {

    private static let crisisPatterns: [NSRegularExpression] = compile([
        #"\b(kill|hurt|harm)\s*(myself|me|my\s*self)\b"#,
        #"\b(suicide|suicidal)\b"#,
        #"\b(end\s*(my|it\s*all))\b"#,
        #"\bi\s*(want|wanna)\s*to\s*(die|disappear)\b"#,
        #"\boverdose\b"#,
        #"\bcut(ting)?\s*myself\b"#,
        #"\bchest\s*pain\b"#,
        #"\bcan'?t\s*breathe\b"#,
        #"\bstroke\b"#,
        #"\bheart\s*attack\b"#
    ])

    private static let medicalPatterns: [NSRegularExpression] = compile([
        #"\b(cure|cures|curing)\b"#,
        #"\bdiagnos(e|is|ing)\b"#,
        #"\bprescrib(e|ing|ed)\b"#,
        #"\btreat(s|ment|ing)?\s+your\b"#,
        #"\byou\s*have\s*(diabetes|cancer|depression|bipolar|adhd)\b"#,
        #"\b(take|use)\s+\d+\s*(mg|mcg|ml)\b"#,
        #"\bthis\s*will\s*(heal|fix)\b"#
    ])

    private static let piiPatterns: [NSRegularExpression] = compile([
        #"[\w.+-]+@[\w-]+\.[\w.-]+"#,
        #"\b\d{10,}\b"#
    ])

    static func scanUserInput(_ text: String) -> SafetyResult {
        let crisis = matches(text, crisisPatterns)
        if !crisis.isEmpty {
            return SafetyResult(passed: false, category: .crisis, matches: crisis, sanitized: "[redacted]")
        }
        let pii = matches(text, piiPatterns)
        var sanitized = text
        for pattern in piiPatterns {
            sanitized = pattern.stringByReplacingMatches(
                in: sanitized,
                options: [],
                range: NSRange(location: 0, length: (sanitized as NSString).length),
                withTemplate: "[redacted]"
            )
        }
        return SafetyResult(
            passed: true,
            category: pii.isEmpty ? .ok : .pii,
            matches: pii,
            sanitized: sanitized
        )
    }

    static func scanAssistantOutput(_ text: String) -> SafetyResult {
        let medical = matches(text, medicalPatterns)
        if !medical.isEmpty {
            return SafetyResult(
                passed: false,
                category: .medicalClaim,
                matches: medical,
                sanitized: rewriteMedical(text)
            )
        }
        return SafetyResult(passed: true, category: .ok, matches: [], sanitized: text)
    }

    static func hashForAudit(_ text: String) -> String {
        let digest = SHA256.hash(data: Data(text.utf8))
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Helpers

    private static func compile(_ patterns: [String]) -> [NSRegularExpression] {
        patterns.compactMap {
            try? NSRegularExpression(pattern: $0, options: [.caseInsensitive])
        }
    }

    private static func matches(_ text: String, _ patterns: [NSRegularExpression]) -> [String] {
        var hits: [String] = []
        let range = NSRange(location: 0, length: (text as NSString).length)
        for pattern in patterns {
            if let match = pattern.firstMatch(in: text, options: [], range: range) {
                let value = (text as NSString).substring(with: match.range)
                hits.append(value)
            }
        }
        return hits
    }

    private static func rewriteMedical(_ text: String) -> String {
        var out = text
        let replacements: [(String, String)] = [
            (#"\bcure(s|d|ing)?\b"#, "support"),
            (#"\bdiagnos(e|is|ing)\b"#, "notice"),
            (#"\bprescrib(e|ing|ed)\b"#, "suggest"),
            (#"\btreat(ment|s|ing)?\b"#, "support"),
            (#"\bheal\b"#, "support")
        ]
        for (pattern, replacement) in replacements {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                out = regex.stringByReplacingMatches(
                    in: out,
                    options: [],
                    range: NSRange(location: 0, length: (out as NSString).length),
                    withTemplate: replacement
                )
            }
        }
        if !out.lowercased().contains("wellness, not medicine") {
            out += "\n\n_Reminder: VitalPath offers wellness guidance only._"
        }
        return out
    }
}
