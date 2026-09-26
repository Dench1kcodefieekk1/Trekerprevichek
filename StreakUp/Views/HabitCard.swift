// FILE: StreakUp/Views/HabitCard.swift
import SwiftUI
import UIKit

struct HabitCard: View {
    @Bindable var habit: Habit
    var isEditMode: Bool = false
    var onToggle: (() -> Void)?
    var onDelete: (() -> Void)?

    // Swipe-to-delete
    @State private var dragX: CGFloat = 0
    @State private var showDeleteConfirm = false
    @State private var isRemoving = false

    // Animations
    @State private var bounce: CGFloat = 1
    @State private var showBurst = false
    @State private var checkScale: CGFloat = 1

    var body: some View {
        ZStack(alignment: .trailing) {
            // Delete background
            deleteBackground

            // Card content (draggable for swipe)
            cardContent
                .offset(x: dragX)
                .offset(y: 0)
                .scaleEffect(bounce)
                .scaleEffect(isRemoving ? 0.85 : 1)
                .opacity(isRemoving ? 0 : 1)
                .wiggle(isEditMode)
                .animation(Glass.spring, value: dragX)
                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: bounce)
                .gesture(swipeGesture, including: .gesture)
        }
        .clipShape(RoundedRectangle(cornerRadius: Glass.cardRadius, style: .continuous))
        .habitShadow(color: habit.color)
        .overlay(alignment: .topTrailing) {
            if showBurst {
                ConfettiBurstView(color: habit.color)
                    .offset(x: -22, y: 28)
            }
        }
        .alert("Delete Habit?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) { confirmDelete() }
            Button("Cancel", role: .cancel) { withAnimation(Glass.spring) { dragX = 0 } }
        } message: {
            Text("Delete \"\(habit.name)\"? This cannot be undone.")
        }
    }

    // MARK: - Card Content (Liquid Glass)

    private var cardContent: some View {
        HStack(spacing: 14) {
            // Left accent bar
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(habit.color)
                .frame(width: 4)
                .padding(.vertical, 10)

            // Emoji circle
            ZStack {
                Circle().fill(habit.color).frame(width: 48, height: 48)
                Text(habit.emoji).font(.system(size: 24))
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
                        .contentTransition(.numericText())
                } else {
                    Text("No streak yet — start today!")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if isEditMode {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(.trailing, 4)
            } else {
                // Checkmark button
                Button { toggle() } label: {
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
                    .scaleEffect(checkScale)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 12)
        .padding(.leading, 2)
        .background(
            RoundedRectangle(cornerRadius: Glass.cardRadius, style: .continuous)
                .fill(Glass.cardMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: Glass.cardRadius, style: .continuous)
                        .stroke(Color.white.opacity(Glass.glassBorderOpacity), lineWidth: Glass.glassBorderWidth)
                )
        )
    }

    private var deleteBackground: some View {
        HStack {
            Spacer()
            Button(role: .destructive) { showDeleteConfirm = true } label: {
                Label("Delete", systemImage: "trash.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 86, height: 76)
                    .background(RoundedRectangle(cornerRadius: Glass.cardRadius, style: .continuous).fill(Color.red))
            }
            .buttonStyle(.plain)
            .padding(.trailing, 2)
        }
        .background(RoundedRectangle(cornerRadius: Glass.cardRadius, style: .continuous).fill(Color.red.opacity(0.92)))
    }

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 18, coordinateSpace: .local)
            .onChanged { v in
                guard !isEditMode else { return }
                let tx = v.translation.width
                if tx < 0 { dragX = max(tx, -88) }
                else if dragX < 0 { dragX = max(tx - 88, -88) }
            }
            .onEnded { v in
                guard !isEditMode else { return }
                let tx = v.translation.width
                if tx < -52 {
                    withAnimation(Glass.spring) { dragX = -86 }
                } else if tx > 44 && dragX < 0 {
                    withAnimation(Glass.spring) { dragX = 0 }
                } else if dragX < 0 && tx > -20 {
                    // tap to close handled via background tap
                }
            }
    }

    // MARK: - Actions

    private func toggle() {
        let willComplete = !habit.isCompletedToday
        Haptics.medium()

        withAnimation(.spring(response: 0.32, dampingFraction: 0.58)) {
            habit.toggleToday()
            bounce = 1.04
            checkScale = 1.18
        }
        if willComplete {
            showBurst = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { showBurst = false }
        }
        onToggle?()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.58)) {
                bounce = 1
                checkScale = 1
            }
        }
        // Return drag if open
        if dragX != 0 {
            withAnimation(Glass.spring) { dragX = 0 }
        }
    }

    private func confirmDelete() {
        Haptics.heavy()
        withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) { isRemoving = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
            onDelete?()
        }
    }
}
