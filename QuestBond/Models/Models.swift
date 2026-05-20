import Foundation

enum SessionMode: String, Codable, CaseIterable, Identifiable {
    case any
    case online
    case inPerson
    case hybrid

    var id: String { rawValue }

    var label: String {
        switch self {
        case .any: "Any"
        case .online: "Online"
        case .inPerson: "In-Person"
        case .hybrid: "Hybrid"
        }
    }

    var icon: String {
        switch self {
        case .any: "sparkles"
        case .online: "network"
        case .inPerson: "mappin.and.ellipse"
        case .hybrid: "arrow.triangle.2.circlepath"
        }
    }
}

enum ExperienceLevel: String, Codable, CaseIterable, Identifiable {
    case any
    case new
    case intermediate
    case veteran

    var id: String { rawValue }

    var label: String {
        switch self {
        case .any: "Any"
        case .new: "New"
        case .intermediate: "Intermediate"
        case .veteran: "Veteran"
        }
    }
}

enum CampaignStyle: String, Codable, CaseIterable, Identifiable {
    case any
    case heroic
    case gritty
    case sandbox
    case storyHeavy
    case comedy
    case horror

    var id: String { rawValue }

    var label: String {
        switch self {
        case .any: "Any"
        case .heroic: "Heroic"
        case .gritty: "Gritty"
        case .sandbox: "Sandbox"
        case .storyHeavy: "Story-Heavy"
        case .comedy: "Comedy"
        case .horror: "Horror"
        }
    }
}

enum PartySizePreference: String, Codable, CaseIterable, Identifiable {
    case any
    case single
    case duo
    case trio
    case squad

    var id: String { rawValue }

    var label: String {
        switch self {
        case .any: "Any"
        case .single: "Single"
        case .duo: "Duo"
        case .trio: "Trio"
        case .squad: "4+"
        }
    }
}

enum PartyRole: String, Codable, CaseIterable, Identifiable {
    case tank
    case healer
    case damage
    case support
    case controller
    case face
    case scout

    var id: String { rawValue }

    var label: String {
        rawValue.prefix(1).uppercased() + rawValue.dropFirst()
    }
}

struct GroupListing: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var mode: SessionMode
    var location: String
    var latitude: Double? = nil
    var longitude: Double? = nil
    var openSlots: Int
    var campaignStyle: CampaignStyle
    var tableExperience: ExperienceLevel
    var lookingForPartySize: PartySizePreference
    var desiredExperience: ExperienceLevel
    var desiredRoles: [PartyRole]
    var characterVibe: String
    var schedule: String
    var about: String
    var contact: String
    var createdAt: Date = .now
}

struct PartyListing: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var partySize: Int
    var mode: SessionMode
    var location: String
    var latitude: Double? = nil
    var longitude: Double? = nil
    var experience: ExperienceLevel
    var rolesCovered: [PartyRole]
    var lookingForCampaign: CampaignStyle
    var lookingForExperience: ExperienceLevel
    var vibe: String
    var schedule: String
    var about: String
    var contact: String
    var createdAt: Date = .now
}

struct UserProfile: Identifiable, Codable, Equatable {
    var id = UUID()
    var displayName: String
    var handle: String
    var location: String
    var latitude: Double? = nil
    var longitude: Double? = nil
    var bio: String
    var favoriteRole: PartyRole
    var preferredMode: SessionMode
    var safetyNote: String
}

struct MatchRecord: Identifiable, Codable, Equatable {
    var id = UUID()
    var groupID: UUID
    var groupName: String
    var partyID: UUID
    var partyName: String
    var score: Int
    var initiatedBy: String
    var connectedAt: Date = .now
}

struct ChatThread: Identifiable, Codable, Equatable {
    var id = UUID()
    var matchID: UUID
    var groupName: String
    var partyName: String
    var score: Int
    var summary: String
    var updatedAt: Date = .now
}

struct ChatMessage: Identifiable, Codable, Equatable {
    enum Sender: String, Codable {
        case me
        case match
        case system
    }

    var id = UUID()
    var threadID: UUID
    var sender: Sender
    var text: String
    var createdAt: Date = .now
}

struct BlockRecord: Identifiable, Codable, Equatable {
    var id = UUID()
    var blockedName: String
    var reason: String
    var createdAt: Date = .now
}

struct ReportRecord: Identifiable, Codable, Equatable {
    enum Subject: String, Codable {
        case profile
        case listing
        case message
    }

    var id = UUID()
    var subject: Subject
    var targetName: String
    var reason: String
    var details: String
    var createdAt: Date = .now
}

struct DecisionRecord: Identifiable, Codable, Equatable {
    enum ViewContext: String, Codable {
        case groupBrowsing
        case partyBrowsing
    }

    enum Choice: String, Codable {
        case pass
        case connect
    }

    var id = UUID()
    var context: ViewContext
    var ownerID: UUID
    var targetID: UUID
    var choice: Choice
    var createdAt: Date = .now
}

struct GroupBrowseFilters: Codable, Equatable {
    var ownerID: UUID?
    var preMode: SessionMode = .any
    var preExperience: ExperienceLevel = .any
    var minimumPartySize = 1
    var maximumDistanceMiles = 50
    var postMode: SessionMode = .any
    var postCampaign: CampaignStyle = .any
    var query = ""
}

struct PartyBrowseFilters: Codable, Equatable {
    var ownerID: UUID?
    var preMode: SessionMode = .any
    var preCampaign: CampaignStyle = .any
    var minimumOpenSlots = 1
    var maximumDistanceMiles = 50
    var postMode: SessionMode = .any
    var postExperience: ExperienceLevel = .any
    var query = ""
}

struct Candidate<Entry: Identifiable> {
    var entry: Entry
    var score: Int
    var reasons: [String]
}
