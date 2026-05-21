import SwiftUI

@MainActor
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

    @Published var feedback: [PostSessionFeedback] {
        didSet { save() }
    }

    @Published var savedSearches: [SavedSearch] {
        didSet { save() }
    }

    @Published var sessionZero: SessionZeroProfile {
        didSet { save() }
    }

    @Published var groupFilters: GroupBrowseFilters {
        didSet { save() }
    }

    @Published var partyFilters: PartyBrowseFilters {
        didSet { save() }
    }

    @Published private(set) var backendStatus = "Offline local mode"
    @Published var moderationWarning: String?

    private let storageKey = "questbond.native.state.v1"
    private var repository: SupabaseQuestBondRepository?
    private let realtime = SupabaseRealtimeService()

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
            feedback = saved.feedback
            savedSearches = saved.savedSearches
            sessionZero = saved.sessionZero
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
            feedback = []
            savedSearches = []
            sessionZero = SeedData.sessionZero
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

    var profileStrength: ProfileStrength {
        var score = 0
        var missing: [String] = []

        func add(_ points: Int, when condition: Bool, missing label: String) {
            if condition {
                score += points
            } else {
                missing.append(label)
            }
        }

        add(15, when: !currentUser.displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, missing: "display name")
        add(10, when: !currentUser.handle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, missing: "handle")
        add(15, when: !currentUser.location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, missing: "location")
        add(20, when: currentUser.bio.count >= 40, missing: "longer bio")
        add(15, when: !currentUser.safetyNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, missing: "safety note")
        add(15, when: !sessionZero.tone.isEmpty && !sessionZero.safetyTools.isEmpty && !sessionZero.rulesStyle.isEmpty, missing: "Session Zero answers")
        add(10, when: !groups.isEmpty || !parties.isEmpty, missing: "at least one listing")

        return ProfileStrength(score: min(score, 100), missingItems: missing)
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
                && isWithinDistance(ownerLatitude: owner.latitude, ownerLongitude: owner.longitude, targetLatitude: party.latitude, targetLongitude: party.longitude, maximumMiles: Double(groupFilters.maximumDistanceMiles))
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
                && isWithinDistance(ownerLatitude: owner.latitude, ownerLongitude: owner.longitude, targetLatitude: group.latitude, targetLongitude: group.longitude, maximumMiles: Double(partyFilters.maximumDistanceMiles))
                && MatchingService.matchesQuery(partyFilters.query, values: [group.name, group.location, group.characterVibe, group.about])
        }

        return filteredCandidates.sorted { lhs, rhs in
            lhs.score == rhs.score ? lhs.entry.createdAt > rhs.entry.createdAt : lhs.score > rhs.score
        }
    }

    func addGroup(_ listing: GroupListing) {
        let moderation = ModerationService().evaluate([listing.name, listing.characterVibe, listing.about, listing.contact])
        guard moderation.canPublish else {
            moderationWarning = moderation.reason ?? "This listing needs moderation before publishing."
            Task { await mirrorModeration(subject: .listing, listingID: listing.id, result: moderation) }
            return
        }

        if moderation.status == .flagged {
            Task { await mirrorModeration(subject: .listing, listingID: listing.id, result: moderation) }
        }

        groups.insert(listing, at: 0)
        groupFilters.ownerID = listing.id
        normalizeOwners()
        Task { await mirrorGroup(listing) }
    }

    func addParty(_ listing: PartyListing) {
        let moderation = ModerationService().evaluate([listing.name, listing.vibe, listing.about, listing.contact])
        guard moderation.canPublish else {
            moderationWarning = moderation.reason ?? "This listing needs moderation before publishing."
            Task { await mirrorModeration(subject: .listing, listingID: listing.id, result: moderation) }
            return
        }

        if moderation.status == .flagged {
            Task { await mirrorModeration(subject: .listing, listingID: listing.id, result: moderation) }
        }

        parties.insert(listing, at: 0)
        partyFilters.ownerID = listing.id
        normalizeOwners()
        Task { await mirrorParty(listing) }
    }

    func swipeGroupCandidate(_ choice: DecisionRecord.Choice) {
        guard let owner = groupOwner, let candidate = groupBrowseCandidates.first else { return }
        decisions.append(DecisionRecord(context: .groupBrowsing, ownerID: owner.id, targetID: candidate.entry.id, choice: choice))
        Task { await mirrorSwipe(ownerID: owner.id, targetID: candidate.entry.id, context: .groupBrowsing, choice: choice) }

        if choice == .connect {
            addMatch(group: owner, party: candidate.entry, score: candidate.score, initiatedBy: "group")
        }
    }

    func swipePartyCandidate(_ choice: DecisionRecord.Choice) {
        guard let owner = partyOwner, let candidate = partyBrowseCandidates.first else { return }
        decisions.append(DecisionRecord(context: .partyBrowsing, ownerID: owner.id, targetID: candidate.entry.id, choice: choice))
        Task { await mirrorSwipe(ownerID: owner.id, targetID: candidate.entry.id, context: .partyBrowsing, choice: choice) }

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
        feedback = []
        savedSearches = []
        sessionZero = SeedData.sessionZero
        groupFilters = GroupBrowseFilters(ownerID: SeedData.groups.first?.id)
        partyFilters = PartyBrowseFilters(ownerID: SeedData.parties.first?.id)
    }

    func blockMatch(in thread: ChatThread, reason: String = "Blocked from chat") {
        guard !blocks.contains(where: { $0.blockedName == thread.groupName || $0.blockedName == thread.partyName }) else { return }
        let block = BlockRecord(blockedName: "\(thread.groupName) + \(thread.partyName)", reason: reason)
        blocks.append(block)
        Task { await mirrorBlock(block) }
    }

    func reportThread(_ thread: ChatThread, reason: String, details: String = "") {
        let report = ReportRecord(
            subject: .message,
            targetName: "\(thread.groupName) + \(thread.partyName)",
            reason: reason,
            details: details
        )
        reports.append(report)
        Task { await mirrorReport(report) }
    }

    func messages(for thread: ChatThread) -> [ChatMessage] {
        messages
            .filter { $0.threadID == thread.id }
            .sorted { $0.createdAt < $1.createdAt }
    }

    func sendMessage(_ text: String, in thread: ChatThread) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let moderation = ModerationService().evaluate([trimmed])
        guard moderation.canPublish else {
            moderationWarning = moderation.reason ?? "This message needs moderation before sending."
            Task { await mirrorModeration(subject: .message, result: moderation) }
            return
        }

        if moderation.status == .flagged {
            Task { await mirrorModeration(subject: .message, result: moderation) }
        }

        let message = ChatMessage(threadID: thread.id, sender: .me, text: trimmed)
        messages.append(message)
        touchThread(thread.id)
        Task { await mirrorMessage(message) }
    }

    func configureBackend(accessTokenProvider: @escaping () -> String?, userIDProvider: @escaping () -> UUID?) {
        repository = SupabaseQuestBondRepository(accessTokenProvider: accessTokenProvider, userIDProvider: userIDProvider)
        backendStatus = "Supabase configured"
    }

    func loadBackendData() async {
        guard let repository else { return }
        do {
            currentUser = try await repository.loadProfile()
            let loaded = try await repository.loadListings()
            if !loaded.0.isEmpty || !loaded.1.isEmpty {
                groups = loaded.0
                parties = loaded.1
            }
            backendStatus = "Synced with Supabase"
            normalizeOwners()
        } catch {
            backendStatus = "Supabase sync failed: \(error.localizedDescription)"
        }
    }

    func registerPushToken(_ token: String?, auth: AuthSessionStore) async {
        await auth.registerPushTokenIfNeeded(token)
    }

    func saveProfileToBackend(auth: AuthSessionStore) async {
        guard let accessToken = auth.accessToken, let userID = auth.userID else { return }
        do {
            _ = try await SupabaseClient().updateProfile(currentUser.payload(userID: userID), accessToken: accessToken)
            backendStatus = "Profile synced"
        } catch {
            backendStatus = "Profile sync failed: \(error.localizedDescription)"
        }
    }

    func subscribeToRealtime(thread: ChatThread, auth: AuthSessionStore) {
        guard let accessToken = auth.accessToken else { return }
        realtime.subscribeToMessages(threadID: thread.id, accessToken: accessToken) { [weak self] event in
            guard let self else { return }
            guard !self.messages.contains(where: { $0.id == event.id }) else { return }
            let sender: ChatMessage.Sender = event.senderUserID == auth.userID ? .me : .match
            self.messages.append(ChatMessage(id: event.id, threadID: event.threadID, sender: sender, text: event.body))
            self.touchThread(event.threadID)
            self.backendStatus = "Realtime chat active"
        }
    }

    func disconnectRealtime() {
        realtime.disconnect()
    }

    func sendPrompt(_ text: String, in thread: ChatThread) {
        sendMessage(text, in: thread)
    }

    func saveCurrentGroupSearch(named name: String? = nil) {
        let searchName = sanitizedSearchName(name, fallback: groupOwner?.name ?? "Group Search")
        let summary = "\(groupFilters.preMode.label), \(groupFilters.preExperience.label), \(groupFilters.maximumDistanceMiles) mi"
        upsertSavedSearch(
            SavedSearch(
                name: searchName,
                kind: .group,
                summary: summary,
                candidateCount: groupBrowseCandidates.count,
                alertsEnabled: true,
                groupFilters: groupFilters
            )
        )
    }

    func saveCurrentPartySearch(named name: String? = nil) {
        let searchName = sanitizedSearchName(name, fallback: partyOwner?.name ?? "Party Search")
        let summary = "\(partyFilters.preMode.label), \(partyFilters.preCampaign.label), \(partyFilters.maximumDistanceMiles) mi"
        upsertSavedSearch(
            SavedSearch(
                name: searchName,
                kind: .party,
                summary: summary,
                candidateCount: partyBrowseCandidates.count,
                alertsEnabled: true,
                partyFilters: partyFilters
            )
        )
    }

    func toggleSavedSearchAlerts(_ search: SavedSearch) {
        guard let index = savedSearches.firstIndex(where: { $0.id == search.id }) else { return }
        savedSearches[index].alertsEnabled.toggle()
    }

    func applySavedSearch(_ search: SavedSearch) {
        switch search.kind {
        case .group:
            if let filters = search.groupFilters { groupFilters = filters }
        case .party:
            if let filters = search.partyFilters { partyFilters = filters }
        }
    }

    func deleteSavedSearches(at offsets: IndexSet) {
        savedSearches.remove(atOffsets: offsets)
    }

    func submitFeedback(thread: ChatThread, sentiment: PostSessionFeedback.Sentiment, wouldPlayAgain: Bool, notes: String) {
        let trimmed = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        feedback.insert(PostSessionFeedback(threadID: thread.id, sentiment: sentiment, wouldPlayAgain: wouldPlayAgain, notes: trimmed), at: 0)

        if sentiment == .safetyConcern {
            reportThread(thread, reason: "Post-session safety concern", details: trimmed)
        }
    }

    func match(for thread: ChatThread) -> MatchRecord? {
        matches.first { $0.id == thread.matchID }
    }

    func group(for thread: ChatThread) -> GroupListing? {
        guard let match = match(for: thread) else { return nil }
        return groups.first { $0.id == match.groupID }
    }

    func party(for thread: ChatThread) -> PartyListing? {
        guard let match = match(for: thread) else { return nil }
        return parties.first { $0.id == match.partyID }
    }

    func candidateComparisonRows() -> [OrganizerComparisonRow] {
        groupBrowseCandidates.prefix(8).map { candidate in
            let party = candidate.entry
            return OrganizerComparisonRow(
                name: party.name,
                fitScore: candidate.score,
                size: MatchingService.partySizeLabel(party.partySize),
                availability: party.schedule.isEmpty ? "Flexible" : party.schedule,
                roles: party.rolesCovered.isEmpty ? "Roles open" : party.rolesCovered.map(\.label).joined(separator: ", "),
                mode: party.mode.label,
                notes: candidate.reasons.joined(separator: " | ")
            )
        }
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
        Task { await mirrorMatchThread(group: group, party: party, score: score, localMatchID: match.id) }
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

    private func mirrorGroup(_ listing: GroupListing) async {
        guard let repository else { return }
        do {
            _ = try await repository.save(group: listing)
            backendStatus = "Group synced"
        } catch {
            backendStatus = "Group sync failed: \(error.localizedDescription)"
        }
    }

    private func mirrorParty(_ listing: PartyListing) async {
        guard let repository else { return }
        do {
            _ = try await repository.save(party: listing)
            backendStatus = "Party synced"
        } catch {
            backendStatus = "Party sync failed: \(error.localizedDescription)"
        }
    }

    private func mirrorMessage(_ message: ChatMessage) async {
        guard let repository else { return }
        do {
            try await repository.send(message: message)
            backendStatus = "Message synced"
        } catch {
            backendStatus = "Message sync failed: \(error.localizedDescription)"
        }
    }

    private func mirrorReport(_ report: ReportRecord) async {
        guard let repository else { return }
        do {
            try await repository.report(report)
            backendStatus = "Report synced"
        } catch {
            backendStatus = "Report sync failed: \(error.localizedDescription)"
        }
    }

    private func mirrorBlock(_ block: BlockRecord) async {
        guard let repository else { return }
        do {
            try await repository.block(block)
            backendStatus = "Block synced"
        } catch {
            backendStatus = "Block sync failed: \(error.localizedDescription)"
        }
    }

    private func mirrorSwipe(ownerID: UUID, targetID: UUID, context: DecisionRecord.ViewContext, choice: DecisionRecord.Choice) async {
        guard let repository else { return }
        do {
            try await repository.recordSwipe(ownerID: ownerID, targetID: targetID, context: context, choice: choice)
            backendStatus = "Swipe synced"
        } catch {
            backendStatus = "Swipe sync failed: \(error.localizedDescription)"
        }
    }

    private func mirrorMatchThread(group: GroupListing, party: PartyListing, score: Int, localMatchID: UUID) async {
        guard let repository else { return }
        do {
            let created = try await repository.createMatchThread(groupID: group.id, partyID: party.id, score: score)
            if let matchIndex = matches.firstIndex(where: { $0.id == localMatchID }) {
                matches[matchIndex].id = created.matchID
            }
            if let threadIndex = threads.firstIndex(where: { $0.matchID == localMatchID }) {
                let oldThreadID = threads[threadIndex].id
                threads[threadIndex].id = created.threadID
                threads[threadIndex].matchID = created.matchID
                messages = messages.map { message in
                    var updated = message
                    if updated.threadID == oldThreadID { updated.threadID = created.threadID }
                    return updated
                }
            }
            backendStatus = "Match synced"
        } catch {
            backendStatus = "Match sync failed: \(error.localizedDescription)"
        }
    }

    private func mirrorModeration(subject: ReportRecord.Subject, listingID: UUID? = nil, messageID: UUID? = nil, result: ModerationResult) async {
        guard let repository else { return }
        do {
            try await repository.recordModeration(subject: subject, listingID: listingID, messageID: messageID, result: result)
            backendStatus = "Moderation event synced"
        } catch {
            backendStatus = "Moderation sync failed: \(error.localizedDescription)"
        }
    }

    private func isWithinDistance(
        ownerLatitude: Double?,
        ownerLongitude: Double?,
        targetLatitude: Double?,
        targetLongitude: Double?,
        maximumMiles: Double
    ) -> Bool {
        guard let ownerLatitude, let ownerLongitude, let targetLatitude, let targetLongitude else { return true }
        let distance = Self.distanceMiles(fromLatitude: ownerLatitude, fromLongitude: ownerLongitude, toLatitude: targetLatitude, toLongitude: targetLongitude)
        return distance <= maximumMiles
    }

    private static func distanceMiles(fromLatitude: Double, fromLongitude: Double, toLatitude: Double, toLongitude: Double) -> Double {
        let earthRadiusMiles = 3958.7613
        let lat1 = fromLatitude * .pi / 180
        let lat2 = toLatitude * .pi / 180
        let deltaLat = (toLatitude - fromLatitude) * .pi / 180
        let deltaLon = (toLongitude - fromLongitude) * .pi / 180
        let a = sin(deltaLat / 2) * sin(deltaLat / 2)
            + cos(lat1) * cos(lat2) * sin(deltaLon / 2) * sin(deltaLon / 2)
        return earthRadiusMiles * 2 * atan2(sqrt(a), sqrt(1 - a))
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
            feedback: feedback,
            savedSearches: savedSearches,
            sessionZero: sessionZero,
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

    private func upsertSavedSearch(_ search: SavedSearch) {
        savedSearches.removeAll { existing in
            existing.kind == search.kind && existing.name.localizedCaseInsensitiveCompare(search.name) == .orderedSame
        }
        savedSearches.insert(search, at: 0)
    }

    private func sanitizedSearchName(_ name: String?, fallback: String) -> String {
        let trimmed = (name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? fallback : trimmed
    }
}

struct OrganizerComparisonRow: Identifiable, Equatable {
    var id: String { name + availability + roles }
    var name: String
    var fitScore: Int
    var size: String
    var availability: String
    var roles: String
    var mode: String
    var notes: String
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
    var feedback: [PostSessionFeedback] = []
    var savedSearches: [SavedSearch] = []
    var sessionZero: SessionZeroProfile = SeedData.sessionZero
    var groupFilters: GroupBrowseFilters
    var partyFilters: PartyBrowseFilters
}
