import Foundation

enum SupabaseConfig {
    static let projectRef = "mczhglpdsoiipdqsbjsl"
    static let url = URL(string: "https://mczhglpdsoiipdqsbjsl.supabase.co")!
    static let publishableKey = "sb_publishable_WL8iL6IcAJORaSvIObzZYQ_zr8SamIL"

    static var isConfigured: Bool {
        !publishableKey.isEmpty && publishableKey.hasPrefix("sb_publishable_")
    }
}
