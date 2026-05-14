import Foundation

protocol CrashReporting {
    func configure()
    func record(error: Error, context: String)
}

struct SentryCrashReportingService: CrashReporting {
    func configure() {
        // Add Sentry SDK initialization here once the DSN is available.
    }

    func record(error: Error, context: String) {
        // Forward nonfatal errors to Sentry in production builds.
    }
}
