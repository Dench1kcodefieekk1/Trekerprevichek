// FILE: StreakUp/Models/Habit.swift
import SwiftUI
import SwiftData
import Foundation

@Model
final class Habit {
    @Attribute(.unique) var id: UUID
    var name: String
    var emoji: String
    var colorHex: String
    var createdAt: Date
    /// Optional daily reminder time (local time). Nil = no reminder.
    var reminderTime: Date?

    @Relationship(deleteRule: .cascade, inverse: \HabitCompletion.habit)
    var completions: [HabitCompletion]

    init(
        id: UUID = UUID(),
        name: String,
        emoji: String,
        colorHex: String,
        createdAt: Date = Date(),
        reminderTime: Date? = nil,
        completions: [HabitCompletion] = []
    ) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.colorHex = colorHex
        self.createdAt = createdAt
        self.reminderTime = reminderTime
        self.completions = completions
    }

    // MARK: - Color Helpers

    var color: Color {
        Color(hex: colorHex)
    }

    var lightBackgroundColor: Color {
        color.opacity(0.15)
    }

    /// Lighter tint for gradient end
    var lightColor: Color {
        color.opacity(0.55)
    }

    // MARK: - Date Helpers

    private var calendar: Calendar { Calendar.current }

    private func startOfDay(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    private var completionDays: Set<Date> {
        Set(completions.map { startOfDay($0.date) })
    }

    // MARK: - Computed Properties

    var isCompletedToday: Bool {
        completionDays.contains(startOfDay(Date()))
    }

    var currentStreak: Int {
        let today = startOfDay(Date())
        var streak = 0
        var cursor = today
        while completionDays.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }

    var longestStreak: Int {
        let sortedDays = completionDays.sorted()
        guard !sortedDays.isEmpty else { return 0 }
        var maxStreak = 1
        var current = 1
        for i in 1..<sortedDays.count {
            let prev = sortedDays[i - 1]
            let curr = sortedDays[i]
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: prev) else { continue }
            if calendar.isDate(curr, inSameDayAs: nextDay) {
                current += 1
                maxStreak = max(maxStreak, current)
            } else {
                current = 1
            }
        }
        return maxStreak
    }

    var totalCompletions: Int { completions.count }

    // MARK: - Helpers

    func isCompleted(on date: Date) -> Bool {
        completionDays.contains(startOfDay(date))
    }

    func toggleToday() {
        let today = startOfDay(Date())
        if let index = completions.firstIndex(where: { startOfDay($0.date) == today }) {
            completions.remove(at: index)
        } else {
            let completion = HabitCompletion(date: today, habit: self)
            completions.append(completion)
        }
    }
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
    func toHex() -> String { "#000000" }
}

// MARK: - Milestones

enum Milestone: Int, CaseIterable {
    case three = 3, seven = 7, fourteen = 14, thirty = 30, hundred = 100
    var emoji: String {
        switch self {
        case .three: return "\u{1F331}" // 🌱
        case .seven: return "\u{1F525}" // 🔥
        case .fourteen: return "\u{26A1}" // ⚡
        case .thirty: return "\u{1F3C6}" // 🏆
        case .hundred: return "\u{1F451}" // 👑
        }
    }
    var title: String { "\(rawValue) Day Streak!" }
    static func milestone(for streak: Int) -> Milestone? {
        Milestone(rawValue: streak)
    }
}
