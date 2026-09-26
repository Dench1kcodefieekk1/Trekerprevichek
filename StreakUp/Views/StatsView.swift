// FILE: StreakUp/Views/StatsView.swift
import SwiftUI
import SwiftData

struct StatsView: View {
    @Query(sort: \Habit.createdAt, order: .forward) private var habits: [Habit]
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var appear = false
    @State private var selectedCalendarHabit: Habit?

    private var totalHabits: Int { habits.count }
    private var completedToday: Int { habits.filter { $0.isCompletedToday }.count }
    private var bestStreak: Int { habits.map { $0.longestStreak }.max() ?? 0 }
    private var totalCompletions: Int { habits.reduce(0) { $0 + $1.completions.count } }
    private var isIPad: Bool { horizontalSizeClass == .regular }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    summaryGrid
                    if !habits.isEmpty {
                        habitDetails
                        weekSection
                        calendarSection
                    } else {
                        emptyState
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
            .navigationTitle("Your Stats")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear { withAnimation { appear = true } }
    }

    // MARK: - Summary (Liquid Glass + shimmer on appear)

    private var summaryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            statCard(value: "\(totalHabits)", label: "Total Habits", icon: "list.bullet", color: Accent.purple, delay: 0)
            statCard(value: "\(completedToday)", label: "Done Today", icon: "checkmark.circle.fill", color: Color(hex: "#1DD1A1"), delay: 0.08)
            statCard(value: "\(bestStreak)", label: "Best Streak", icon: "flame.fill", color: Color(hex: "#FF6B6B"), delay: 0.16)
            statCard(value: "\(totalCompletions)", label: "Total Done", icon: "star.fill", color: Color(hex: "#FF9F43"), delay: 0.24)
        }
        .padding(.horizontal, 16)
    }

    private func statCard(value: String, label: String, icon: String, color: Color, delay: Double) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack { Image(systemName: icon).font(.system(size: 14, weight: .semibold)).foregroundStyle(color); Spacer() }
            Text(value).font(.system(size: 28, weight: .bold, design: .rounded)).foregroundStyle(.primary).contentTransition(.numericText())
            Text(label).font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: Glass.cardRadius, style: .continuous)
                .fill(Glass.cardMaterial)
                .overlay(RoundedRectangle(cornerRadius: Glass.cardRadius, style: .continuous).stroke(Color.white.opacity(0.15), lineWidth: 0.5))
                .overlay(RoundedRectangle(cornerRadius: Glass.cardRadius, style: .continuous).stroke(color.opacity(0.10), lineWidth: 1))
        )
        .shadow(color: color.opacity(0.12), radius: 10, x: 0, y: 6)
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 10)
        .animation(.spring(response: 0.4, dampingFraction: 0.75).delay(delay), value: appear)
        .overlay {
            if appear {
                GeometryReader { geo in
                    LinearGradient(colors: [.clear, .white.opacity(0.28), .clear], startPoint: .leading, endPoint: .trailing)
                        .frame(width: geo.size.width * 0.45)
                        .offset(x: appear ? geo.size.width : -geo.size.width * 0.45)
                        .animation(.easeInOut(duration: 0.9).delay(delay + 0.2), value: appear)
                }
                .clipShape(RoundedRectangle(cornerRadius: Glass.cardRadius, style: .continuous))
                .blendMode(.overlay)
                .allowsHitTesting(false)
            }
        }
    }

    // MARK: - Habit Details

    private var habitDetails: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Habit Details").font(.system(size: 20, weight: .bold, design: .rounded)).padding(.horizontal, 16)
            LazyVStack(spacing: 10) {
                ForEach(Array(habits.enumerated()), id: \.element.id) { idx, habit in
                    habitDetailRow(habit: habit)
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 12)
                        .animation(.spring(response: 0.4, dampingFraction: 0.75).delay(Double(idx) * 0.05 + 0.3), value: appear)
                }
            }.padding(.horizontal, 16)
        }
    }

    private func habitDetailRow(habit: Habit) -> some View {
        HStack(spacing: 12) {
            ZStack { Circle().fill(habit.color).frame(width: 40, height: 40); Text(habit.emoji).font(.system(size: 20)) }
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) { Text(habit.name).font(.system(size: 15, weight: .semibold)).lineLimit(1); Circle().fill(habit.color).frame(width: 8, height: 8) }
                Text("\(habit.completions.count) completions").font(.system(size: 12)).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Label("\(habit.currentStreak)", systemImage: "flame.fill").font(.system(size: 13, weight: .bold)).foregroundStyle(habit.color).contentTransition(.numericText())
                Label("\(habit.longestStreak)", systemImage: "trophy.fill").font(.system(size: 13, weight: .medium)).foregroundStyle(.secondary).contentTransition(.numericText())
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: Glass.cardRadius, style: .continuous).fill(Glass.cardMaterial)
            .overlay(RoundedRectangle(cornerRadius: Glass.cardRadius, style: .continuous).stroke(Color.white.opacity(0.15), lineWidth: 0.5)))
        .habitShadow(color: habit.color)
    }

    // MARK: - This Week

    private var weekSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week").font(.system(size: 20, weight: .bold, design: .rounded)).padding(.horizontal, 16)
            ForEach(habits) { habit in weeklyGridRow(habit: habit) }
        }.padding(.horizontal, 16)
    }

    private func weeklyGridRow(habit: Habit) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) { Text(habit.emoji); Text(habit.name).font(.system(size: 14, weight: .semibold)).lineLimit(1); Spacer() }
            let weekDays = weekDates()
            let dayLetters = ["M","T","W","T","F","S","S"]
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { idx in
                    VStack(spacing: 6) {
                        Text(dayLetters[idx]).font(.system(size: 11, weight: .medium)).foregroundStyle(.secondary).frame(maxWidth: .infinity)
                        ZStack {
                            Circle().fill(habit.isCompleted(on: weekDays[idx]) ? habit.color : Color.gray.opacity(0.15)).frame(width: 32, height: 32)
                            if habit.isCompleted(on: weekDays[idx]) {
                                Image(systemName: "checkmark").font(.system(size: 11, weight: .bold)).foregroundStyle(.white)
                            }
                        }.frame(maxWidth: .infinity)
                        Text(dayNumberString(for: weekDays[idx])).font(.system(size: 10, weight: .medium)).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: Glass.cardRadius, style: .continuous).fill(Glass.cardMaterial)
            .overlay(RoundedRectangle(cornerRadius: Glass.cardRadius, style: .continuous).stroke(Color.white.opacity(0.15), lineWidth: 0.5)))
    }

    // MARK: - Calendar (new)

    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("History Calendar").font(.system(size: 20, weight: .bold, design: .rounded))
                Spacer()
                if isIPad {
                    Text("Swipe to change month").font(.system(size: 11, weight: .medium)).foregroundStyle(.secondary)
                }
            }.padding(.horizontal, 16)

            if isIPad {
                // side-by-side on iPad
                HStack(alignment: .top, spacing: 16) {
                    CompletionCalendarView(habits: Array(habits))
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tip").font(.system(size: 13, weight: .bold))
                        Text("Tap a day to see which habits were completed. Dots match habit colors.").font(.system(size: 12)).foregroundStyle(.secondary)
                        Divider().padding(.vertical, 4)
                        ForEach(habits.prefix(6)) { h in
                            HStack(spacing: 6) { Circle().fill(h.color).frame(width: 8, height: 8); Text(h.name).font(.system(size: 12, weight: .medium)).lineLimit(1) }
                        }
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Glass.cardMaterial)
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.15), lineWidth: 0.5)))
                    .frame(width: 200)
                }.padding(.horizontal, 16)
            } else {
                CompletionCalendarView(habits: Array(habits))
                    .padding(.horizontal, 16)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("\u{1F4CA}").font(.system(size: 48))
            Text("No stats yet").font(.system(size: 18, weight: .semibold))
            Text("Add habits and complete them to see your progress here.").font(.system(size: 14)).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }.frame(maxWidth: .infinity).padding(.top, 32)
    }

    private func weekDates() -> [Date] {
        let c = Calendar.current
        let today = Date()
        let weekday = c.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7
        guard let monday = c.date(byAdding: .day, value: -daysFromMonday, to: c.startOfDay(for: today)) else {
            return (0..<7).compactMap { c.date(byAdding: .day, value: $0, to: today) }
        }
        return (0..<7).compactMap { c.date(byAdding: .day, value: $0, to: monday) }
    }
    private func dayNumberString(for date: Date) -> String { "\(Calendar.current.component(.day, from: date))" }
}

#Preview {
    StatsView().modelContainer(for: [Habit.self, HabitCompletion.self], inMemory: true)
}
