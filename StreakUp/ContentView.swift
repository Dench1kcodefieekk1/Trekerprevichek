// FILE: StreakUp/ContentView.swift
import SwiftUI

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var selectedTab: AppTab = .today

    private var isIPad: Bool { horizontalSizeClass == .regular }

    var body: some View {
        Group {
            if isIPad {
                iPadLayout
            } else {
                iPhoneLayout
            }
        }
        .tint(Accent.purple)
    }

    // MARK: - iPhone (floating pill tab bar)

    private var iPhoneLayout: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .today: TodayView()
                case .stats: StatsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(.asymmetric(
                insertion: .move(edge: .bottom).combined(with: .opacity),
                removal: .move(edge: .top).combined(with: .opacity)
            ))
            .id(selectedTab)
            .animation(Glass.spring, value: selectedTab)

            FloatingTabBar(selected: $selectedTab)
                .padding(.bottom, 12)
        }
        .ignoresSafeArea(.keyboard)
    }

    // MARK: - iPad (NavigationSplitView sidebar)

    private var iPadLayout: some View {
        NavigationSplitView {
            List(selection: $selectedTab) {
                ForEach(AppTab.allCases, id: \.self) { tab in
                    NavigationLink(value: tab) {
                        Label(tab.rawValue, systemImage: selectedTab == tab ? tab.icon : tab.outlineIcon)
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .listRowBackground(selectedTab == tab ? Accent.purple.opacity(0.14) : Color.clear)
                }
            }
            .navigationTitle("StreakUp")
            .listStyle(.sidebar)
        } detail: {
            Group {
                switch selectedTab {
                case .today: TodayView()
                case .stats: StatsView()
                }
            }
            .id(selectedTab)
            .transition(.opacity.combined(with: .move(edge: .top)))
            .animation(Glass.spring, value: selectedTab)
        }
    }
}

#Preview {
    ContentView().modelContainer(for: [Habit.self, HabitCompletion.self], inMemory: true)
}
