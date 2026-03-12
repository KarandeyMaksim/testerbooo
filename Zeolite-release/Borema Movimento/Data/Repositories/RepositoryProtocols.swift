import Foundation

public protocol ProtocolsRepository {
    func all() -> [ProtocolDTO]
    func profile(for protocolId: UUID, level: Int) -> LevelProfileDTO?
}

public protocol SessionsRepository {
    func createRunning(protocolId: UUID, level: Int, startAt: Date) throws -> SessionDTO
    func finalize(sessionId: UUID, finishedAt: Date, durationSec: Int) throws
    func updateLog(sessionId: UUID, difficulty: Int, flagExt: Bool, flagRot: Bool, note: String?) throws
    func byId(_ id: UUID) -> SessionDTO?
    func recent(limit: Int) -> [SessionDTO]
    func list(from: Date, to: Date) -> [SessionDTO]
    func all() -> [SessionDTO]
    func deleteAll() throws
}

public protocol PhaseEventsRepository {
    func insert(_ e: PhaseEventDTO) throws
    func list(sessionId: UUID) -> [PhaseEventDTO]
    func deleteAll() throws
}

public protocol StabilityRepository {
    func load() -> StabilityProgressDTO
    func save(_ s: StabilityProgressDTO) throws
}

public protocol SettingsRepository {
    func load() -> SettingsDTO
    func save(_ s: SettingsDTO) throws
}

