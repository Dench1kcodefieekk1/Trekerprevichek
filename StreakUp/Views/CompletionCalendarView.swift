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
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        f.locale = Locale(identifier: "en_US")
        return f.string(from: currentMonth)
    }

    private var daysInMonth: [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: currentMonth),
              let first = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)) else { return [] }
        let weekday = calendar.component(.weekday, from: first) // 1=Sun
        let leading = (weekday + 5) % 7 // Mon=0
        var days: [Date?] = Array(repeating: nil, count: leading)
        for d in range {
            if let date = calendar.date(byAdding: .day, value: d - 1, to: first) {
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
            // Header
            HStack {
                Button { withAnimation(Glass.spring) { shiftMonth(-1) } } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(.ultraThinMaterial))
                }.buttonStyle(.plain)
                Spacer()
                Text(monthTitle)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                Spacer()
                Button { withAnimation(Glass.spring) { shiftMonth(1) } } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(.ultraThinMaterial))
                }.buttonStyle(.plain)
            }

            // Weekday letters
            HStack(spacing: 0) {
                ForEach(["M","T","W","T","F","S","S"], id: \.self) { ch in
                    Text(ch).font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 8) {
                ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, day in
                    if let day {
                        let isToday = calendar.isDateInToday(day)
                        let completed = isCompleted(on: day)
                        let selected = selectedDay.map { calendar.isDate($0, inSameDayAs: day) } ?? false
                        Button {
                            withAnimation(Glass.spring) {
                                selectedDay = selected ? nil : day
                            }
                            Haptics.light()
                        } label: {
                            VStack(spacing: 4) {
                                Text("\(calendar.component(.day, from: day))")
                                    .font(.system(size: 13, weight: isToday ? .bold : .medium))
                                    .foregroundStyle(isToday ? Accent.purple : .primary)
                                Circle()
                                    .fill(completed ? dotColor(for: day) : Color.gray.opacity(0.14))
                                    .frame(width: 8, height: 8)
                                    .overlay {
                                        if completed && habitsDone(on: day).count > 1 {
                                            Circle().stroke(Color.white.opacity(0.9), lineWidth: 1).frame(width: 8, height: 8)
                                        }
                                    }
                            }
                            .frame(height: 44)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(selected ? Accent.purple.opacity(0.14) : Color.clear)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(selected ? Accent.purple.opacity(0.4) : Color.clear, lineWidth: 1)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(isToday ? Accent.purple.opacity(0.5) : Color.clear, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    } else {
                        Color.clear.frame(height: 44)
                    }
                }
            }
            .offset(x: dragOffset)
            .gesture(
                DragGesture(minimumDistance: 30, coordinateSpace: .local)
                    .onEnded { v in
                        if v.translation.width < -60 { withAnimation(Glass.spring) { shiftMonth(1) } }
                        else if v.translation.width > 60 { withAnimation(Glass.spring) { shiftMonth(-1) } }
                    }
            )

            // Tooltip
            if let sel = selectedDay {
                let done = habitsDone(on: sel)
                VStack(alignment: .leading, spacing: 6) {
                    let f = DateFormatter(); f.dateStyle = .medium; f.locale = Locale(identifier: "en_US")
                    Text(f.string(from: sel)).font(.system(size: 12, weight: .semibold)).foregroundStyle(.secondary)
                    if done.isEmpty {
                        Text("No habits completed").font(.system(size: 13)).foregroundStyle(.secondary)
                    } else {
                        ForEach(done) { h in
                            HStack(spacing: 6) {
                                Text(h.emoji).font(.system(size: 13))
                                Text(h.name).font(.system(size: 13, weight: .medium))
                                Circle().fill(h.color).frame(width: 6, height: 6)
                                Spacer()
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(h.color).font(.system(size: 13))
                            }
                        }
                    }
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.regularMaterial)
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.15), lineWidth: 0.5)))
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: Glass.cardRadius, style: .continuous)
                .fill(Glass.cardMaterial)
                .overlay(RoundedRectangle(cornerRadius: Glass.cardRadius, style: .continuous).stroke(Color.white.opacity(0.15), lineWidth: 0.5))
        )
    }

    private func shiftMonth(_ delta: Int) {
        if let next = calendar.date(byAdding: .month, value: delta, to: currentMonth) {
            currentMonth = next
            selectedDay = nil
        }
    }
}
