import Foundation

struct StartSessionInput {
    let protocolId: UUID
    let level: Int
    let now: Date
}

struct StartSessionOutput {
    let session: SessionDTO
    let phases: LevelProfileDTO
}

protocol StartSessionUseCase {
    func execute(_ input: StartSessionInput) throws -> StartSessionOutput
}

class StartSessionUseCaseImpl: StartSessionUseCase {
    private let sessionsRepo: SessionsRepository
    private let protocolsRepo: ProtocolsRepository
    
    init(sessionsRepo: SessionsRepository, protocolsRepo: ProtocolsRepository) {
        self.sessionsRepo = sessionsRepo
        self.protocolsRepo = protocolsRepo
    }
    
    func execute(_ input: StartSessionInput) throws -> StartSessionOutput {
        guard let profile = protocolsRepo.profile(for: input.protocolId, level: input.level) else {
            throw NSError(domain: "StartSession", code: 1, userInfo: [NSLocalizedDescriptionKey: "Profile not found"])
        }
        
        let session = try sessionsRepo.createRunning(protocolId: input.protocolId, level: input.level, startAt: input.now)
        
        return StartSessionOutput(session: session, phases: profile)
    }
}

protocol TickPhaseUseCase {
    func phaseChanged(sessionId: UUID, at: Date, type: PhaseDTOType, side: String?)
}

class TickPhaseUseCaseImpl: TickPhaseUseCase {
    private let phaseEventsRepo: PhaseEventsRepository
    
    init(phaseEventsRepo: PhaseEventsRepository) {
        self.phaseEventsRepo = phaseEventsRepo
    }
    
    func phaseChanged(sessionId: UUID, at: Date, type: PhaseDTOType, side: String?) {
        let event = PhaseEventDTO(id: UUID(), sessionId: sessionId, timestamp: at, type: type, side: side)
        try? phaseEventsRepo.insert(event)
    }
}

struct StopAndLogOutput {
    let session: SessionDTO
}

protocol StopAndLogUseCase {
    func stop(sessionId: UUID, finishedAt: Date, durationSec: Int) throws -> StopAndLogOutput
    func saveLog(sessionId: UUID, difficulty: Int, flagExt: Bool, flagRot: Bool, note: String?) throws
}

class StopAndLogUseCaseImpl: StopAndLogUseCase {
    private let sessionsRepo: SessionsRepository
    
    init(sessionsRepo: SessionsRepository) {
        self.sessionsRepo = sessionsRepo
    }
    
    func stop(sessionId: UUID, finishedAt: Date, durationSec: Int) throws -> StopAndLogOutput {
        try sessionsRepo.finalize(sessionId: sessionId, finishedAt: finishedAt, durationSec: durationSec)
        
        guard let session = sessionsRepo.byId(sessionId) else {
            throw NSError(domain: "StopSession", code: 1, userInfo: [NSLocalizedDescriptionKey: "Session not found"])
        }
        
        return StopAndLogOutput(session: session)
    }
    
    func saveLog(sessionId: UUID, difficulty: Int, flagExt: Bool, flagRot: Bool, note: String?) throws {
        try sessionsRepo.updateLog(sessionId: sessionId, difficulty: difficulty, flagExt: flagExt, flagRot: flagRot, note: note)
    }
}

struct EvaluateStabilityInput {
    let lastSession: SessionDTO
}

struct EvaluateStabilityOutput {
    let stability: StabilityProgressDTO
    let recommendUp: Bool
    let recommendDown: Bool
}

protocol EvaluateStabilityUseCase {
    func execute(_ input: EvaluateStabilityInput) -> EvaluateStabilityOutput
}

class EvaluateStabilityUseCaseImpl: EvaluateStabilityUseCase {
    private let stabilityRepo: StabilityRepository
    private let sessionsRepo: SessionsRepository
    
    init(stabilityRepo: StabilityRepository, sessionsRepo: SessionsRepository) {
        self.stabilityRepo = stabilityRepo
        self.sessionsRepo = sessionsRepo
    }
    
    func execute(_ input: EvaluateStabilityInput) -> EvaluateStabilityOutput {
        var stability = stabilityRepo.load()
        var recommendUp = false
        var recommendDown = false
        
        let isClean = (input.lastSession.difficulty ?? 10) <= 4 && !input.lastSession.flagExtension && !input.lastSession.flagRotation
        
        if isClean {
            let newStreak = stability.cleanStreakDays + 1
            stability = StabilityProgressDTO(
                id: stability.id,
                currentLevel: stability.currentLevel,
                cleanStreakDays: newStreak,
                lastEvaluatedAt: Date()
            )
            
            if newStreak >= 3 && stability.currentLevel < 3 {
                recommendUp = true
            }
        } else {
            stability = StabilityProgressDTO(
                id: stability.id,
                currentLevel: stability.currentLevel,
                cleanStreakDays: 0,
                lastEvaluatedAt: Date()
            )
            
            if (input.lastSession.difficulty ?? 0) >= 8 || input.lastSession.flagExtension || input.lastSession.flagRotation {
                let recent = sessionsRepo.recent(limit: 2)
                if recent.count == 2 {
                    let prevHadFlags = recent[1].flagExtension || recent[1].flagRotation
                    if prevHadFlags && stability.currentLevel > 1 {
                        recommendDown = true
                    }
                }
            }
        }
        
        try? stabilityRepo.save(stability)
        
        return EvaluateStabilityOutput(stability: stability, recommendUp: recommendUp, recommendDown: recommendDown)
    }
}

