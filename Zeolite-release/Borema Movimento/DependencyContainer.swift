import Foundation
import CoreData

class DependencyContainer {
    static let shared = DependencyContainer()
    
    private let context: NSManagedObjectContext
    private let phaseEngine: PhaseEngine
    private let soundHapticsService: SoundHapticsService
    
    private let protocolsRepo: ProtocolsRepository
    private let sessionsRepo: SessionsRepository
    private let phaseEventsRepo: PhaseEventsRepository
    private let stabilityRepo: StabilityRepository
    private let settingsRepo: SettingsRepository
    
    private let startSessionUC: StartSessionUseCase
    private let tickPhaseUC: TickPhaseUseCase
    private let stopAndLogUC: StopAndLogUseCase
    private let evaluateStabilityUC: EvaluateStabilityUseCase
    private let buildProgressChartsUC: BuildProgressChartsUseCase
    
    private init() {
        self.context = PersistenceController.shared.container.viewContext
        self.phaseEngine = PhaseEngine()
        self.soundHapticsService = SoundHapticsService()
        
        self.protocolsRepo = ProtocolsRepositoryImpl(context: context)
        self.sessionsRepo = SessionsRepositoryImpl(context: context)
        self.phaseEventsRepo = PhaseEventsRepositoryImpl(context: context)
        self.stabilityRepo = StabilityRepositoryImpl(context: context)
        self.settingsRepo = SettingsRepositoryImpl(context: context)
        
        self.startSessionUC = StartSessionUseCaseImpl(sessionsRepo: sessionsRepo, protocolsRepo: protocolsRepo)
        self.tickPhaseUC = TickPhaseUseCaseImpl(phaseEventsRepo: phaseEventsRepo)
        self.stopAndLogUC = StopAndLogUseCaseImpl(sessionsRepo: sessionsRepo)
        self.evaluateStabilityUC = EvaluateStabilityUseCaseImpl(stabilityRepo: stabilityRepo, sessionsRepo: sessionsRepo)
        self.buildProgressChartsUC = BuildProgressChartsUseCaseImpl()
        
        configureServices()
    }
    
    private func configureServices() {
        let settings = settingsRepo.load()
        soundHapticsService.configure(hapticsEnabled: settings.hapticsEnabled, voiceLevel: settings.voiceGuidance)
    }
    
    func makeHomeViewModel() -> HomeViewModel {
        return HomeViewModel(
            startUC: startSessionUC,
            stabilityRepo: stabilityRepo,
            protocolsRepo: protocolsRepo
        )
    }
    
    func makeSessionViewModel(session: SessionDTO, phases: LevelProfileDTO) -> SessionViewModel {
        return SessionViewModel(
            session: session,
            phases: phases,
            tickUC: tickPhaseUC,
            stopUC: stopAndLogUC,
            soundHapticsService: soundHapticsService,
            engine: phaseEngine
        )
    }
    
    func makePostSessionLogViewModel() -> PostSessionLogViewModel {
        return PostSessionLogViewModel(
            stopUC: stopAndLogUC,
            evalUC: evaluateStabilityUC,
            sessionsRepo: sessionsRepo
        )
    }
    
    func makeProgressViewModel() -> ProgressViewModel {
        return ProgressViewModel(
            sessionsRepo: sessionsRepo,
            protocolsRepo: protocolsRepo,
            stabilityRepo: stabilityRepo,
            buildUC: buildProgressChartsUC
        )
    }
    
    func makeSettingsViewModel() -> SettingsViewModel {
        return SettingsViewModel(
            settingsRepo: settingsRepo,
            soundHapticsService: soundHapticsService,
            sessionsRepo: sessionsRepo,
            stabilityRepo: stabilityRepo,
            phaseEventsRepo: phaseEventsRepo
        )
    }
    
    func isOnboardingCompleted() -> Bool {
        return settingsRepo.load().onboardingCompleted
    }
    
    func completeOnboarding() {
        let settings = settingsRepo.load()
        let updated = SettingsDTO(
            id: settings.id,
            voiceGuidance: settings.voiceGuidance,
            hapticsEnabled: settings.hapticsEnabled,
            onboardingCompleted: true
        )
        try? settingsRepo.save(updated)
    }
    
    func completeOnboarding(withLevel level: StabilityLevel) {
        let settings = settingsRepo.load()
        let updated = SettingsDTO(
            id: settings.id,
            voiceGuidance: settings.voiceGuidance,
            hapticsEnabled: settings.hapticsEnabled,
            onboardingCompleted: true
        )
        try? settingsRepo.save(updated)
        
        let stability = stabilityRepo.load()
        let updatedStability = StabilityProgressDTO(
            id: stability.id,
            currentLevel: level.rawValue,
            cleanStreakDays: 0,
            lastEvaluatedAt: Date()
        )
        try? stabilityRepo.save(updatedStability)
    }
}

