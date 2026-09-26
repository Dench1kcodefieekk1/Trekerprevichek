// FILE: StreakUp/Views/FloatingTabBar.swift
import SwiftUI

enum AppTab: String, CaseIterable, Hashable {
    case today = "Today"
    case stats = "Stats"
    var icon: String {
        switch self {
        case .today: return "house.fill"
        case .stats: return "chart.bar.fill"
        }
    }
    var outlineIcon: String {
        switch self {
        case .today: return "house"
        case .stats: return "chart.bar"
        }
    }
}

struct FloatingTabBar: View {
    @Binding var selected: AppTab
    @Namespace private var tabNS

    var body: some View {
        HStack(spacing: 6) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                let isActive = selected == tab
                Button {
                    withAnimation(Glass.spring) { selected = tab }
                    Haptics.light()
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: isActive ? tab.icon : tab.outlineIcon)
                            .font(.system(size: 16, weight: .semibold))
                        Text(tab.rawValue)
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(isActive ? Accent.purple : Color.secondary)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 11)
                    .background {
                        if isActive {
                            Capsule(style: .continuous)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    Capsule(style: .continuous)
                                        .stroke(Color.white.opacity(0.22), lineWidth: 0.5)
                                )
                                .shadow(color: Accent.purple.opacity(0.18), radius: 10, x: 0, y: 4)
                                .matchedGeometryEffect(id: "activeTab", in: tabNS)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(7)
        .background(
            Capsule(style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(Color.white.opacity(Glass.tabBarBorderOpacity), lineWidth: 0.5)
                )
        )
        .shadow(color: .black.opacity(0.12), radius: Glass.tabBarShadowRadius, x: 0, y: 12)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        .frame(width: 280)
    }
}
