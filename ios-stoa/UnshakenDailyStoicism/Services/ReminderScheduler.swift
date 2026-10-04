import Foundation
import UserNotifications

/// Schedules the daily reading reminder as real local notifications,
/// each carrying the actual quote for the day it will fire.
@MainActor
enum ReminderScheduler {
    static func syncIfNeeded(progress: ProgressStore, content: ContentStore) async {
        if progress.state.reminderOn {
            await schedule(progress: progress, content: content)
        }
    }

    static func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        default:
            return false
        }
    }

    static func schedule(progress: ProgressStore, content: ContentStore) async {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        guard progress.state.reminderOn else { return }

        let granted = await requestPermission()
        guard granted else {
            progress.setReminder(on: false, hour: progress.state.reminderHour, minute: progress.state.reminderMinute)
            return
        }

        let calendar = Calendar.current
        let hour = progress.state.reminderHour
        let minute = progress.state.reminderMinute
        for offset in 0...6 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: Date())),
                  let entry = content.entry(for: day) else { continue }
            let dayComponents = calendar.dateComponents([.year, .month, .day], from: day)
            var fireDate = DateComponents()
            fireDate.year = dayComponents.year
            fireDate.month = dayComponents.month
            fireDate.day = dayComponents.day
            fireDate.hour = hour
            fireDate.minute = minute

            let content_ = UNMutableNotificationContent()
            content_.title = "Your daily Stoic reading"
            content_.body = "\(entry.quote) Two minutes for today's entry."
            content_.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: fireDate, repeats: false)
            let request = UNNotificationRequest(identifier: "stoa-daily-\(offset)", content: content_, trigger: trigger)
            try? await center.add(request)
        }
    }

    static func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
