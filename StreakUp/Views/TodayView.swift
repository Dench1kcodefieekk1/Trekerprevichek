// FILE: StreakUp/Views/TodayView.swift
import SwiftUI
import SwiftData
import UIKit

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.createdAt, order: .forward) private var habits: [Habit]
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    @State private var showAddSheet = false
    @State private var appear = false
    @State private var isEditMode = false
    @State private var milestoneStreak: Int?
    @State private var showAllDoneRain = false
    @State private var fabPressed = false
    @State private var habitOrder: [UUID] = []

    private var completedCount: Int { habits.filter { $0.isCompletedToday }.count }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning \u{1F44B}"
        case 12..<17: return "Good afternoon \u{1F44B}"
        default: return "Good evening \u{1F44B}"
        }
    }
    private var formattedDate: String {
        let f = DateFormatter(); f.dateFormat = "EEEE, d MMM"; f.locale = Locale(identifier: "en_US")
        return f.string(from: Date())
    }
    private var isIPad: Bool { horizontalSizeClass == .regular }
    private var isLandscape: Bool { verticalSizeClass == .compact }

    // iPad: 3 cols landscape, 2 cols portrait; iPhone: list
    private var gridColumns: [GridItem] {
        if !isIPad { return [] }
        let count = isLandscape ? 3 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 12), count: count)
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(spacing: 20) {
                        header
                        if !habits.isEmpty {
                            ProgressRingView(completed: completedCount, total: habits.count)
                                .padding(.vertical, 8)
                                .opacity(appear ? 1 : 0)
                                .offset(y: appear ? 0 : 10)
                                .animation(.easeOut(duration: 0.5).delay(0.12), value: appear)
                        }
                        if habits.isEmpty {
                            emptyState
                        } else {
                            habitsGrid
                        }
                    }
                    .padding(.bottom, 96)
                }

                fab
            }
            .navigationBarHidden(true)
            .toolbar {
                if !habits.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(isEditMode ? "Done" : "Edit") {
                            withAnimation(Glass.spring) { isEditMode.toggle() }
                            Haptics.soft()
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Accent.purple)
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddHabitSheet()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .onAppear {
                withAnimation { appear = true }
            }
            .overlay {
                if let streak = milestoneStreak {
                    MilestoneOverlay(streak: streak) { milestoneStreak = nil }
                }
            }
            .overlay {
                if showAllDoneRain {
                    ConfettiRainView()
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }
            }
        }
    }

    // MARK: - Header with typewriter

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            TypewriterText(text: greeting, charDelay: 0.05)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            Text(formattedDate)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Habits Grid

    @ViewBuilder
    private var habitsGrid: some View {
        let items = Array(habits.enumerated())
        Group {
            if isIPad {
                LazyVGrid(columns: gridColumns, spacing: 12) {
                    ForEach(items, id: \.element.id) { idx, habit in
                        card(for: habit, index: idx)
                    }
                }
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(items, id: \.element.id) { idx, habit in
                        card(for: habit, index: idx)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private func card(for habit: Habit, index: Int) -> some View {
        HabitCard(
            habit: habit,
            isEditMode: isEditMode,
            onToggle: {
                handleToggle(habit)
            },
            onDelete: {
                deleteHabit(habit)
            }
        )
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 14)
        .animation(.spring(response: 0.4, dampingFraction: 0.75).delay(Double(index) * 0.05), value: appear)
        .contextMenu {
            Button(role: .destructive) { deleteHabit(habit) } label: { Label("Delete", systemImage: "trash") }
            Button { withAnimation(Glass.spring) { isEditMode.toggle() } } label: { Label(isEditMode ? "Done Editing" : "Reorder", systemImage: "arrow.up.arrow.down") }
        }
        .onTapGesture {} // for swipe hit-testing
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.45).onEnded { _ in
                withAnimation(Glass.spring) { isEditMode.toggle() }
                Haptics.soft()
            }
        )
    }

    private func handleToggle(_ habit: Habit) {
        let willComplete = !habit.isCompletedToday
        // before toggle streak
        let prevStreak = habit.currentStreak

        // SwiftData: toggle mutates habit.completions — need to trigger milestone after toggle
        // Use small delay to let SwiftData update
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            if willComplete {
                let newStreak = habit.currentStreak
                if let _ = Milestone.milestone(for: newStreak) {
                    milestoneStreak = newStreak
                }
                // All done?
                let allDone = habits.allSatisfy { $0.isCompletedToday }
                if allDone && habits.count > 1 {
                    withAnimation { showAllDoneRain = true }
                    Haptics.success()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation { showAllDoneRain = false }
                    }
                }
            }
        }
        // Re-sort order is by createdAt — no reorder needed on toggle
        _ = prevStreak
    }

    // MARK: - FAB (Liquid Glass + rotation when sheet open)

    private var fab: some View {
        Button {
            showAddSheet = true
        } label: {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: Glass.fabSize, height: Glass.fabSize)
                    .overlay(Circle().stroke(Color.white.opacity(0.22), lineWidth: 0.8))
                    .shadow(color: Accent.purple.opacity(0.28), radius: 14, x: 0, y: 8)
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Accent.gradient)
                    .rotationEffect(.degrees(showAddSheet ? 45 : 0))
                    .animation(.spring(response: 0.38, dampingFraction: 0.72), value: showAddSheet)
            }
        }
        .scaleEffect(fabPressed ? 0.92 : 1)
        .animation(.spring(response: 0.28, dampingFraction: 0.72), value: fabPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in fabPressed = true }
                .onEnded { _ in fabPressed = false }
        )
        .padding(.trailing, 20)
        .padding(.bottom, 20)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("\u{1F33F}").font(.system(size: 56))
            Text("No habits yet").font(.system(size: 20, weight: .semibold)).foregroundStyle(.primary)
            Text("Tap the + button to add your first habit and start building streaks.")
                .font(.system(size: 15)).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal, 32)
            Button { showAddSheet = true } label: {
                Text("Add Habit").font(.system(size: 16, weight: .semibold)).foregroundStyle(.white)
                    .padding(.horizontal, 28).padding(.vertical, 12)
                    .background(Capsule().fill(Accent.purple))
            }.padding(.top, 4)
        }.padding(.top, 40)
    }

    private func deleteHabit(_ habit: Habit) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            modelContext.delete(habit)
            try? modelContext.save()
        }
    }
}

#Preview {
    TodayView().modelContainer(for: [Habit.self, HabitCompletion.self], inMemory: true)
}
