// FILE: StreakUp/Views/TypewriterText.swift
import SwiftUI

struct TypewriterText: View {
    let text: String
    var charDelay: Double = 0.05
    @State private var visibleCount: Int = 0
    @State private var timer: Timer?

    var body: some View {
        Text(String(text.prefix(visibleCount)))
            .onAppear { start() }
            .onChange(of: text) { _, _ in start() }
            .onDisappear { timer?.invalidate() }
    }

    private func start() {
        timer?.invalidate()
        visibleCount = 0
        guard !text.isEmpty else { return }
        timer = Timer.scheduledTimer(withTimeInterval: charDelay, repeats: true) { t in
            if visibleCount < text.count {
                visibleCount += 1
            } else {
                t.invalidate()
            }
        }
        if let timer { RunLoop.main.add(timer, forMode: .common) }
    }
}
