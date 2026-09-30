import Foundation
import UserNotifications

// STEP 9: Watering alerts, one per plant.
// Each plant gets its own notification on the day it's next due, at 9 AM.
// Whenever anything changes (you water, add, edit, or delete a plant), we
// wipe the old alerts and schedule fresh ones from the current list.
// Like TRUNCATE + INSERT instead of updating rows one by one: simple, and
// nothing can get out of sync.

enum WateringAlerts {
    static let alertHour = 9   // 9 AM

    // TESTING: set to true to make every alert fire a few seconds from now
    // (put the app in the background to see them). Set back to false after.
    static let testMode = false

    // Returns true if notifications are allowed, so the screen can say so.
    @discardableResult
    static func reschedule(_ plants: [Plant]) async -> Bool {
        let center = UNUserNotificationCenter.current()

        // The first time, iOS shows the "Allow notifications?" popup.
        // After that it just returns the answer you gave.
        let allowed = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        guard allowed else { return false }

        center.removeAllPendingNotificationRequests()

        for (index, plant) in plants.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = "Time to water \(plant.displayName) 💧"
            content.body = "\(plant.room.label) · every \(plant.waterEveryDays) days"
            content.sound = .default

            let trigger: UNNotificationTrigger
            if testMode {
                trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5 + Double(index) * 5, repeats: false)
            } else {
                let parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute],
                                                            from: alertDate(for: plant))
                trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
            }

            // The ID must be unique per plant. dateAdded never changes, so it works as a key.
            let id = "water-\(plant.dateAdded.timeIntervalSince1970)"
            try? await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        }
        return true
    }

    // 9 AM on the plant's due day. If that's already passed (it's overdue),
    // remind at the next 9 AM instead.
    static func alertDate(for plant: Plant) -> Date {
        let calendar = Calendar.current
        let now = Date()
        let dueAt9 = calendar.date(bySettingHour: alertHour, minute: 0, second: 0, of: plant.nextWatering) ?? plant.nextWatering
        if dueAt9 > now { return dueAt9 }

        let todayAt9 = calendar.date(bySettingHour: alertHour, minute: 0, second: 0, of: now) ?? now
        return todayAt9 > now ? todayAt9 : calendar.date(byAdding: .day, value: 1, to: todayAt9) ?? todayAt9
    }
}
