// FILE: StreakUp/Views/TypewriterText.swift
import SwiftUI

struct TypewriterText: View {
    let text: String
    var charDelay: Double = 0.05
    @State private var visibleCount: Int = 0
    @State private var typingTask: Task<Void, Never>?

    var body: some View {
        Text(String(text.prefix(visibleCount)))
            .onAppear { start() }
            .onChange(of: text) { _, _ in start() }
            .onDisappear { typingTask?.cancel(); typingTask = nil }
    }

    @MainActor
    private func start() {
        typingTask?.cancel()
        typingTask = nil
        visibleCount = 0
        guard !text.isEmpty else { return }
        let total = text.count
        let delay = charDelay
        typingTask = Task { @MainActor in
            for i in 1...total {
                if Task.isCancelled { break }
                visibleCount = i
                if i < total {
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
                if Task.isCancelled { break }
            }
        }
    }
}
