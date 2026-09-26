// FILE: StreakUp/Views/TodayView.swift
import SwiftUI
import SwiftData
import UIKit

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.createdAt, order: .forward) private var habits: [Habit]
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var showAddSheet = false

    private var completedCount: Int {
        habits.filter { $0.isCompletedToday }.count
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning \u{1F44B}"
        case 12..<17: return "Good afternoon \u{1F44B}"
        default: return "Good evening \u{1F44B}"
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMM"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: Date())
    }

    private var isIPad: Bool {
        horizontalSizeClass == .regular
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(alignment: .leading, spacing: 4) {
                            Text(greeting)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(.primary)
                            Text(formattedDate)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                        // Progress ring
                        if !habits.isEmpty {
                            ProgressRingView(completed: completedCount, total: habits.count)
                                .padding(.vertical, 8)
                        }

                        // Habits grid / list
                        if habits.isEmpty {
                            emptyState
                        } else {
                            habitsGrid
                        }
                    }
                    .padding(.bottom, 90)
                }

                // FAB
                Button {
                    showAddSheet = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "#5F27CD"), Color(hex: "#FF6B9D")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)
                            .shadow(color: Color(hex: "#5F27CD").opacity(0.35), radius: 10, x: 0, y: 6)

                        Image(systemName: "plus")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAddSheet) {
                AddHabitSheet()
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Habits Grid

    @ViewBuilder
    private var habitsGrid: some View {
        if isIPad {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(habits) { habit in
                    HabitCard(habit: habit)
                        .contextMenu {
                            Button(role: .destructive) {
                                deleteHabit(habit)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .padding(.horizontal, 16)
        } else {
            LazyVStack(spacing: 12) {
                ForEach(habits) { habit in
                    HabitCard(habit: habit)
                        .contextMenu {
                            Button(role: .destructive) {
                                deleteHabit(habit)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("\u{1F33F}")
                .font(.system(size: 56))
            Text("No habits yet")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.primary)
            Text("Tap the + button to add your first habit and start building streaks.")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                showAddSheet = true
            } label: {
                Text("Add Habit")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(
                        Capsule().fill(Color(hex: "#5F27CD"))
                    )
            }
            .padding(.top, 4)
        }
        .padding(.top, 40)
    }

    private func deleteHabit(_ habit: Habit) {
        withAnimation {
            modelContext.delete(habit)
            try? modelContext.save()
        }
    }
}

#Preview {
    TodayView()
        .modelContainer(for: [Habit.self, HabitCompletion.self], inMemory: true)
}
