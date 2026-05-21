import Foundation

enum SeedData {
    static let currentUser = UserProfile(
        displayName: "Nick",
        handle: "@questmaker",
        location: "Los Angeles, CA",
        latitude: 34.0522,
        longitude: -118.2437,
        bio: "Looking for thoughtful tables, reliable schedules, and players who enjoy story as much as dice.",
        favoriteRole: .support,
        preferredMode: .hybrid,
        safetyNote: "Session Zero first, clear expectations, and respectful table culture."
    )

    static let sessionZero = SessionZeroProfile()

    static let groups: [GroupListing] = [
        GroupListing(
            name: "The Ashen Vault",
            mode: .online,
            location: "EST",
            openSlots: 2,
            campaignStyle: .storyHeavy,
            tableExperience: .intermediate,
            lookingForPartySize: .duo,
            desiredExperience: .any,
            desiredRoles: [.healer, .face],
            characterVibe: "High-drama heroes and morally grey support casters.",
            schedule: "Wednesdays 8 PM EST",
            about: "Long-form political fantasy campaign with character-focused arcs.",
            contact: "Discord: AshenDM#1142"
        ),
        GroupListing(
            name: "Sunmarket Delvers",
            mode: .inPerson,
            location: "Austin, TX",
            openSlots: 3,
            campaignStyle: .heroic,
            tableExperience: .new,
            lookingForPartySize: .trio,
            desiredExperience: .new,
            desiredRoles: [.tank, .support],
            characterVibe: "Classic fantasy party energy with big set-piece battles.",
            schedule: "Saturdays 2 PM CST",
            about: "Beginner-friendly in-person table focused on teamwork and exploration.",
            contact: "sunmarket.table@gmail.com"
        ),
        GroupListing(
            name: "Mirrorspine Pact",
            mode: .hybrid,
            location: "Seattle, WA / PST",
            openSlots: 1,
            campaignStyle: .gritty,
            tableExperience: .veteran,
            lookingForPartySize: .single,
            desiredExperience: .veteran,
            desiredRoles: [.controller, .scout],
            characterVibe: "Low-magic intrigue, stealth, and consequences.",
            schedule: "Sundays 6 PM PST",
            about: "Serious tone, difficult choices, and tactical encounters.",
            contact: "DM via Discord: mirrorspine"
        )
    ]

    static let parties: [PartyListing] = [
        PartyListing(
            name: "Amber Duo",
            partySize: 2,
            mode: .online,
            location: "CST / EST",
            experience: .intermediate,
            rolesCovered: [.tank, .damage],
            lookingForCampaign: .storyHeavy,
            lookingForExperience: .intermediate,
            vibe: "Paladin + bard duo who love roleplay and heists.",
            schedule: "Weekdays after 7 PM CST",
            about: "Reliable duo looking for a long campaign and strong table chemistry.",
            contact: "Discord: AmberDuo"
        ),
        PartyListing(
            name: "Silver Rookie",
            partySize: 1,
            mode: .inPerson,
            location: "Austin, TX",
            experience: .new,
            rolesCovered: [.support],
            lookingForCampaign: .heroic,
            lookingForExperience: .new,
            vibe: "Cleric player brand new to 5e and eager to learn.",
            schedule: "Saturday afternoons",
            about: "Looking for a welcoming table with patient players.",
            contact: "Email: silverrookie@example.com"
        ),
        PartyListing(
            name: "Nightglass Trio",
            partySize: 3,
            mode: .hybrid,
            location: "Seattle, WA",
            experience: .veteran,
            rolesCovered: [.scout, .controller, .face],
            lookingForCampaign: .gritty,
            lookingForExperience: .veteran,
            vibe: "Stealth-heavy operators with tactical combat focus.",
            schedule: "Sundays after 5 PM PST",
            about: "Three veteran players seeking difficult encounters and meaningful choices.",
            contact: "Discord: Nightglass"
        ),
        PartyListing(
            name: "Chaos Squad",
            partySize: 4,
            mode: .online,
            location: "US Time Zones",
            experience: .intermediate,
            rolesCovered: [.tank, .healer, .damage, .face],
            lookingForCampaign: .comedy,
            lookingForExperience: .any,
            vibe: "Light-hearted improvisers who still show up prepared.",
            schedule: "Fridays 9 PM EST",
            about: "Looking for a DM that enjoys big personalities and creative plans.",
            contact: "Discord: chaos.squad"
        )
    ]
}
