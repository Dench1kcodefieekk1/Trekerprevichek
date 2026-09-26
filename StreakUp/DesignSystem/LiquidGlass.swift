// FILE: StreakUp/DesignSystem/LiquidGlass.swift
import SwiftUI
import UIKit

// MARK: - Liquid Glass Design Tokens (iOS 26 — back-ported to iOS 17 via Materials)

enum Glass {
    // Corner radii
    static let cardRadius: CGFloat = 16
    static let buttonRadius: CGFloat = 12
    static let pillRadius: CGFloat = 28
    static let fabSize: CGFloat = 56

    // Spacing
    static let horizontalPadding: CGFloat = 16
    static let cardSpacing: CGFloat = 12

    // Materials
    static let cardMaterial: Material = .regularMaterial
    static let tabBarMaterial: Material = .ultraThinMaterial
    static let sheetMaterial: Material = .ultraThickMaterial
    static let fieldMaterial: Material = .regularMaterial

    // Borders
    static let glassBorderOpacity: Double = 0.15
    static let glassBorderWidth: CGFloat = 0.5
    static let tabBarBorderOpacity: Double = 0.20

    // Shadows
    static let cardShadowRadius: CGFloat = 12
    static let tabBarShadowRadius: CGFloat = 20

    // Animation defaults
    static let spring = Animation.spring(response: 0.4, dampingFraction: 0.75)
    static let snappy = Animation.spring(response: 0.3, dampingFraction: 0.6)
    static let smooth = Animation.easeInOut(duration: 0.5)
}

// MARK: - Accent

enum Accent {
    static let purple = Color(hex: "#5F27CD")
    static let pink = Color(hex: "#FF6B9D")
    static let gradient = LinearGradient(
        colors: [purple, pink],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let ringGradient = AngularGradient(
        gradient: Gradient(colors: [purple, pink]),
        center: .center,
        startAngle: .degrees(-90),
        endAngle: .degrees(270)
    )
}

// MARK: - View Helpers

extension View {
    /// Liquid Glass card background: .regularMaterial + white inner border + shadow
    func liquidGlassCard(color: Color = .clear, cornerRadius: CGFloat = Glass.cardRadius) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Glass.cardMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(Glass.glassBorderOpacity), lineWidth: Glass.glassBorderWidth)
            )
    }

    /// Colored shadow matched to habit color
    func habitShadow(color: Color) -> some View {
        self.shadow(color: color.opacity(0.30), radius: Glass.cardShadowRadius, x: 0, y: 6)
    }

    /// Shimmer sweep overlay (used for idle shimmer)
    func shimmer(active: Bool = true) -> some View {
        self.modifier(ShimmerModifier(active: active))
    }
}

// Centralized haptics
enum Haptics {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let g = UIImpactFeedbackGenerator(style: style)
        g.prepare()
        g.impactOccurred()
    }
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    static func heavy() { impact(.heavy) }
    static func medium() { impact(.medium) }
    static func soft() { impact(.soft) }
    static func light() { impact(.light) }
}

// MARK: - Shimmer Modifier

struct ShimmerModifier: ViewModifier {
    var active: Bool
    @State private var move: Bool = false

    func body(content: Content) -> some View {
        content
            .overlay {
                if active {
                    GeometryReader { geo in
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.35), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geo.size.width * 0.4)
                        .offset(x: move ? geo.size.width * 1.2 : -geo.size.width * 0.4)
                        .blendMode(.overlay)
                    }
                    .mask(content)
                }
            }
            .onAppear {
                guard active else { return }
                withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                    move = true
                }
            }
    }
}

// MARK: - Wiggle Modifier

struct WiggleModifier: ViewModifier {
    var active: Bool
    @State private var wiggling = false

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(active ? (wiggling ? 2 : -2) : 0))
            .animation(
                active ? .easeInOut(duration: 0.14).repeatForever(autoreverses: true) : .default,
                value: wiggling
            )
            .onAppear { if active { wiggling = true } }
            .onChange(of: active) { _, new in
                wiggling = new
            }
    }
}

extension View {
    func wiggle(_ active: Bool) -> some View {
        modifier(WiggleModifier(active: active))
    }
}
