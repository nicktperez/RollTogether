import SwiftUI

@main
struct QuestBondApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = QuestBondStore()
    private let crashReporting = SentryCrashReportingService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .task {
                    crashReporting.configure()
                    await NotificationRegistrationService.shared.configure()
                }
        }
    }
}
