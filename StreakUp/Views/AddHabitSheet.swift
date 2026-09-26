// FILE: StreakUp/Views/AddHabitSheet.swift
import SwiftUI
import SwiftData
import UIKit

struct AddHabitSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var speechRecognizer = SpeechRecognizer()

    @State private var habitName: String = ""
    @State private var selectedEmoji: String = "\u{1F4AA}"
    @State private var selectedColorHex: String = "#5F27CD"
    @State private var isPulsing: Bool = false
    @FocusState private var isTextFieldFocused: Bool

    // Preset data per spec
    private let emojis: [String] = [
        "\u{1F4AA}", "\u{1F3C3}", "\u{1F4DA}", "\u{1F4A7}", "\u{1F9D8}",
        "\u{1F34E}", "\u{1F634}", "\u{1F3AF}", "\u{270D}\u{FE0F}", "\u{1F3B5}",
        "\u{1F3CB}\u{FE0F}", "\u{1F6B4}", "\u{1F9E0}", "\u{1F48A}", "\u{1F33F}",
        "\u{2600}\u{FE0F}", "\u{1F6C1}", "\u{1F64F}", "\u{1F4BB}", "\u{1F3A8}"
    ]

    private let colorHexes: [String] = [
        "#FF6B6B", "#FF9F43", "#FECA57", "#48DBFB", "#FF9FF3",
        "#54A0FF", "#5F27CD", "#00D2D3", "#1DD1A1", "#C8D6E5"
    ]

    private var isValid: Bool {
        !habitName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Emoji picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Choose an emoji")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.secondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(emojis, id: \.self) { emoji in
                                    Button {
                                        selectedEmoji = emoji
                                    } label: {
                                        Text(emoji)
                                            .font(.system(size: 26))
                                            .frame(width: 48, height: 48)
                                            .background(
                                                Circle()
                                                    .fill(selectedEmoji == emoji ? Color(hex: selectedColorHex).opacity(0.2) : Color.gray.opacity(0.1))
                                            )
                                            .overlay(
                                                Circle()
                                                    .stroke(selectedEmoji == emoji ? Color(hex: selectedColorHex) : Color.clear, lineWidth: 2)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }

                    // Habit name field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Habit name")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.secondary)
                        HStack(spacing: 10) {
                            TextField("e.g. Morning run", text: $habitName)
                                .font(.system(size: 17))
                                .focused($isTextFieldFocused)
                                .autocorrectionDisabled(false)
                                .textInputAutocapitalization(.sentences)
                                .onChange(of: speechRecognizer.transcript) { _, newValue in
                                    if !newValue.isEmpty {
                                        habitName = newValue
                                    }
                                }

                            // Voice input button
                            Button {
                                withAnimation {
                                    speechRecognizer.toggleRecording()
                                }
                                if speechRecognizer.isRecording {
                                    isTextFieldFocused = false
                                }
                            } label: {
                                ZStack {
                                    if speechRecognizer.isRecording {
                                        Circle()
                                            .fill(Color.red.opacity(0.15))
                                            .frame(width: 40, height: 40)
                                            .scaleEffect(isPulsing ? 1.35 : 1.0)
                                            .opacity(isPulsing ? 0.3 : 0.6)
                                            .animation(
                                                .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                                                value: isPulsing
                                            )
                                    }
                                    Circle()
                                        .fill(speechRecognizer.isRecording ? Color.red : Color(hex: "#5F27CD"))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: speechRecognizer.isRecording ? "stop.fill" : "mic.fill")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(.white)
                                }
                            }
                            .buttonStyle(.plain)
                            .onChange(of: speechRecognizer.isRecording) { _, newValue in
                                isPulsing = newValue
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.gray.opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )

                        if speechRecognizer.isRecording {
                            Text("Listening... tap stop when done")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.red)
                        }
                    }

                    // Color picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Pick a color")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.secondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(colorHexes, id: \.self) { hex in
                                    Button {
                                        withAnimation(.spring(response: 0.3)) {
                                            selectedColorHex = hex
                                        }
                                    } label: {
                                        ZStack {
                                            Circle()
                                                .fill(Color(hex: hex))
                                                .frame(width: 44, height: 44)
                                                .shadow(color: Color(hex: hex).opacity(0.35), radius: 4, x: 0, y: 2)
                                            if selectedColorHex == hex {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 14, weight: .bold))
                                                    .foregroundStyle(.white)
                                                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                                            }
                                        }
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: selectedColorHex == hex ? 3 : 0)
                                        )
                                        .shadow(color: .black.opacity(selectedColorHex == hex ? 0.15 : 0), radius: 6, x: 0, y: 3)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }

                    // Preview card
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Preview")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.secondary)
                        HStack(spacing: 14) {
                            ZStack {
                                Circle().fill(Color(hex: selectedColorHex)).frame(width: 48, height: 48)
                                Text(selectedEmoji).font(.system(size: 24))
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                Text(habitName.isEmpty ? "Your habit" : habitName)
                                    .font(.system(size: 17, weight: .bold))
                                    .lineLimit(1)
                                Text("\u{1F525} 0 day streak")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            ZStack {
                                Circle()
                                    .strokeBorder(Color.gray.opacity(0.35), lineWidth: 2)
                                    .frame(width: 36, height: 36)
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(hex: selectedColorHex).opacity(0.15))
                        )
                    }

                    // Add button
                    Button {
                        addHabit()
                    } label: {
                        Text("Add Habit")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(isValid ? Color(hex: selectedColorHex) : Color.gray.opacity(0.3))
                            )
                    }
                    .disabled(!isValid)
                    .animation(.easeInOut(duration: 0.2), value: isValid)
                    .padding(.top, 4)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            .navigationTitle("New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                // Delay focus so sheet animation completes smoothly
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isTextFieldFocused = true
                }
            }
            .alert("Microphone Access", isPresented: $speechRecognizer.showPermissionAlert) {
                Button("OK", role: .cancel) {}
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            } message: {
                Text(speechRecognizer.errorMessage ?? "Permission required for voice input.")
            }
        }
    }

    private func addHabit() {
        let trimmed = habitName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let habit = Habit(
            name: trimmed,
            emoji: selectedEmoji,
            colorHex: selectedColorHex
        )
        modelContext.insert(habit)
        try? modelContext.save()

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        dismiss()
    }
}
