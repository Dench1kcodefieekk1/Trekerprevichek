// FILE: StreakUp/Models/HabitCompletion.swift
import SwiftData
import Foundation

@Model
final class HabitCompletion {
    @Attribute(.unique) var id: UUID
    var date: Date
    var habit: Habit?

    init(id: UUID = UUID(), date: Date, habit: Habit? = nil) {
        self.id = id
        // Always store stripped to start-of-day
        self.date = Calendar.current.startOfDay(for: date)
        self.habit = habit
    }
}
