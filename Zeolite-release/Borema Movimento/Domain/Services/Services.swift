import Foundation
import AVFoundation
import UIKit

class PhaseEngine {
    typealias PhaseCallback = (Int, Int, PhaseItemDTO) -> Void
    typealias CompletionCallback = () -> Void
    
    private var phases: [PhaseItemDTO] = []
    private var totalSeconds: Int = 300
    private var elapsedSeconds: Int = 0
    private var currentPhaseIndex: Int = 0
    private var isRunning: Bool = false
    private var timer: Timer?
    private var callback: PhaseCallback?
    private var completionCallback: CompletionCallback?
    
    func configure(phases: [PhaseItemDTO], totalSec: Int, callback: @escaping PhaseCallback, completion: @escaping CompletionCallback) {
        self.phases = phases
        self.totalSeconds = totalSec
        self.callback = callback
        self.completionCallback = completion
        self.elapsedSeconds = 0
        self.currentPhaseIndex = 0
    }
    
    func start() {
        isRunning = true
        startTimer()
    }
    
    func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    func resume() {
        isRunning = true
        startTimer()
    }
    
    func stop() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    func elapsed() -> Int {
        return elapsedSeconds
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }
    
    private func tick() {
        guard isRunning else { return }
        
        elapsedSeconds += 1
        let remaining = totalSeconds - elapsedSeconds
        
        if remaining <= 0 {
            stop()
            completionCallback?()
            return
        }
        
        updatePhase()
        callback?(remaining, currentPhaseIndex, phases[currentPhaseIndex])
    }
    
    private func updatePhase() {
        var accumulated = 0
        for (index, phase) in phases.enumerated() {
            accumulated += phase.durationSec
            if elapsedSeconds <= accumulated {
                currentPhaseIndex = index
                break
            }
        }
    }
}

class SoundHapticsService {
    private let synthesizer = AVSpeechSynthesizer()
    private var hapticsEnabled: Bool = true
    private var voiceLevel: Int = 2
    
    func configure(hapticsEnabled: Bool, voiceLevel: Int) {
        self.hapticsEnabled = hapticsEnabled
        self.voiceLevel = voiceLevel
    }
    
    func playVoiceCue(_ text: String) {
        guard voiceLevel > 0 else { return }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = voiceLevel == 1 ? 0.4 : 0.5
        utterance.volume = voiceLevel == 1 ? 0.5 : 1.0
        
        synthesizer.speak(utterance)
    }
    
    func triggerHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        guard hapticsEnabled else { return }
        
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    func triggerNotificationHaptic(type: UINotificationFeedbackGenerator.FeedbackType) {
        guard hapticsEnabled else { return }
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
}

class FormattersService {
    static func mmss(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
    
    static func weekdayShort(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    static func dateISO(from date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: date)
    }
}

