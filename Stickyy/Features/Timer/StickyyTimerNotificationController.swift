@preconcurrency import UserNotifications

final class StickyyTimerNotificationController: NSObject,
    UNUserNotificationCenterDelegate, @unchecked Sendable {
    static let shared = StickyyTimerNotificationController()

    private let center = UNUserNotificationCenter.current()

    private override init() {
        super.init()
        center.delegate = self
    }

    func prepare() {
        center.delegate = self
    }

    func requestAuthorizationIfNeeded() {
        center.getNotificationSettings { [center] settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            center.requestAuthorization(options: [.alert, .sound]) { _, error in
                if let error {
                    NSLog(
                        "Stickyy notification permission failed: %@",
                        error.localizedDescription
                    )
                }
            }
        }
    }

    func notifyTimerFinished() {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Stickyy Timer")
        content.body = String(localized: "Time is up. Your thought is still here.")
        content.sound = .default

        center.add(
            UNNotificationRequest(
                identifier: "Stickyy.Timer.\(UUID().uuidString)",
                content: content,
                trigger: nil
            )
        ) { error in
            if let error {
                NSLog(
                    "Stickyy timer notification failed: %@",
                    error.localizedDescription
                )
            }
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }
}
