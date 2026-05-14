import UIKit
import UserNotifications

@MainActor
final class NotificationRegistrationService {
    static let shared = NotificationRegistrationService()

    private(set) var deviceToken: String?

    private init() {}

    func configure() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            guard granted else { return }
            UIApplication.shared.registerForRemoteNotifications()
        } catch {
            // Keep notification setup non-blocking during onboarding and local prototyping.
        }
    }

    func updateDeviceToken(_ token: Data) {
        deviceToken = token.map { String(format: "%02.2hhx", $0) }.joined()
    }
}
