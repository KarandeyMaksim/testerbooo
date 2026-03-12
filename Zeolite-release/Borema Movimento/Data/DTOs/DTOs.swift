import Foundation

public enum PhaseDTOType: Int16 {
    case inhale = 0
    case exhale = 1
    case neutral = 2
    case sideSwitch = 3
    case start = 4
    case stop = 5
}

public struct ProtocolDTO: Identifiable, Equatable {
    public let id: UUID
    public let name: String
    public let slug: String
    public let categories: Set<String>
    
    public init(id: UUID, name: String, slug: String, categories: Set<String>) {
        self.id = id
        self.name = name
        self.slug = slug
        self.categories = categories
    }
}

public struct PhaseItemDTO: Equatable {
    public let type: PhaseDTOType
    public let durationSec: Int
    public let side: String?
    
    public init(type: PhaseDTOType, durationSec: Int, side: String?) {
        self.type = type
        self.durationSec = durationSec
        self.side = side
    }
}

public struct LevelProfileDTO: Identifiable, Equatable {
    public let id: UUID
    public let protocolId: UUID
    public let level: Int
    public let phases: [PhaseItemDTO]
    public let voiceCues: [String: String]
    
    public init(id: UUID, protocolId: UUID, level: Int, phases: [PhaseItemDTO], voiceCues: [String: String]) {
        self.id = id
        self.protocolId = protocolId
        self.level = level
        self.phases = phases
        self.voiceCues = voiceCues
    }
}

public struct SessionDTO: Identifiable, Equatable {
    public let id: UUID
    public let protocolId: UUID
    public let level: Int
    public let startedAt: Date
    public let finishedAt: Date?
    public let actualDurationSec: Int
    public let difficulty: Int?
    public let flagExtension: Bool
    public let flagRotation: Bool
    public let note: String?
    
    public init(id: UUID, protocolId: UUID, level: Int, startedAt: Date, finishedAt: Date?, actualDurationSec: Int, difficulty: Int?, flagExtension: Bool, flagRotation: Bool, note: String?) {
        self.id = id
        self.protocolId = protocolId
        self.level = level
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.actualDurationSec = actualDurationSec
        self.difficulty = difficulty
        self.flagExtension = flagExtension
        self.flagRotation = flagRotation
        self.note = note
    }
}

public struct PhaseEventDTO: Identifiable, Equatable {
    public let id: UUID
    public let sessionId: UUID
    public let timestamp: Date
    public let type: PhaseDTOType
    public let side: String?
    
    public init(id: UUID, sessionId: UUID, timestamp: Date, type: PhaseDTOType, side: String?) {
        self.id = id
        self.sessionId = sessionId
        self.timestamp = timestamp
        self.type = type
        self.side = side
    }
}

public struct StabilityProgressDTO: Identifiable, Equatable {
    public let id: UUID
    public let currentLevel: Int
    public let cleanStreakDays: Int
    public let lastEvaluatedAt: Date
    
    public init(id: UUID, currentLevel: Int, cleanStreakDays: Int, lastEvaluatedAt: Date) {
        self.id = id
        self.currentLevel = currentLevel
        self.cleanStreakDays = cleanStreakDays
        self.lastEvaluatedAt = lastEvaluatedAt
    }
}

public struct SettingsDTO: Identifiable, Equatable {
    public let id: UUID
    public let voiceGuidance: Int
    public let hapticsEnabled: Bool
    public let onboardingCompleted: Bool
    
    public init(id: UUID, voiceGuidance: Int, hapticsEnabled: Bool, onboardingCompleted: Bool) {
        self.id = id
        self.voiceGuidance = voiceGuidance
        self.hapticsEnabled = hapticsEnabled
        self.onboardingCompleted = onboardingCompleted
    }
}

