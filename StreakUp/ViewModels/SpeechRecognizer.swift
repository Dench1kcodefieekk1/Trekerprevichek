// FILE: StreakUp/ViewModels/SpeechRecognizer.swift
import Foundation
import Speech
import AVFoundation
import SwiftUI
import Combine

@MainActor
final class SpeechRecognizer: ObservableObject {
    @Published var transcript: String = ""
    @Published var isRecording: Bool = false
    @Published var errorMessage: String?
    @Published var showPermissionAlert: Bool = false

    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var speechRecognizer: SFSpeechRecognizer?
    private var silenceTimer: Timer?
    private var hasReceivedResult: Bool = false

    init(locale: Locale = Locale(identifier: "en-US")) {
        // Try requested locale, fallback to current locale, then en-US
        if let recognizer = SFSpeechRecognizer(locale: locale), recognizer.isAvailable {
            speechRecognizer = recognizer
        } else if let fallback = SFSpeechRecognizer(locale: Locale.current), fallback.isAvailable {
            speechRecognizer = fallback
        } else {
            speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        }
    }

    // MARK: - Permissions

    func requestPermissions() async -> Bool {
        let speechStatus = await withCheckedContinuation { (continuation: CheckedContinuation<SFSpeechRecognizerAuthorizationStatus, Never>) in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        guard speechStatus == .authorized else {
            errorMessage = "Speech recognition permission denied. Please enable it in Settings > Privacy > Speech Recognition."
            showPermissionAlert = true
            return false
        }

        let micStatus = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }

        guard micStatus else {
            errorMessage = "Microphone permission denied. Please enable it in Settings > Privacy > Microphone."
            showPermissionAlert = true
            return false
        }

        return true
    }

    // MARK: - Recording

    func startTranscribing() {
        Task {
            let granted = await requestPermissions()
            guard granted else { return }
            await MainActor.run { self.beginRecording() }
        }
    }

    private func beginRecording() {
        // Reset state
        transcript = ""
        hasReceivedResult = false
        errorMessage = nil

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "Failed to configure audio session: \(error.localizedDescription)"
            showPermissionAlert = true
            return
        }

        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            errorMessage = "Speech recognizer is not available on this device."
            showPermissionAlert = true
            return
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest else {
            errorMessage = "Unable to create recognition request."
            return
        }
        recognitionRequest.shouldReportPartialResults = true
        // Use on-device if available for privacy
        if recognizer.supportsOnDeviceRecognition {
            recognitionRequest.requiresOnDeviceRecognition = false
        }

        audioEngine = AVAudioEngine()
        guard let audioEngine else { return }

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            errorMessage = "Failed to start audio engine: \(error.localizedDescription)"
            return
        }

        isRecording = true
        resetSilenceTimer()

        recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }
                if let result {
                    self.transcript = result.bestTranscription.formattedString
                    self.hasReceivedResult = true
                    self.resetSilenceTimer()
                    if result.isFinal {
                        self.stopTranscribing()
                    }
                }
                if let error {
                    // Ignore cancellation errors
                    let nsError = error as NSError
                    if nsError.domain == "kAFAssistantErrorDomain" || nsError.code == 216 {
                        return
                    }
                    // Only show error if we never got a result
                    if !self.hasReceivedResult {
                        self.errorMessage = error.localizedDescription
                    }
                    self.stopTranscribing()
                }
            }
        }
    }

    func stopTranscribing() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        audioEngine = nil
        isRecording = false
        silenceTimer?.invalidate()
        silenceTimer = nil

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    func toggleRecording() {
        if isRecording {
            stopTranscribing()
        } else {
            startTranscribing()
        }
    }

    // Auto-stop after 3 seconds of silence (no new transcription)
    private func resetSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.isRecording else { return }
                self.stopTranscribing()
            }
        }
    }

    // Note: no deinit invalidation needed — stopTranscribing handles timer cleanup.
    // Avoid MainActor-isolated deinit access which would not compile.
}
