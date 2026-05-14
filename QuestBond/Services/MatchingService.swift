import Foundation

enum MatchingService {
    static func score(group: GroupListing, party: PartyListing) -> (score: Int, reasons: [String]) {
        var score = 0
        var reasons: [String] = []

        if modesCompatible(group.mode, party.mode) {
            score += 20
            reasons.append("Session type alignment is strong.")
        } else {
            reasons.append("Session type preference conflicts.")
        }

        let slotPoints = capacityPoints(openSlots: group.openSlots, partySize: party.partySize, weight: 20)
        score += slotPoints
        reasons.append(
            slotPoints > 0
                ? "\(group.openSlots) open slot\(group.openSlots == 1 ? "" : "s") can fit this \(partySizeLabel(party.partySize).lowercased())."
                : "Party size is larger than the current open slots."
        )

        if valueMatches(requested: group.desiredExperience, actual: party.experience) {
            score += 15
            reasons.append("Experience level fits what the group wants.")
        }

        let roleFit = roleCompatibility(wanted: group.desiredRoles, offered: party.rolesCovered, weight: 20)
        score += roleFit.points
        reasons.append(roleFit.reason)

        if party.lookingForCampaign == .any || party.lookingForCampaign == group.campaignStyle {
            score += 15
            reasons.append("Campaign style preference lines up.")
        }

        if partySizeMatches(group.lookingForPartySize, party.partySize) {
            score += 10
            reasons.append("Party size category matches the requested target.")
        }

        return (min(100, max(0, score)), Array(reasons.prefix(4)))
    }

    static func score(party: PartyListing, group: GroupListing) -> (score: Int, reasons: [String]) {
        score(group: group, party: party)
    }

    static func matchesMode(_ mode: SessionMode, filter: SessionMode) -> Bool {
        filter == .any || mode == filter || (mode == .hybrid && (filter == .online || filter == .inPerson))
    }

    static func valueMatches(requested: ExperienceLevel, actual: ExperienceLevel) -> Bool {
        requested == .any || actual == .any || requested == actual
    }

    static func matchesQuery(_ query: String, values: [String]) -> Bool {
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !term.isEmpty else { return true }
        return values.contains { $0.lowercased().contains(term) }
    }

    private static func modesCompatible(_ left: SessionMode, _ right: SessionMode) -> Bool {
        left == right || left == .hybrid || right == .hybrid
    }

    private static func capacityPoints(openSlots: Int, partySize: Int, weight: Int) -> Int {
        if openSlots >= partySize {
            return weight
        }

        if openSlots + 1 == partySize {
            return Int(Double(weight) * 0.45)
        }

        return 0
    }

    private static func roleCompatibility(wanted: [PartyRole], offered: [PartyRole], weight: Int) -> (points: Int, reason: String) {
        guard !wanted.isEmpty else {
            return (weight, "Group accepts any role composition.")
        }

        guard !offered.isEmpty else {
            return (0, "Role overlap is unknown because no roles were listed.")
        }

        let overlap = offered.filter { wanted.contains($0) }
        guard !overlap.isEmpty else {
            return (0, "No direct role overlap with requested composition.")
        }

        let ratio = Double(overlap.count) / Double(wanted.count)
        let labels = overlap.map(\.label).joined(separator: ", ")
        return (Int(Double(weight) * ratio), "Role overlap: \(labels).")
    }

    private static func partySizeMatches(_ preference: PartySizePreference, _ size: Int) -> Bool {
        preference == .any || preference == partySizeCategory(size)
    }

    static func partySizeCategory(_ size: Int) -> PartySizePreference {
        if size <= 1 { return .single }
        if size == 2 { return .duo }
        if size == 3 { return .trio }
        return .squad
    }

    static func partySizeLabel(_ size: Int) -> String {
        switch partySizeCategory(size) {
        case .any: "Any"
        case .single: "Single"
        case .duo: "Duo"
        case .trio: "Trio"
        case .squad: "Squad"
        }
    }
}

extension JSONEncoder {
    static var questBond: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

extension JSONDecoder {
    static var questBond: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
