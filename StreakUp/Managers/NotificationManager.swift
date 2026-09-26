// FILE: StreakUp/Managers/NotificationManager.swift
import Foundation
import UserNotifications

@MainActor
final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    private init() {}

    @Published var isAuthorized: Bool = false

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted
            return granted
        } catch {
            return false
        }
    }

    func checkAuthorization() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    func scheduleDailyReminder(for habit: Habit, at time: Date) {
        let id = "habit-\(habit.id.uuidString)"
        let content = UNMutableNotificationContent()
        content.title = "StreakUp"
        content.body = "Time for \(habit.name)! Keep your streak going \u{1F525}"
        content.sound = .default

        let comps = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error { print("[Notifications] schedule error: \(error)") }
        }
    }

    func removeReminder(for habit: Habit) {
        let id = "habit-\(habit.id.uuidString)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }

    func removeAllReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
