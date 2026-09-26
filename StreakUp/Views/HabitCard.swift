// FILE: StreakUp/Views/HabitCard.swift
import SwiftUI
import UIKit

struct HabitCard: View {
    @Bindable var habit: Habit
    var onToggle: (() -> Void)?

    @State private var isPressed = false

    var body: some View {
        HStack(spacing: 14) {
            // Emoji circle
            ZStack {
                Circle()
                    .fill(habit.color)
                    .frame(width: 48, height: 48)
                Text(habit.emoji)
                    .font(.system(size: 24))
            }

            // Name + streak
            VStack(alignment: .leading, spacing: 3) {
                Text(habit.name)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                if habit.currentStreak > 0 {
                    Text("\u{1F525} \(habit.currentStreak) day streak")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                } else {
                    Text("No streak yet — start today!")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Checkmark button
            Button {
                toggle()
            } label: {
                ZStack {
                    Circle()
                        .strokeBorder(habit.isCompletedToday ? Color.clear : Color.gray.opacity(0.35), lineWidth: 2)
                        .background(Circle().fill(habit.isCompletedToday ? habit.color : Color.clear))
                        .frame(width: 36, height: 36)

                    if habit.isCompletedToday {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .scaleEffect(isPressed ? 1.15 : 1.0)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(habit.lightBackgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(habit.color.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    }

    private func toggle() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()

        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            habit.toggleToday()
            isPressed = true
        }

        onToggle?()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = false
            }
        }
    }
}
