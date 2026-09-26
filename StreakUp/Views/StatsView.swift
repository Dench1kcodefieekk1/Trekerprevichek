// FILE: StreakUp/Views/StatsView.swift
import SwiftUI
import SwiftData

struct StatsView: View {
    @Query(sort: \Habit.createdAt, order: .forward) private var habits: [Habit]

    private var totalHabits: Int { habits.count }
    private var completedToday: Int { habits.filter { $0.isCompletedToday }.count }
    private var bestStreak: Int { habits.map { $0.longestStreak }.max() ?? 0 }
    private var totalCompletions: Int { habits.reduce(0) { $0 + $1.completions.count } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Summary cards grid (2 columns)
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        StatCard(value: "\(totalHabits)", label: "Total Habits", icon: "list.bullet", color: Color(hex: "#5F27CD"))
                        StatCard(value: "\(completedToday)", label: "Done Today", icon: "checkmark.circle.fill", color: Color(hex: "#1DD1A1"))
                        StatCard(value: "\(bestStreak)", label: "Best Streak", icon: "flame.fill", color: Color(hex: "#FF6B6B"))
                        StatCard(value: "\(totalCompletions)", label: "Total Done", icon: "star.fill", color: Color(hex: "#FF9F43"))
                    }
                    .padding(.horizontal, 16)

                    // Habit Details
                    if !habits.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Habit Details")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .padding(.horizontal, 16)

                            LazyVStack(spacing: 10) {
                                ForEach(habits) { habit in
                                    habitDetailRow(habit: habit)
                                }
                            }
                            .padding(.horizontal, 16)
                        }

                        // This Week
                        VStack(alignment: .leading, spacing: 12) {
                            Text("This Week")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .padding(.horizontal, 16)

                            ForEach(habits) { habit in
                                weeklyGridRow(habit: habit)
                            }
                        }
                        .padding(.horizontal, 16)
                    } else {
                        VStack(spacing: 12) {
                            Text("\u{1F4CA}")
                                .font(.system(size: 48))
                            Text("No stats yet")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Add habits and complete them to see your progress here.")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 32)
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .navigationTitle("Your Stats")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Habit Detail Row

    private func habitDetailRow(habit: Habit) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(habit.color).frame(width: 40, height: 40)
                Text(habit.emoji).font(.system(size: 20))
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(habit.name)
                        .font(.system(size: 15, weight: .semibold))
                        .lineLimit(1)
                    Circle()
                        .fill(habit.color)
                        .frame(width: 8, height: 8)
                }
                Text("\(habit.completions.count) completions")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Label("\(habit.currentStreak)", systemImage: "flame.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(habit.color)
                Label("\(habit.longestStreak)", systemImage: "trophy.fill")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.gray.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - Weekly Grid

    private func weeklyGridRow(habit: Habit) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(habit.emoji)
                Text(habit.name)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                Spacer()
            }

            // Day letters M T W T F S S
            let weekDays = weekDates()
            let dayLetters = ["M", "T", "W", "T", "F", "S", "S"]

            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { idx in
                    VStack(spacing: 6) {
                        Text(dayLetters[idx])
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)

                        ZStack {
                            Circle()
                                .fill(habit.isCompleted(on: weekDays[idx]) ? habit.color : Color.gray.opacity(0.15))
                                .frame(width: 32, height: 32)
                            if habit.isCompleted(on: weekDays[idx]) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)

                        Text(dayNumberString(for: weekDays[idx]))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // MARK: - Date Helpers

    private func weekDates() -> [Date] {
        let calendar = Calendar.current
        // Monday as start of week
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        // weekday: 1=Sun,2=Mon,...7=Sat  -> offset to Monday
        let daysFromMonday = (weekday + 5) % 7
        guard let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: calendar.startOfDay(for: today)) else {
            return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: today) }
        }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: monday) }
    }

    private func dayNumberString(for date: Date) -> String {
        let day = Calendar.current.component(.day, from: date)
        return "\(day)"
    }
}

// MARK: - Stat Card

private struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(color)
                Spacer()
            }
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(color.opacity(0.12), lineWidth: 1)
        )
    }
}

#Preview {
    StatsView()
        .modelContainer(for: [Habit.self, HabitCompletion.self], inMemory: true)
}
