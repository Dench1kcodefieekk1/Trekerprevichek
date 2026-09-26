// FILE: StreakUp/Views/ProgressRingView.swift
import SwiftUI

struct ProgressRingView: View {
    let completed: Int
    let total: Int
    /// Optional per-habit color gradient; falls back to app accent
    var gradientColors: [Color]? = nil

    private var progress: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }
    private var percentageText: String {
        guard total > 0 else { return "0%" }
        return "\(Int(progress * 100))%"
    }

    @State private var draw: CGFloat = 0
    @State private var glow: CGFloat = 8

    private var ringGradient: AngularGradient {
        if let g = gradientColors, g.count >= 2 {
            return AngularGradient(gradient: Gradient(colors: g), center: .center, startAngle: .degrees(-90), endAngle: .degrees(270))
        }
        return Accent.ringGradient
    }

    var body: some View {
        ZStack {
            // Track — ultraThinMaterial circle stroke (simulated via stroke on material-blurred circle)
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 140, height: 140)
                .overlay(Circle().stroke(Color.white.opacity(0.18), lineWidth: 1))
                .overlay(Circle().stroke(Color.gray.opacity(0.12), lineWidth: 14).padding(0))
                .clipShape(Circle())

            // Progress arc
            Circle()
                .trim(from: 0, to: draw)
                .stroke(ringGradient, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: (gradientColors?.first ?? Accent.purple).opacity(0.45), radius: glow, x: 0, y: 0)
                .frame(width: 140, height: 140)

            VStack(spacing: 2) {
                Text(percentageText)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
                Text("\(completed)/\(total) done")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
            }
        }
        .frame(width: 140, height: 140)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9)) { draw = CGFloat(progress) }
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                glow = 16
            }
        }
        .onChange(of: progress) { _, new in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) { draw = CGFloat(new) }
        }
    }
}

#Preview {
    VStack(spacing: 32) {
        ProgressRingView(completed: 0, total: 5)
        ProgressRingView(completed: 3, total: 5)
        ProgressRingView(completed: 5, total: 5)
    }
}
