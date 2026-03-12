import Foundation
import Combine
import UIKit

class HomeViewModel: ObservableObject {
    @Published var selectedLevel: StabilityLevel = .I
    @Published var selectedProtocolId: UUID? = nil
    @Published var canStart: Bool = false
    @Published var recommendUp: Bool = false
    @Published var protocols: [ProtocolDTO] = []
    
    private let startUC: StartSessionUseCase
    private let stabilityRepo: StabilityRepository
    private let protocolsRepo: ProtocolsRepository
    
    init(startUC: StartSessionUseCase, stabilityRepo: StabilityRepository, protocolsRepo: ProtocolsRepository) {
        self.startUC = startUC
        self.stabilityRepo = stabilityRepo
        self.protocolsRepo = protocolsRepo
        
        loadData()
    }
    
    func loadData() {
        let st = stabilityRepo.load()
        selectedLevel = StabilityLevel(rawValue: st.currentLevel) ?? .I
        protocols = protocolsRepo.all()
    }
    
    func selectProtocol(_ id: UUID) {
        selectedProtocolId = id
        canStart = true
    }
    
    func start() -> (SessionDTO, LevelProfileDTO)? {
        guard let pid = selectedProtocolId else { return nil }
        
        let input = StartSessionInput(protocolId: pid, level: selectedLevel.rawValue, now: Date())
        guard let output = try? startUC.execute(input) else { return nil }
        
        return (output.session, output.phases)
    }
}

class SessionViewModel: ObservableObject {
    @Published var timeLeft: String = "05:00"
    @Published var progress: Double = 0
    @Published var phaseText: String = "Inhale 360"
    @Published var sideText: String? = nil
    @Published var isPaused: Bool = false
    @Published var sessionCompleted: Bool = false
    
    let session: SessionDTO
    let phases: LevelProfileDTO
    private let tickUC: TickPhaseUseCase
    private let stopUC: StopAndLogUseCase
    private let soundHapticsService: SoundHapticsService
    private var engine: PhaseEngine
    private var lastPhaseType: PhaseDTOType?
    
    init(session: SessionDTO, phases: LevelProfileDTO, tickUC: TickPhaseUseCase, stopUC: StopAndLogUseCase, soundHapticsService: SoundHapticsService, engine: PhaseEngine) {
        self.session = session
        self.phases = phases
        self.tickUC = tickUC
        self.stopUC = stopUC
        self.soundHapticsService = soundHapticsService
        self.engine = engine
        
        configureEngine()
    }
    
    private func configureEngine() {
        engine.configure(phases: phases.phases, totalSec: 300, callback: { [weak self] secLeft, phaseIdx, current in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.timeLeft = FormattersService.mmss(secLeft)
                self.progress = 1.0 - (Double(secLeft) / 300.0)
                self.phaseText = self.phaseTitle(for: current.type)
                self.sideText = current.side
                
                if self.lastPhaseType != current.type {
                    self.tickUC.phaseChanged(sessionId: self.session.id, at: Date(), type: current.type, side: current.side)
                    self.soundHapticsService.playVoiceCue(self.phaseText)
                    
                    if current.type == .sideSwitch {
                        self.soundHapticsService.triggerHaptic(style: .medium)
                    } else {
                        self.soundHapticsService.triggerHaptic(style: .light)
                    }
                    
                    self.lastPhaseType = current.type
                }
            }
        }, completion: { [weak self] in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.timeLeft = "00:00"
                self.progress = 1.0
                self.soundHapticsService.triggerNotificationHaptic(type: .success)
                self.soundHapticsService.playVoiceCue("Session complete")
                self.sessionCompleted = true
            }
        })
    }
    
    func startSession() {
        engine.start()
    }
    
    func pause() {
        engine.pause()
        isPaused = true
    }
    
    func resume() {
        engine.resume()
        isPaused = false
    }
    
    func stop() -> SessionDTO? {
        engine.stop()
        let elapsed = engine.elapsed()
        
        return try? stopUC.stop(sessionId: session.id, finishedAt: Date(), durationSec: elapsed).session
    }
    
    private func phaseTitle(for type: PhaseDTOType) -> String {
        switch type {
        case .inhale: return "Inhale 360"
        case .exhale: return "Exhale - Ribs Down"
        case .neutral: return "Breathe Steadily"
        case .sideSwitch: return "Switch Sides"
        case .start: return "Begin"
        case .stop: return "Complete"
        }
    }
}

class PostSessionLogViewModel: ObservableObject {
    @Published var difficulty: Double = 5
    @Published var flagExt: Bool = false
    @Published var flagRot: Bool = false
    @Published var note: String = ""
    
    private let stopUC: StopAndLogUseCase
    private let evalUC: EvaluateStabilityUseCase
    private let sessionsRepo: SessionsRepository
    
    init(stopUC: StopAndLogUseCase, evalUC: EvaluateStabilityUseCase, sessionsRepo: SessionsRepository) {
        self.stopUC = stopUC
        self.evalUC = evalUC
        self.sessionsRepo = sessionsRepo
    }
    
    func save(sessionId: UUID) -> EvaluateStabilityOutput? {
        try? stopUC.saveLog(sessionId: sessionId, difficulty: Int(difficulty), flagExt: flagExt, flagRot: flagRot, note: note.isEmpty ? nil : note)
        
        guard let session = sessionsRepo.byId(sessionId) else { return nil }
        
        let input = EvaluateStabilityInput(lastSession: session)
        return evalUC.execute(input)
    }
}

class ProgressViewModel: ObservableObject {
    @Published var week: WeekTimelineModel = WeekTimelineModel(title: "", points: [])
    @Published var donut: ProtocolsDonutModel = ProtocolsDonutModel(title: "", slices: [], caption: "")
    @Published var bars: ProtocolDifficultyBarsModel = ProtocolDifficultyBarsModel(title: "", bars: [])
    @Published var cleanPie: CleanVsFlagsPieModel = CleanVsFlagsPieModel(title: "", cleanPct: 0, extPct: 0, rotPct: 0, a11yText: "")
    @Published var stabilityLevel: StabilityLevel = .I
    @Published var cleanStreak: Int = 0
    
    private let sessionsRepo: SessionsRepository
    private let protocolsRepo: ProtocolsRepository
    private let stabilityRepo: StabilityRepository
    private let buildUC: BuildProgressChartsUseCase
    
    init(sessionsRepo: SessionsRepository, protocolsRepo: ProtocolsRepository, stabilityRepo: StabilityRepository, buildUC: BuildProgressChartsUseCase) {
        self.sessionsRepo = sessionsRepo
        self.protocolsRepo = protocolsRepo
        self.stabilityRepo = stabilityRepo
        self.buildUC = buildUC
    }
    
    func load() {
        let stability = stabilityRepo.load()
        stabilityLevel = StabilityLevel(rawValue: stability.currentLevel) ?? .I
        cleanStreak = stability.cleanStreakDays
        
        let allSessions = sessionsRepo.all()
        
        guard !allSessions.isEmpty else {
            week = WeekTimelineModel(title: "Week", points: [])
            donut = ProtocolsDonutModel(title: "Protocol Usage", slices: [], caption: "")
            bars = ProtocolDifficultyBarsModel(title: "Average Difficulty", bars: [])
            cleanPie = CleanVsFlagsPieModel(title: "Form Quality", cleanPct: 0, extPct: 0, rotPct: 0, a11yText: "No data")
            return
        }
        
        let calendar = Calendar.current
        
        let newestSession = allSessions.first?.startedAt ?? Date()
        
        // Always use the actual session date range, not current device date
        let from = calendar.date(byAdding: .day, value: -6, to: newestSession) ?? newestSession
        let to = newestSession
        
        let protocols = protocolsRepo.all()
        
        let output = buildUC.execute(from: from, to: to, sessions: allSessions, protocols: protocols)
        week = output.weekTimeline
        donut = output.protocolsDonut
        bars = output.difficultyBars
        cleanPie = output.cleanPie
    }
}

class SettingsViewModel: ObservableObject {
    @Published var voiceGuidance: Int = 2
    @Published var hapticsEnabled: Bool = true
    @Published var showResetAlert: Bool = false
    
    private let settingsRepo: SettingsRepository
    private let soundHapticsService: SoundHapticsService
    private let sessionsRepo: SessionsRepository
    private let stabilityRepo: StabilityRepository
    private let phaseEventsRepo: PhaseEventsRepository
    
    init(settingsRepo: SettingsRepository, soundHapticsService: SoundHapticsService, sessionsRepo: SessionsRepository, stabilityRepo: StabilityRepository, phaseEventsRepo: PhaseEventsRepository) {
        self.settingsRepo = settingsRepo
        self.soundHapticsService = soundHapticsService
        self.sessionsRepo = sessionsRepo
        self.stabilityRepo = stabilityRepo
        self.phaseEventsRepo = phaseEventsRepo
        loadSettings()
    }
    
    func loadSettings() {
        let settings = settingsRepo.load()
        voiceGuidance = settings.voiceGuidance
        hapticsEnabled = settings.hapticsEnabled
        applySettings()
    }
    
    func saveSettings() {
        let settings = settingsRepo.load()
        let updated = SettingsDTO(id: settings.id, voiceGuidance: voiceGuidance, hapticsEnabled: hapticsEnabled, onboardingCompleted: settings.onboardingCompleted)
        try? settingsRepo.save(updated)
        applySettings()
    }
    
    private func applySettings() {
        soundHapticsService.configure(hapticsEnabled: hapticsEnabled, voiceLevel: voiceGuidance)
    }
    
    func showResetConfirmation() {
        showResetAlert = true
    }
    
    func resetAllData() {
        try? phaseEventsRepo.deleteAll()
        try? sessionsRepo.deleteAll()
        
        let settings = settingsRepo.load()
        let updated = SettingsDTO(id: settings.id, voiceGuidance: 2, hapticsEnabled: true, onboardingCompleted: false)
        try? settingsRepo.save(updated)
        
        let stability = stabilityRepo.load()
        let newStability = StabilityProgressDTO(id: stability.id, currentLevel: 1, cleanStreakDays: 0, lastEvaluatedAt: Date())
        try? stabilityRepo.save(newStability)
        
        voiceGuidance = 2
        hapticsEnabled = true
        applySettings()
    }
}

