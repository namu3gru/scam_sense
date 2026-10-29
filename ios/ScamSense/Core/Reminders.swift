import Foundation
import UserNotifications

/// Daily "Spot the Scam" reminder. Permission is asked only when the person turns it on
/// (after finishing a quiz, or in Settings) - never at launch.
enum Reminders {
    static let id = "daily-quiz"

    static func enable(hour: Int, minute: Int) async -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        guard granted else { return false }
        center.removePendingNotificationRequests(withIdentifiers: [id])
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Today's Spot the Scam is ready")
        content.body = String(localized: "5 quick questions to keep your scam radar sharp. Keep your streak going!")
        content.sound = .default
        var when = DateComponents()
        when.hour = hour
        when.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: when, repeats: true)
        try? await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        return true
    }

    static func disable() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }

    static func isUndetermined() async -> Bool {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus == .notDetermined
    }
}
