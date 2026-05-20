import Foundation

final class SupabaseAuthService: AuthServicing {
    private let client: SupabaseClient
    private(set) var currentSession: SupabaseSession?

    var currentUserID: UUID? { currentSession?.user.id }

    init(client: SupabaseClient = SupabaseClient()) {
        self.client = client
    }

    func signInWithApple() async throws {
        throw SupabaseClientError.requestFailed(501, "Sign in with Apple requires Apple Developer configuration before enabling in Supabase Auth.")
    }

    func signIn(email: String, password: String) async throws {
        currentSession = try await client.signIn(email: email, password: password)
    }

    func signUp(email: String, password: String, displayName: String) async throws {
        currentSession = try await client.signUp(email: email, password: password, displayName: displayName)
    }

    func signOut() async throws {
        currentSession = nil
    }

    func deleteAccount() async throws {
        guard let accessToken = currentSession?.accessToken else { throw SupabaseClientError.missingSession }
        try await client.deleteAccount(reason: "User requested account deletion", accessToken: accessToken)
        currentSession = nil
    }
}

final class SupabaseQuestBondRepository {
    private let client: SupabaseClient
    private let accessTokenProvider: () -> String?
    private let userIDProvider: () -> UUID?

    init(
        client: SupabaseClient = SupabaseClient(),
        accessTokenProvider: @escaping () -> String?,
        userIDProvider: @escaping () -> UUID? = { nil }
    ) {
        self.client = client
        self.accessTokenProvider = accessTokenProvider
        self.userIDProvider = userIDProvider
    }

    func loadProfile() async throws -> UserProfile {
        try await client.fetchProfile(accessToken: requireAccessToken()).profile
    }

    func loadListings() async throws -> ([GroupListing], [PartyListing]) {
        let listings = try await client.fetchListings(accessToken: requireAccessToken())
        let groups = listings.filter { $0.listingType == "group" }.map(\.groupListing)
        let parties = listings.filter { $0.listingType == "party" }.map(\.partyListing)
        return (groups, parties)
    }

    func save(group: GroupListing) async throws -> GroupListing {
        guard let userID = userIDProvider() else { throw SupabaseClientError.missingSession }
        let created = try await client.createListing(group.payload(ownerUserID: userID), accessToken: requireAccessToken())
        try await client.createRoles(group.desiredRoles.map { SupabaseRolePayload(listingID: created.id ?? group.id, role: $0.rawValue, roleKind: "desired") }, accessToken: requireAccessToken())
        return created.groupListing
    }

    func save(party: PartyListing) async throws -> PartyListing {
        guard let userID = userIDProvider() else { throw SupabaseClientError.missingSession }
        let created = try await client.createListing(party.payload(ownerUserID: userID), accessToken: requireAccessToken())
        try await client.createRoles(party.rolesCovered.map { SupabaseRolePayload(listingID: created.id ?? party.id, role: $0.rawValue, roleKind: "covered") }, accessToken: requireAccessToken())
        return created.partyListing
    }

    func send(message: ChatMessage) async throws {
        guard let userID = userIDProvider() else { throw SupabaseClientError.missingSession }
        let moderation = ModerationService().evaluate([message.text])
        _ = try await client.createMessage(
            SupabaseMessagePayload(
                id: message.id,
                threadID: message.threadID,
                senderUserID: userID,
                body: message.text,
                moderationStatus: moderation.status.rawValue
            ),
            accessToken: requireAccessToken()
        )
    }

    func block(_ block: BlockRecord) async throws {
        guard let userID = userIDProvider() else { throw SupabaseClientError.missingSession }
        try await client.createBlock(
            SupabaseBlockPayload(blockerUserID: userID, blockedListingID: nil, reason: "\(block.blockedName): \(block.reason)"),
            accessToken: requireAccessToken()
        )
    }

    func report(_ report: ReportRecord) async throws {
        guard let userID = userIDProvider() else { throw SupabaseClientError.missingSession }
        try await client.createReport(
            SupabaseReportPayload(
                reporterUserID: userID,
                subject: report.subject.rawValue,
                targetListingID: nil,
                targetMessageID: nil,
                reason: report.reason,
                details: "\(report.targetName)\n\(report.details)"
            ),
            accessToken: requireAccessToken()
        )
    }

    func recordSwipe(ownerID: UUID, targetID: UUID, context: DecisionRecord.ViewContext, choice: DecisionRecord.Choice) async throws {
        guard let userID = userIDProvider() else { throw SupabaseClientError.missingSession }
        try await client.createSwipe(
            SupabaseSwipePayload(
                swiperUserID: userID,
                ownerListingID: ownerID,
                targetListingID: targetID,
                choice: choice.rawValue,
                context: context == .groupBrowsing ? "group_browsing" : "party_browsing"
            ),
            accessToken: requireAccessToken()
        )
    }

    private func requireAccessToken() throws -> String {
        guard let accessToken = accessTokenProvider(), !accessToken.isEmpty else {
            throw SupabaseClientError.missingSession
        }
        return accessToken
    }
}

extension SupabaseProfilePayload {
    var profile: UserProfile {
        UserProfile(
            id: id,
            displayName: displayName,
            handle: handle ?? "@adventurer",
            location: location,
            latitude: latitude,
            longitude: longitude,
            bio: bio,
            favoriteRole: PartyRole(rawValue: favoriteRole) ?? .support,
            preferredMode: SessionMode(rawValue: preferredMode) ?? .any,
            safetyNote: safetyNote
        )
    }
}

extension UserProfile {
    func payload(userID: UUID) -> SupabaseProfilePayload {
        SupabaseProfilePayload(
            id: userID,
            displayName: displayName,
            handle: handle,
            bio: bio,
            location: location,
            latitude: latitude,
            longitude: longitude,
            experience: "new",
            preferredMode: preferredMode.rawValue,
            favoriteRole: favoriteRole.rawValue,
            safetyNote: safetyNote
        )
    }
}

extension SupabaseListingPayload {
    var groupListing: GroupListing {
        GroupListing(
            id: id ?? UUID(),
            name: name,
            mode: SessionMode(rawValue: mode) ?? .any,
            location: location,
            latitude: latitude,
            longitude: longitude,
            openSlots: openSlots,
            campaignStyle: CampaignStyle(rawValue: campaignStyle) ?? .any,
            tableExperience: ExperienceLevel(rawValue: tableExperience) ?? .any,
            lookingForPartySize: PartySizePreference(rawValue: lookingForPartySize) ?? .any,
            desiredExperience: ExperienceLevel(rawValue: desiredExperience) ?? .any,
            desiredRoles: [],
            characterVibe: characterVibe,
            schedule: schedule,
            about: about,
            contact: contact
        )
    }

    var partyListing: PartyListing {
        PartyListing(
            id: id ?? UUID(),
            name: name,
            partySize: partySize,
            mode: SessionMode(rawValue: mode) ?? .any,
            location: location,
            latitude: latitude,
            longitude: longitude,
            experience: ExperienceLevel(rawValue: tableExperience) ?? .any,
            rolesCovered: [],
            lookingForCampaign: CampaignStyle(rawValue: campaignStyle) ?? .any,
            lookingForExperience: ExperienceLevel(rawValue: desiredExperience) ?? .any,
            vibe: characterVibe,
            schedule: schedule,
            about: about,
            contact: contact
        )
    }
}

extension GroupListing {
    func payload(ownerUserID: UUID) -> SupabaseListingPayload {
        SupabaseListingPayload(
            id: id,
            ownerUserID: ownerUserID,
            listingType: "group",
            name: name,
            mode: mode.rawValue,
            location: location,
            latitude: latitude,
            longitude: longitude,
            openSlots: openSlots,
            partySize: 1,
            campaignStyle: campaignStyle.rawValue,
            tableExperience: tableExperience.rawValue,
            desiredExperience: desiredExperience.rawValue,
            lookingForPartySize: lookingForPartySize.rawValue,
            characterVibe: characterVibe,
            schedule: schedule,
            about: about,
            contact: contact,
            isActive: true
        )
    }
}

extension PartyListing {
    func payload(ownerUserID: UUID) -> SupabaseListingPayload {
        SupabaseListingPayload(
            id: id,
            ownerUserID: ownerUserID,
            listingType: "party",
            name: name,
            mode: mode.rawValue,
            location: location,
            latitude: latitude,
            longitude: longitude,
            openSlots: 0,
            partySize: partySize,
            campaignStyle: lookingForCampaign.rawValue,
            tableExperience: experience.rawValue,
            desiredExperience: lookingForExperience.rawValue,
            lookingForPartySize: "any",
            characterVibe: vibe,
            schedule: schedule,
            about: about,
            contact: contact,
            isActive: true
        )
    }
}
