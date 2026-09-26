// FILE: StreakUp/Views/AddHabitSheet.swift
import SwiftUI
import SwiftData
import UIKit
import UserNotifications

struct AddHabitSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var speechRecognizer = SpeechRecognizer()

    @State private var habitName: String = ""
    @State private var selectedEmoji: String = "\u{1F4AA}"
    @State private var selectedColorHex: String = "#5F27CD"
    @State private var isPulsing: Bool = false
    @State private var enableReminder: Bool = false
    @State private var reminderTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var shimmerMove: Bool = false
    @FocusState private var isTextFieldFocused: Bool

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
                    emojiPicker
                    nameField
                    colorPicker
                    reminderSection
                    previewCard
                    addButton
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            .background(Glass.sheetMaterial)
            .navigationTitle("New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { isTextFieldFocused = true }
                withAnimation(.linear(duration: 1.6).repeatForever(autoreverses: false)) { shimmerMove = true }
            }
            .alert("Microphone Access", isPresented: $speechRecognizer.showPermissionAlert) {
                Button("OK", role: .cancel) {}
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                }
            } message: {
                Text(speechRecognizer.errorMessage ?? "Permission required for voice input.")
            }
        }
    }

    // MARK: - Emoji picker (bounce on select)

    private var emojiPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Choose an emoji").font(.system(size: 14, weight: .semibold)).foregroundStyle(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(emojis, id: \.self) { emoji in
                        let isSelected = selectedEmoji == emoji
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) { selectedEmoji = emoji }
                            Haptics.light()
                        } label: {
                            Text(emoji)
                                .font(.system(size: 26))
                                .frame(width: 48, height: 48)
                                .background(Circle().fill(isSelected ? Color(hex: selectedColorHex).opacity(0.22) : Color.gray.opacity(0.10)))
                                .overlay(Circle().stroke(isSelected ? Color(hex: selectedColorHex) : Color.clear, lineWidth: 2))
                                .scaleEffect(isSelected ? 1.1 : 1)
                                .animation(.spring(response: 0.35, dampingFraction: 0.55), value: isSelected)
                        }.buttonStyle(.plain)
                    }
                }.padding(.vertical, 2)
            }
        }
    }

    // MARK: - Name field (glass)

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Habit name").font(.system(size: 14, weight: .semibold)).foregroundStyle(.secondary)
            HStack(spacing: 10) {
                TextField("e.g. Morning run", text: $habitName)
                    .font(.system(size: 17))
                    .focused($isTextFieldFocused)
                    .autocorrectionDisabled(false)
                    .textInputAutocapitalization(.sentences)
                    .onChange(of: speechRecognizer.transcript) { _, newValue in
                        if !newValue.isEmpty { habitName = newValue }
                    }
                Button {
                    withAnimation { speechRecognizer.toggleRecording() }
                    if speechRecognizer.isRecording { isTextFieldFocused = false }
                } label: {
                    ZStack {
                        if speechRecognizer.isRecording {
                            Circle().fill(Color.red.opacity(0.15)).frame(width: 40, height: 40)
                                .scaleEffect(isPulsing ? 1.35 : 1.0).opacity(isPulsing ? 0.3 : 0.6)
                                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isPulsing)
                        }
                        Circle().fill(speechRecognizer.isRecording ? Color.red : Accent.purple).frame(width: 36, height: 36)
                        Image(systemName: speechRecognizer.isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 15, weight: .semibold)).foregroundStyle(.white)
                    }
                }.buttonStyle(.plain)
                .onChange(of: speechRecognizer.isRecording) { _, v in isPulsing = v }
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Glass.fieldMaterial)
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.18), lineWidth: 0.5)))
            if speechRecognizer.isRecording {
                Text("Listening... tap stop when done").font(.system(size: 12, weight: .medium)).foregroundStyle(.red)
            }
        }
    }

    // MARK: - Color picker (selected 1.2, others 0.9)

    private var colorPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Pick a color").font(.system(size: 14, weight: .semibold)).foregroundStyle(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(colorHexes, id: \.self) { hex in
                        let isSelected = selectedColorHex == hex
                        Button {
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.68)) { selectedColorHex = hex }
                            Haptics.light()
                        } label: {
                            ZStack {
                                Circle().fill(Color(hex: hex)).frame(width: 44, height: 44)
                                    .shadow(color: Color(hex: hex).opacity(0.35), radius: 4, x: 0, y: 2)
                                if isSelected {
                                    Image(systemName: "checkmark").font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(.white).shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                                }
                            }
                            .overlay(Circle().stroke(Color.white, lineWidth: isSelected ? 3 : 0))
                            .shadow(color: .black.opacity(isSelected ? 0.15 : 0), radius: 6, x: 0, y: 3)
                            .scaleEffect(isSelected ? 1.2 : 0.9)
                            .animation(.spring(response: 0.32, dampingFraction: 0.68), value: isSelected)
                        }.buttonStyle(.plain)
                    }
                }.padding(.vertical, 6)
            }
        }
    }

    // MARK: - Reminder

    private var reminderSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: $enableReminder) {
                Label("Daily reminder", systemImage: "bell.fill")
                    .font(.system(size: 14, weight: .semibold)).foregroundStyle(.secondary)
            }.tint(Accent.purple)
            .onChange(of: enableReminder) { _, on in
                if on {
                    Task { _ = await NotificationManager.shared.requestAuthorization() }
                }
            }
            if enableReminder {
                DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(height: 110)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Glass.fieldMaterial)
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.15), lineWidth: 0.5)))
        .animation(Glass.spring, value: enableReminder)
    }

    // MARK: - Preview (Liquid Glass)

    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Preview").font(.system(size: 14, weight: .semibold)).foregroundStyle(.secondary)
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 2, style: .continuous).fill(Color(hex: selectedColorHex)).frame(width: 4).padding(.vertical, 6)
                ZStack { Circle().fill(Color(hex: selectedColorHex)).frame(width: 48, height: 48); Text(selectedEmoji).font(.system(size: 24)) }
                VStack(alignment: .leading, spacing: 3) {
                    Text(habitName.isEmpty ? "Your habit" : habitName).font(.system(size: 17, weight: .bold)).lineLimit(1)
                    Text("\u{1F525} 0 day streak").font(.system(size: 13, weight: .medium)).foregroundStyle(.secondary)
                }
                Spacer()
                Circle().strokeBorder(Color.gray.opacity(0.35), lineWidth: 2).frame(width: 36, height: 36)
            }
            .padding(.vertical, 14).padding(.horizontal, 12).padding(.leading, 2)
            .background(RoundedRectangle(cornerRadius: Glass.cardRadius, style: .continuous).fill(Glass.cardMaterial)
                .overlay(RoundedRectangle(cornerRadius: Glass.cardRadius, style: .continuous).stroke(Color.white.opacity(0.15), lineWidth: 0.5)))
            .habitShadow(color: Color(hex: selectedColorHex))
        }
    }

    // MARK: - Add button (shimmer)

    private var addButton: some View {
        Button { addHabit() } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isValid ? Color(hex: selectedColorHex) : Color.gray.opacity(0.3))
                    .frame(height: 52)
                // shimmer sweep
                if isValid {
                    GeometryReader { geo in
                        LinearGradient(colors: [.clear, .white.opacity(0.42), .clear], startPoint: .leading, endPoint: .trailing)
                            .frame(width: geo.size.width * 0.35)
                            .offset(x: shimmerMove ? geo.size.width : -geo.size.width * 0.35)
                    }
                    .frame(height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .blendMode(.overlay)
                }
                Text("Add Habit").font(.system(size: 17, weight: .semibold)).foregroundStyle(.white)
            }
        }
        .disabled(!isValid)
        .animation(.easeInOut(duration: 0.2), value: isValid)
        .padding(.top, 4)
    }

    private func addHabit() {
        let trimmed = habitName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let habit = Habit(name: trimmed, emoji: selectedEmoji, colorHex: selectedColorHex, reminderTime: enableReminder ? reminderTime : nil)
        modelContext.insert(habit)
        try? modelContext.save()
        if enableReminder, let rt = habit.reminderTime {
            Task { @MainActor in
                await NotificationManager.shared.checkAuthorization()
                _ = await NotificationManager.shared.requestAuthorization()
                NotificationManager.shared.scheduleDailyReminder(for: habit, at: rt)
            }
        }
        Haptics.success()
        dismiss()
    }
}
