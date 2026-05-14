import XCTest
@testable import QuestBond

final class MatchingServiceTests: XCTestCase {
    func testExactModeAndCapacityScoresHighly() {
        let group = GroupListing(
            name: "Test Table",
            mode: .online,
            location: "PST",
            openSlots: 2,
            campaignStyle: .storyHeavy,
            tableExperience: .intermediate,
            lookingForPartySize: .duo,
            desiredExperience: .intermediate,
            desiredRoles: [.healer],
            characterVibe: "Support-focused",
            schedule: "Fridays",
            about: "",
            contact: ""
        )

        let party = PartyListing(
            name: "Test Duo",
            partySize: 2,
            mode: .online,
            location: "PST",
            experience: .intermediate,
            rolesCovered: [.healer],
            lookingForCampaign: .storyHeavy,
            lookingForExperience: .intermediate,
            vibe: "",
            schedule: "Fridays",
            about: "",
            contact: ""
        )

        let result = MatchingService.score(group: group, party: party)

        XCTAssertGreaterThanOrEqual(result.score, 90)
        XCTAssertTrue(result.reasons.contains { $0.contains("Session type") })
    }

    func testModeFilterTreatsHybridAsOnlineAndInPerson() {
        XCTAssertTrue(MatchingService.matchesMode(.hybrid, filter: .online))
        XCTAssertTrue(MatchingService.matchesMode(.hybrid, filter: .inPerson))
        XCTAssertFalse(MatchingService.matchesMode(.online, filter: .inPerson))
    }

    func testQueryMatchesAcrossProvidedValues() {
        XCTAssertTrue(MatchingService.matchesQuery("seattle", values: ["Nightglass", "Seattle, WA"]))
        XCTAssertFalse(MatchingService.matchesQuery("austin", values: ["Nightglass", "Seattle, WA"]))
    }
}
