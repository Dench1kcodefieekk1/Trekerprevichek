// FILE: StreakUp/Views/CompletionCalendarView.swift
import SwiftUI
import SwiftData

struct CompletionCalendarView: View {
    var habits: [Habit]

    @State private var currentMonth: Date = Date()
    @State private var selectedDay: Date?
    @State private var dragOffset: CGFloat = 0

    private var calendar: Calendar { Calendar.current }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: currentMonth)
    }

    private var daysInMonth: [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: currentMonth),
              let first = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)) else {
            return []
        }
        let weekday = calendar.component(.weekday, from: first)
        let leading = (weekday + 5) % 7
        var days: [Date?] = Array(repeating: nil, count: leading)
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: first) {
                days.append(date)
            }
        }
        return days
    }

    private func isCompleted(on day: Date) -> Bool {
        let start = calendar.startOfDay(for: day)
        return habits.contains { $0.isCompleted(on: start) }
    }

    private func habitsDone(on day: Date) -> [Habit] {
        let start = calendar.startOfDay(for: day)
        return habits.filter { $0.isCompleted(on: start) }
    }

    private func dotColor(for day: Date) -> Color {
        let done = habitsDone(on: day)
        if done.count == habits.count && !habits.isEmpty { return Accent.purple }
        return done.first?.color ?? .clear
    }

    var body: some View {
        VStack(spacing: 14) {
            headerView
            weekdayHeaderView
            gridView
            tooltipView
        }
        .padding(14)
        .background(cardBackground)
    }

    // MARK: - Subviews (broken out to avoid type-checker explosion)

    private var headerView: some View {
        HStack {
            monthButton(direction: -1, icon: "chevron.left")
            Spacer()
            Text(monthTitle)
                .font(.system(size: 16, weight: .bold, design: .rounded))
            Spacer()
            monthButton(direction: 1, icon: "chevron.right")
        }
    }

    private func monthButton(direction: Int, icon: String) -> some View {
        Button {
            withAnimation(Glass.spring) { shiftMonth(direction) }
        } label: {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 32, height: 32)
                .background(Circle().fill(.ultraThinMaterial))
        }
        .buttonStyle(.plain)
    }

    private var weekdayHeaderView: some View {
        HStack(spacing: 0) {
            ForEach(["M", "T", "W", "T", "F", "S", "S"], id: \.self) { ch in
                Text(ch)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var gridView: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 8) {
            ForEach(daysInMonth.indices, id: \.self) { idx in
                dayCell(at: idx)
            }
        }
        .offset(x: dragOffset)
        .gesture(swipeGesture)
    }

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 30, coordinateSpace: .local)
            .onEnded { value in
                if value.translation.width < -60 {
                    withAnimation(Glass.spring) { shiftMonth(1) }
                } else if value.translation.width > 60 {
                    withAnimation(Glass.spring) { shiftMonth(-1) }
                }
            }
    }

    @ViewBuilder
    private func dayCell(at index: Int) -> some View {
        if let day = daysInMonth[index] {
            let today = calendar.isDateInToday(day)
            let completed = isCompleted(on: day)
            let selected = isSelected(day)
            let color = dotColor(for: day)
            let multi = habitsDone(on: day).count > 1
            CalendarDayCell(
                day: day,
                isToday: today,
                isCompleted: completed,
                dotColor: color,
                isMulti: multi,
                isSelected: selected
            ) {
                withAnimation(Glass.spring) {
                    selectedDay = selected ? nil : day
                }
                Haptics.light()
            }
        } else {
            Color.clear.frame(height: 44)
        }
    }

    private func isSelected(_ day: Date) -> Bool {
        guard let sel = selectedDay else { return false }
        return calendar.isDate(sel, inSameDayAs: day)
    }

    @ViewBuilder
    private var tooltipView: some View {
        if let sel = selectedDay {
            let done = habitsDone(on: sel)
            VStack(alignment: .leading, spacing: 6) {
                Text(formattedDay(sel))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                if done.isEmpty {
                    Text("No habits completed")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(done) { habit in
                        HStack(spacing: 6) {
                            Text(habit.emoji).font(.system(size: 13))
                            Text(habit.name).font(.system(size: 13, weight: .medium))
                            Circle().fill(habit.color).frame(width: 6, height: 6)
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(habit.color)
                                .font(.system(size: 13))
                        }
                    }
                }
            }
            .padding(12)
            .background(tooltipBackground)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    private func formattedDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: date)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: Glass.cardRadius, style: .continuous)
            .fill(Glass.cardMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: Glass.cardRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
            )
    }

    private var tooltipBackground: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(.regularMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
            )
    }

    private func shiftMonth(_ delta: Int) {
        if let next = calendar.date(byAdding: .month, value: delta, to: currentMonth) {
            currentMonth = next
            selectedDay = nil
        }
    }
}

// MARK: - Day cell extracted to keep type-checker fast

private struct CalendarDayCell: View {
    let day: Date
    let isToday: Bool
    let isCompleted: Bool
    let dotColor: Color
    let isMulti: Bool
    let isSelected: Bool
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(dayNumber)
                    .font(.system(size: 13, weight: isToday ? .bold : .medium))
                    .foregroundStyle(isToday ? Accent.purple : .primary)
                dotView
            }
            .frame(height: 44)
            .frame(maxWidth: .infinity)
            .background(cellBackground)
            .overlay(selectedBorder)
            .overlay(todayBorder)
        }
        .buttonStyle(.plain)
    }

    private var dayNumber: String {
        "\(Calendar.current.component(.day, from: day))"
    }

    private var dotView: some View {
        Circle()
            .fill(isCompleted ? dotColor : Color.gray.opacity(0.14))
            .frame(width: 8, height: 8)
            .overlay {
                if isCompleted && isMulti {
                    Circle()
                        .stroke(Color.white.opacity(0.9), lineWidth: 1)
                        .frame(width: 8, height: 8)
                }
            }
    }

    private var cellBackground: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(isSelected ? Accent.purple.opacity(0.14) : Color.clear)
    }

    private var selectedBorder: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .stroke(isSelected ? Accent.purple.opacity(0.4) : Color.clear, lineWidth: 1)
    }

    private var todayBorder: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .stroke(isToday ? Accent.purple.opacity(0.5) : Color.clear, lineWidth: 1)
    }
}
