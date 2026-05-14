import SwiftUI

final class QuestBondStore: ObservableObject {
    @Published var currentUser: UserProfile {
        didSet { save() }
    }

    @Published var groups: [GroupListing] {
        didSet { save() }
    }

    @Published var parties: [PartyListing] {
        didSet { save() }
    }

    @Published var matches: [MatchRecord] {
        didSet { save() }
    }

    @Published var threads: [ChatThread] {
        didSet { save() }
    }

    @Published var messages: [ChatMessage] {
        didSet { save() }
    }

    @Published var decisions: [DecisionRecord] {
        didSet { save() }
    }

    @Published var blocks: [BlockRecord] {
        didSet { save() }
    }

    @Published var reports: [ReportRecord] {
        didSet { save() }
    }

    @Published var groupFilters: GroupBrowseFilters {
        didSet { save() }
    }

    @Published var partyFilters: PartyBrowseFilters {
        didSet { save() }
    }

    private let storageKey = "questbond.native.state.v1"

    init() {
        if let saved = Self.loadSavedState(key: storageKey) {
            currentUser = saved.currentUser
            groups = saved.groups
            parties = saved.parties
            matches = saved.matches
            threads = saved.threads
            messages = saved.messages
            decisions = saved.decisions
            blocks = saved.blocks
            reports = saved.reports
            groupFilters = saved.groupFilters
            partyFilters = saved.partyFilters
        } else {
            currentUser = SeedData.currentUser
            groups = SeedData.groups
            parties = SeedData.parties
            matches = []
            threads = []
            messages = []
            decisions = []
            blocks = []
            reports = []
            groupFilters = GroupBrowseFilters(ownerID: SeedData.groups.first?.id)
            partyFilters = PartyBrowseFilters(ownerID: SeedData.parties.first?.id)
        }

        normalizeOwners()
    }

    var groupOwner: GroupListing? {
        groups.first { $0.id == groupFilters.ownerID }
    }

    var partyOwner: PartyListing? {
        parties.first { $0.id == partyFilters.ownerID }
    }

    var groupBrowseCandidates: [Candidate<PartyListing>] {
        guard let owner = groupOwner else { return [] }

        let availableParties = parties.filter { party in
            !hasDecision(context: .groupBrowsing, ownerID: owner.id, targetID: party.id)
                && MatchingService.matchesMode(party.mode, filter: groupFilters.preMode)
                && MatchingService.valueMatches(requested: groupFilters.preExperience, actual: party.experience)
                && party.partySize >= groupFilters.minimumPartySize
        }

        let scoredCandidates: [Candidate<PartyListing>] = availableParties.map { party in
            let result = MatchingService.score(group: owner, party: party)
            return Candidate(entry: party, score: result.score, reasons: result.reasons)
        }

        let filteredCandidates = scoredCandidates.filter { candidate in
            let party = candidate.entry
            let campaignMatches = groupFilters.postCampaign == .any
                || party.lookingForCampaign == .any
                || party.lookingForCampaign == groupFilters.postCampaign

            return MatchingService.matchesMode(party.mode, filter: groupFilters.postMode)
                && campaignMatches
                && MatchingService.matchesQuery(groupFilters.query, values: [party.name, party.location, party.vibe, party.about])
        }

        return filteredCandidates.sorted { lhs, rhs in
            lhs.score == rhs.score ? lhs.entry.createdAt > rhs.entry.createdAt : lhs.score > rhs.score
        }
    }

    var partyBrowseCandidates: [Candidate<GroupListing>] {
        guard let owner = partyOwner else { return [] }

        let availableGroups = groups.filter { group in
            !hasDecision(context: .partyBrowsing, ownerID: owner.id, targetID: group.id)
                && MatchingService.matchesMode(group.mode, filter: partyFilters.preMode)
                && (partyFilters.preCampaign == .any || group.campaignStyle == partyFilters.preCampaign)
                && group.openSlots >= partyFilters.minimumOpenSlots
        }

        let scoredCandidates: [Candidate<GroupListing>] = availableGroups.map { group in
            let result = MatchingService.score(party: owner, group: group)
            return Candidate(entry: group, score: result.score, reasons: result.reasons)
        }

        let filteredCandidates = scoredCandidates.filter { candidate in
            let group = candidate.entry
            return MatchingService.matchesMode(group.mode, filter: partyFilters.postMode)
                && MatchingService.valueMatches(requested: partyFilters.postExperience, actual: group.tableExperience)
                && MatchingService.matchesQuery(partyFilters.query, values: [group.name, group.location, group.characterVibe, group.about])
        }

        return filteredCandidates.sorted { lhs, rhs in
            lhs.score == rhs.score ? lhs.entry.createdAt > rhs.entry.createdAt : lhs.score > rhs.score
        }
    }

    func addGroup(_ listing: GroupListing) {
        groups.insert(listing, at: 0)
        groupFilters.ownerID = listing.id
        normalizeOwners()
    }

    func addParty(_ listing: PartyListing) {
        parties.insert(listing, at: 0)
        partyFilters.ownerID = listing.id
        normalizeOwners()
    }

    func swipeGroupCandidate(_ choice: DecisionRecord.Choice) {
        guard let owner = groupOwner, let candidate = groupBrowseCandidates.first else { return }
        decisions.append(DecisionRecord(context: .groupBrowsing, ownerID: owner.id, targetID: candidate.entry.id, choice: choice))

        if choice == .connect {
            addMatch(group: owner, party: candidate.entry, score: candidate.score, initiatedBy: "group")
        }
    }

    func swipePartyCandidate(_ choice: DecisionRecord.Choice) {
        guard let owner = partyOwner, let candidate = partyBrowseCandidates.first else { return }
        decisions.append(DecisionRecord(context: .partyBrowsing, ownerID: owner.id, targetID: candidate.entry.id, choice: choice))

        if choice == .connect {
            addMatch(group: candidate.entry, party: owner, score: candidate.score, initiatedBy: "party")
        }
    }

    func clearMatches() {
        matches = []
        threads = []
        messages = []
    }

    func deleteLocalAccount() {
        UserDefaults.standard.removeObject(forKey: storageKey)
        currentUser = SeedData.currentUser
        groups = SeedData.groups
        parties = SeedData.parties
        matches = []
        threads = []
        messages = []
        decisions = []
        blocks = []
        reports = []
        groupFilters = GroupBrowseFilters(ownerID: SeedData.groups.first?.id)
        partyFilters = PartyBrowseFilters(ownerID: SeedData.parties.first?.id)
    }

    func blockMatch(in thread: ChatThread, reason: String = "Blocked from chat") {
        guard !blocks.contains(where: { $0.blockedName == thread.groupName || $0.blockedName == thread.partyName }) else { return }
        blocks.append(BlockRecord(blockedName: "\(thread.groupName) + \(thread.partyName)", reason: reason))
    }

    func reportThread(_ thread: ChatThread, reason: String, details: String = "") {
        reports.append(
            ReportRecord(
                subject: .message,
                targetName: "\(thread.groupName) + \(thread.partyName)",
                reason: reason,
                details: details
            )
        )
    }

    func messages(for thread: ChatThread) -> [ChatMessage] {
        messages
            .filter { $0.threadID == thread.id }
            .sorted { $0.createdAt < $1.createdAt }
    }

    func sendMessage(_ text: String, in thread: ChatThread) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        messages.append(ChatMessage(threadID: thread.id, sender: .me, text: trimmed))
        touchThread(thread.id)
    }

    func sendPrompt(_ text: String, in thread: ChatThread) {
        sendMessage(text, in: thread)
    }

    private func addMatch(group: GroupListing, party: PartyListing, score: Int, initiatedBy: String) {
        guard !matches.contains(where: { $0.groupID == group.id && $0.partyID == party.id }) else { return }

        let match = MatchRecord(
            groupID: group.id,
            groupName: group.name,
            partyID: party.id,
            partyName: party.name,
            score: score,
            initiatedBy: initiatedBy
        )

        matches.insert(
            match,
            at: 0
        )

        createThread(for: match, group: group, party: party)
    }

    private func createThread(for match: MatchRecord, group: GroupListing, party: PartyListing) {
        let thread = ChatThread(
            matchID: match.id,
            groupName: group.name,
            partyName: party.name,
            score: match.score,
            summary: "\(group.mode.label) | \(group.campaignStyle.label) | \(group.schedule.isEmpty ? "Schedule flexible" : group.schedule)"
        )

        threads.insert(thread, at: 0)
        messages.append(contentsOf: [
            ChatMessage(threadID: thread.id, sender: .system, text: "Connection opened. Contact details stay private until someone shares them in chat."),
            ChatMessage(threadID: thread.id, sender: .match, text: "Hey! This looks like a good fit. Want to compare schedules and table expectations?")
        ])
    }

    private func touchThread(_ threadID: UUID) {
        guard let index = threads.firstIndex(where: { $0.id == threadID }) else { return }
        threads[index].updatedAt = .now
        threads.sort { $0.updatedAt > $1.updatedAt }
    }

    private func hasDecision(context: DecisionRecord.ViewContext, ownerID: UUID, targetID: UUID) -> Bool {
        decisions.contains {
            $0.context == context && $0.ownerID == ownerID && $0.targetID == targetID
        }
    }

    private func normalizeOwners() {
        if groupFilters.ownerID == nil || !groups.contains(where: { $0.id == groupFilters.ownerID }) {
            groupFilters.ownerID = groups.first?.id
        }

        if partyFilters.ownerID == nil || !parties.contains(where: { $0.id == partyFilters.ownerID }) {
            partyFilters.ownerID = parties.first?.id
        }
    }

    private func save() {
        let state = PersistedState(
            currentUser: currentUser,
            groups: groups,
            parties: parties,
            matches: matches,
            threads: threads,
            messages: messages,
            decisions: decisions,
            blocks: blocks,
            reports: reports,
            groupFilters: groupFilters,
            partyFilters: partyFilters
        )

        if let data = try? JSONEncoder.questBond.encode(state) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private static func loadSavedState(key: String) -> PersistedState? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder.questBond.decode(PersistedState.self, from: data)
    }
}

private struct PersistedState: Codable {
    var currentUser: UserProfile
    var groups: [GroupListing]
    var parties: [PartyListing]
    var matches: [MatchRecord]
    var threads: [ChatThread]
    var messages: [ChatMessage]
    var decisions: [DecisionRecord]
    var blocks: [BlockRecord] = []
    var reports: [ReportRecord] = []
    var groupFilters: GroupBrowseFilters
    var partyFilters: PartyBrowseFilters
}
