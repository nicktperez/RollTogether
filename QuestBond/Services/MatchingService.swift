import Foundation

enum MatchingService {
    static func score(group: GroupListing, party: PartyListing) -> (score: Int, reasons: [String]) {
        let categories = categoryScores(group: group, party: party)
        let score = categories.reduce(0) { $0 + $1.score }
        let reasons = categories.map(\.note)

        return (min(100, max(0, score)), Array(reasons.prefix(4)))
    }

    static func categoryScores(group: GroupListing, party: PartyListing) -> [MatchCategoryScore] {
        let modeScore = modesCompatible(group.mode, party.mode) ? 20 : 0
        let slotScore = capacityPoints(openSlots: group.openSlots, partySize: party.partySize, weight: 18)
        let experienceScore = valueMatches(requested: group.desiredExperience, actual: party.experience) ? 12 : 0
        let roleFit = roleCompatibility(wanted: group.desiredRoles, offered: party.rolesCovered, weight: 18)
        let campaignScore = party.lookingForCampaign == .any || party.lookingForCampaign == group.campaignStyle ? 14 : 0
        let partySizeScore = partySizeMatches(group.lookingForPartySize, party.partySize) ? 8 : 0
        let availability = availabilityCompatibility(groupAvailability: group.availability, partyAvailability: party.availability, groupSchedule: group.schedule, partySchedule: party.schedule, weight: 10)

        return [
            MatchCategoryScore(
                category: "Mode",
                score: modeScore,
                weight: 20,
                note: modeScore > 0 ? "Session type alignment is strong." : "Session type preference conflicts."
            ),
            MatchCategoryScore(
                category: "Capacity",
                score: slotScore,
                weight: 18,
                note: slotScore > 0
                    ? "\(group.openSlots) open slot\(group.openSlots == 1 ? "" : "s") can fit this \(partySizeLabel(party.partySize).lowercased())."
                    : "Party size is larger than the current open slots."
            ),
            MatchCategoryScore(
                category: "Experience",
                score: experienceScore,
                weight: 12,
                note: experienceScore > 0 ? "Experience level fits what the group wants." : "Experience preference needs discussion."
            ),
            MatchCategoryScore(category: "Roles", score: roleFit.points, weight: 18, note: roleFit.reason),
            MatchCategoryScore(
                category: "Campaign",
                score: campaignScore,
                weight: 14,
                note: campaignScore > 0 ? "Campaign style preference lines up." : "Campaign style may not match."
            ),
            MatchCategoryScore(
                category: "Party Size",
                score: partySizeScore,
                weight: 8,
                note: partySizeScore > 0 ? "Party size category matches the requested target." : "Party size target is not exact."
            ),
            availability
        ]
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

    static func listingFreshnessLabel(createdAt: Date, now: Date = .now) -> String {
        let days = Calendar.current.dateComponents([.day], from: createdAt, to: now).day ?? 0
        switch days {
        case ..<14:
            return "Fresh"
        case 14..<30:
            return "Review soon"
        default:
            return "Stale"
        }
    }

    private static func availabilityCompatibility(
        groupAvailability: [AvailabilitySlot]?,
        partyAvailability: [AvailabilitySlot]?,
        groupSchedule: String,
        partySchedule: String,
        weight: Int
    ) -> MatchCategoryScore {
        let groupSlots = Set(groupAvailability ?? [])
        let partySlots = Set(partyAvailability ?? [])

        if !groupSlots.isEmpty || !partySlots.isEmpty {
            guard !groupSlots.isEmpty, !partySlots.isEmpty else {
                return MatchCategoryScore(category: "Availability", score: weight / 2, weight: weight, note: "One side has availability details listed.")
            }

            let overlap = groupSlots.intersection(partySlots)
            guard !overlap.isEmpty else {
                return MatchCategoryScore(category: "Availability", score: 0, weight: weight, note: "No availability overlap listed.")
            }

            let labels = overlap.prefix(2).map(\.label).joined(separator: ", ")
            return MatchCategoryScore(category: "Availability", score: weight, weight: weight, note: "Availability overlaps: \(labels).")
        }

        let groupText = groupSchedule.lowercased()
        let partyText = partySchedule.lowercased()
        let tokens = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday", "weekday", "weekend", "morning", "afternoon", "evening", "night"]
        let hasOverlap = tokens.contains { groupText.contains($0) && partyText.contains($0) }
        return MatchCategoryScore(
            category: "Availability",
            score: hasOverlap ? weight : weight / 2,
            weight: weight,
            note: hasOverlap ? "Schedule text appears to overlap." : "Schedule needs confirmation."
        )
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
