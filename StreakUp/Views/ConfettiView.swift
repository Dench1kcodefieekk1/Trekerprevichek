// FILE: StreakUp/Views/ConfettiView.swift
import SwiftUI

// MARK: - Burst from a point (checkmark)

struct ConfettiBurstView: View {
    var color: Color
    @State private var animate = false

    private struct Particle: Identifiable {
        let id = UUID()
        let x: CGFloat
        let y: CGFloat
        let color: Color
        let size: CGFloat
        let delay: Double
    }

    private func particles() -> [Particle] {
        let base: [Color] = [color, color.opacity(0.85), Accent.purple, Accent.pink, Color(hex: "#FECA57"), Color(hex: "#1DD1A1")]
        return (0..<7).map { i in
            let angle = Double(i) / 7 * 360 - 20
            let rad = angle * .pi / 180
            let dist: CGFloat = CGFloat.random(in: 44...78)
            return Particle(
                x: cos(rad) * dist,
                y: sin(rad) * dist - CGFloat.random(in: 18...36),
                color: base[i % base.count],
                size: CGFloat.random(in: 6...10),
                delay: Double(i) * 0.03
            )
        }
    }

    var body: some View {
        let items = particles()
        ZStack {
            ForEach(items) { p in
                Circle()
                    .fill(p.color)
                    .frame(width: p.size, height: p.size)
                    .offset(x: animate ? p.x : 0, y: animate ? p.y : 0)
                    .opacity(animate ? 0 : 1)
                    .animation(.easeOut(duration: 0.62).delay(p.delay), value: animate)
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            withAnimation { animate = true }
        }
    }
}

// MARK: - Full-screen rain

struct ConfettiRainView: View {
    @State private var animate = false
    var body: some View {
        GeometryReader { geo in
            let cols = 22
            ZStack {
                ForEach(0..<cols, id: \.self) { i in
                    let x = geo.size.width * CGFloat(i) / CGFloat(cols) + CGFloat.random(in: -8...8)
                    let colors: [Color] = [Accent.purple, Accent.pink, Color(hex:"#FECA57"), Color(hex:"#48DBFB"), Color(hex:"#1DD1A1"), Color(hex:"#FF6B6B")]
                    let c = colors[i % colors.count]
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(c)
                        .frame(width: CGFloat.random(in: 8...14), height: CGFloat.random(in: 6...10))
                        .rotationEffect(.degrees(animate ? Double.random(in: 360...720) : 0))
                        .position(x: x, y: animate ? geo.size.height + 60 : -40)
                        .animation(
                            .easeIn(duration: Double.random(in: 1.2...1.9))
                            .delay(Double(i) * 0.04),
                            value: animate
                        )
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear { animate = true }
    }
}

// MARK: - Milestone overlay

struct MilestoneOverlay: View {
    let streak: Int
    var onDismiss: () -> Void

    @State private var scale: CGFloat = 0.6
    @State private var glow = false

    private var info: (emoji: String, title: String) {
        if let m = Milestone.milestone(for: streak) { return (m.emoji, m.title) }
        return ("\u{1F389}", "\(streak) Day Streak!")
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            ConfettiRainView()
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text(info.emoji)
                    .font(.system(size: 72))
                    .scaleEffect(scale)
                    .shadow(color: Accent.pink.opacity(glow ? 0.9 : 0.35), radius: glow ? 28 : 12)
                Text("\(streak)")
                    .font(.system(size: 56, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                Text("\u{1F389} \(info.title)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.92))
                    .multilineTextAlignment(.center)
                Text("Keep it going!")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(Color.white.opacity(0.22), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.25), radius: 30, x: 0, y: 16)
            .scaleEffect(scale)
            .padding(.horizontal, 24)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) { scale = 1 }
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) { glow = true }
            Haptics.success()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { onDismiss() }
        }
    }
}
