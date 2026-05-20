import Foundation

enum ModerationStatus: String, Codable {
    case approved
    case flagged
    case removed
}

struct ModerationResult: Equatable {
    var status: ModerationStatus
    var reason: String?

    var canPublish: Bool { status != .removed }
}

struct ModerationService {
    private let blockedTerms = [
        "kill yourself",
        "kys",
        "nazi",
        "doxx",
        "doxxing"
    ]

    func evaluate(_ values: [String]) -> ModerationResult {
        let text = values.joined(separator: " ").lowercased()
        if let term = blockedTerms.first(where: { text.contains($0) }) {
            return ModerationResult(status: .removed, reason: "Blocked unsafe term: \(term)")
        }

        let riskyTerms = ["nsfw", "18+", "explicit"]
        if let term = riskyTerms.first(where: { text.contains($0) }) {
            return ModerationResult(status: .flagged, reason: "Needs review for: \(term)")
        }

        return ModerationResult(status: .approved, reason: nil)
    }
}
