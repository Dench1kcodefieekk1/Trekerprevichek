// FILE: StreakUp/Views/ProgressRingView.swift
import SwiftUI

struct ProgressRingView: View {
    let completed: Int
    let total: Int

    private var progress: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }

    private var percentageText: String {
        guard total > 0 else { return "0%" }
        return "\(Int(progress * 100))%"
    }

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.gray.opacity(0.15), lineWidth: 14)

            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [Color(hex: "#5F27CD"), Color(hex: "#FF6B9D")]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)

            // Center content
            VStack(spacing: 2) {
                Text(percentageText)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.5), value: completed)

                Text("\(completed)/\(total) done")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 140, height: 140)
    }
}

#Preview {
    VStack(spacing: 32) {
        ProgressRingView(completed: 0, total: 5)
        ProgressRingView(completed: 3, total: 5)
        ProgressRingView(completed: 5, total: 5)
    }
}
