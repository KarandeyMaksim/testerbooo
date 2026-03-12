import Foundation
import CoreData

class ProtocolsRepositoryImpl: ProtocolsRepository {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func all() -> [ProtocolDTO] {
        let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "Protocol")
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        guard let results = try? context.fetch(request) else { return [] }
        
        return results.compactMap { entity -> ProtocolDTO? in
            guard let id = entity.value(forKey: "id") as? UUID,
                  let name = entity.value(forKey: "name") as? String,
                  let slug = entity.value(forKey: "slug") as? String else {
                return nil
            }
            
            let categoryRaw = entity.value(forKey: "categoryRaw") as? Int16 ?? 0
            var categories: Set<String> = []
            
            if categoryRaw == 1 { categories.insert("antiExtension") }
            if categoryRaw == 2 { categories.insert("antiRotation") }
            if categoryRaw == 3 { categories = ["antiExtension", "antiRotation"] }
            
            return ProtocolDTO(id: id, name: name, slug: slug, categories: categories)
        }
    }
    
    func profile(for protocolId: UUID, level: Int) -> LevelProfileDTO? {
        let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "LevelProfile")
        request.predicate = NSPredicate(format: "protocolId == %@ AND levelRaw == %d", protocolId as CVarArg, Int16(level))
        request.fetchLimit = 1
        
        guard let result = try? context.fetch(request).first,
              let id = result.value(forKey: "id") as? UUID,
              let phasesData = result.value(forKey: "phasesJSON") as? Data,
              let voiceCuesData = result.value(forKey: "voiceCuesJSON") as? Data else {
            return nil
        }
        
        let phases = parsePhasesJSON(data: phasesData)
        let voiceCues = parseVoiceCuesJSON(data: voiceCuesData)
        
        return LevelProfileDTO(id: id, protocolId: protocolId, level: level, phases: phases, voiceCues: voiceCues)
    }
    
    private func parsePhasesJSON(data: Data) -> [PhaseItemDTO] {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return [] }
        
        return json.compactMap { dict -> PhaseItemDTO? in
            guard let typeRaw = dict["type"] as? Int,
                  let duration = dict["duration"] as? Int else { return nil }
            
            let type = PhaseDTOType(rawValue: Int16(typeRaw)) ?? .neutral
            let side = dict["side"] as? String
            
            return PhaseItemDTO(type: type, durationSec: duration, side: side)
        }
    }
    
    private func parseVoiceCuesJSON(data: Data) -> [String: String] {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: String] else { return [:] }
        return json
    }
}

class SessionsRepositoryImpl: SessionsRepository {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func createRunning(protocolId: UUID, level: Int, startAt: Date) throws -> SessionDTO {
        let entity = NSEntityDescription.insertNewObject(forEntityName: "Session", into: context)
        let id = UUID()
        
        entity.setValue(id, forKey: "id")
        entity.setValue(protocolId, forKey: "protocolId")
        entity.setValue(Int16(level), forKey: "levelRaw")
        entity.setValue(startAt, forKey: "startedAtUTC")
        entity.setValue(Int32(0), forKey: "actualDurationSec")
        entity.setValue(Int16(0), forKey: "statusRaw")
        entity.setValue(false, forKey: "flagExtension")
        entity.setValue(false, forKey: "flagRotation")
        
        try context.save()
        
        return SessionDTO(id: id, protocolId: protocolId, level: level, startedAt: startAt, finishedAt: nil, actualDurationSec: 0, difficulty: nil, flagExtension: false, flagRotation: false, note: nil)
    }
    
    func finalize(sessionId: UUID, finishedAt: Date, durationSec: Int) throws {
        guard let entity = fetchEntity(by: sessionId) else { return }
        
        entity.setValue(finishedAt, forKey: "finishedAtUTC")
        entity.setValue(Int32(durationSec), forKey: "actualDurationSec")
        entity.setValue(Int16(1), forKey: "statusRaw")
        
        try context.save()
    }
    
    func updateLog(sessionId: UUID, difficulty: Int, flagExt: Bool, flagRot: Bool, note: String?) throws {
        guard let entity = fetchEntity(by: sessionId) else { return }
        
        entity.setValue(Int16(difficulty), forKey: "difficultyScore")
        entity.setValue(flagExt, forKey: "flagExtension")
        entity.setValue(flagRot, forKey: "flagRotation")
        entity.setValue(note, forKey: "note")
        
        try context.save()
    }
    
    func byId(_ id: UUID) -> SessionDTO? {
        guard let entity = fetchEntity(by: id) else { return nil }
        return mapToDTO(entity: entity)
    }
    
    func recent(limit: Int) -> [SessionDTO] {
        let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "Session")
        request.sortDescriptors = [NSSortDescriptor(key: "startedAtUTC", ascending: false)]
        request.fetchLimit = limit
        
        guard let results = try? context.fetch(request) else { return [] }
        return results.compactMap { mapToDTO(entity: $0) }
    }
    
    func list(from: Date, to: Date) -> [SessionDTO] {
        let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "Session")
        request.predicate = NSPredicate(format: "startedAtUTC >= %@ AND startedAtUTC <= %@", from as NSDate, to as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "startedAtUTC", ascending: false)]
        
        guard let results = try? context.fetch(request) else { return [] }
        return results.compactMap { mapToDTO(entity: $0) }
    }
    
    func all() -> [SessionDTO] {
        let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "Session")
        request.sortDescriptors = [NSSortDescriptor(key: "startedAtUTC", ascending: false)]
        
        guard let results = try? context.fetch(request) else { return [] }
        return results.compactMap { mapToDTO(entity: $0) }
    }
    
    func deleteAll() throws {
        let request: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Session")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        try context.execute(deleteRequest)
        try context.save()
    }
    
    private func fetchEntity(by id: UUID) -> NSManagedObject? {
        let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "Session")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        return try? context.fetch(request).first
    }
    
    private func mapToDTO(entity: NSManagedObject) -> SessionDTO? {
        guard let id = entity.value(forKey: "id") as? UUID,
              let protocolId = entity.value(forKey: "protocolId") as? UUID,
              let levelRaw = entity.value(forKey: "levelRaw") as? Int16,
              let startedAt = entity.value(forKey: "startedAtUTC") as? Date,
              let durationSec = entity.value(forKey: "actualDurationSec") as? Int32 else {
            return nil
        }
        
        let finishedAt = entity.value(forKey: "finishedAtUTC") as? Date
        let difficulty = entity.value(forKey: "difficultyScore") as? Int16
        let flagExtension = entity.value(forKey: "flagExtension") as? Bool ?? false
        let flagRotation = entity.value(forKey: "flagRotation") as? Bool ?? false
        let note = entity.value(forKey: "note") as? String
        
        return SessionDTO(
            id: id,
            protocolId: protocolId,
            level: Int(levelRaw),
            startedAt: startedAt,
            finishedAt: finishedAt,
            actualDurationSec: Int(durationSec),
            difficulty: difficulty != nil ? Int(difficulty!) : nil,
            flagExtension: flagExtension,
            flagRotation: flagRotation,
            note: note
        )
    }
}

class PhaseEventsRepositoryImpl: PhaseEventsRepository {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func insert(_ e: PhaseEventDTO) throws {
        let entity = NSEntityDescription.insertNewObject(forEntityName: "PhaseEvent", into: context)
        
        entity.setValue(e.id, forKey: "id")
        entity.setValue(e.sessionId, forKey: "sessionId")
        entity.setValue(e.timestamp, forKey: "timestampUTC")
        entity.setValue(Int16(e.type.rawValue), forKey: "phaseTypeRaw")
        
        if let side = e.side {
            let sideRaw: Int16 = side == "R" ? 0 : 1
            entity.setValue(sideRaw, forKey: "sideRaw")
        }
        
        try context.save()
    }
    
    func list(sessionId: UUID) -> [PhaseEventDTO] {
        let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "PhaseEvent")
        request.predicate = NSPredicate(format: "sessionId == %@", sessionId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "timestampUTC", ascending: true)]
        
        guard let results = try? context.fetch(request) else { return [] }
        
        return results.compactMap { entity -> PhaseEventDTO? in
            guard let id = entity.value(forKey: "id") as? UUID,
                  let timestamp = entity.value(forKey: "timestampUTC") as? Date,
                  let typeRaw = entity.value(forKey: "phaseTypeRaw") as? Int16 else {
                return nil
            }
            
            let type = PhaseDTOType(rawValue: typeRaw) ?? .neutral
            let sideRaw = entity.value(forKey: "sideRaw") as? Int16
            let side = sideRaw == 0 ? "R" : (sideRaw == 1 ? "L" : nil)
            
            return PhaseEventDTO(id: id, sessionId: sessionId, timestamp: timestamp, type: type, side: side)
        }
    }
    
    func deleteAll() throws {
        let request: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "PhaseEvent")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        try context.execute(deleteRequest)
        try context.save()
    }
}

class StabilityRepositoryImpl: StabilityRepository {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func load() -> StabilityProgressDTO {
        let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "StabilityProgress")
        request.fetchLimit = 1
        
        guard let entity = try? context.fetch(request).first,
              let id = entity.value(forKey: "id") as? UUID,
              let currentLevel = entity.value(forKey: "currentLevelRaw") as? Int16,
              let cleanStreak = entity.value(forKey: "cleanStreakDays") as? Int16,
              let lastEval = entity.value(forKey: "lastEvaluatedAtUTC") as? Date else {
            return StabilityProgressDTO(id: UUID(), currentLevel: 1, cleanStreakDays: 0, lastEvaluatedAt: Date())
        }
        
        return StabilityProgressDTO(id: id, currentLevel: Int(currentLevel), cleanStreakDays: Int(cleanStreak), lastEvaluatedAt: lastEval)
    }
    
    func save(_ s: StabilityProgressDTO) throws {
        let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "StabilityProgress")
        request.fetchLimit = 1
        
        let entity = try context.fetch(request).first ?? NSEntityDescription.insertNewObject(forEntityName: "StabilityProgress", into: context)
        
        entity.setValue(s.id, forKey: "id")
        entity.setValue(Int16(s.currentLevel), forKey: "currentLevelRaw")
        entity.setValue(Int16(s.cleanStreakDays), forKey: "cleanStreakDays")
        entity.setValue(s.lastEvaluatedAt, forKey: "lastEvaluatedAtUTC")
        
        try context.save()
    }
}

class SettingsRepositoryImpl: SettingsRepository {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func load() -> SettingsDTO {
        let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "Settings")
        request.fetchLimit = 1
        
        guard let entity = try? context.fetch(request).first,
              let id = entity.value(forKey: "id") as? UUID,
              let voice = entity.value(forKey: "voiceGuidance") as? Int16,
              let haptics = entity.value(forKey: "hapticsEnabled") as? Bool,
              let onboarding = entity.value(forKey: "onboardingCompleted") as? Bool else {
            return SettingsDTO(id: UUID(), voiceGuidance: 2, hapticsEnabled: true, onboardingCompleted: false)
        }
        
        return SettingsDTO(id: id, voiceGuidance: Int(voice), hapticsEnabled: haptics, onboardingCompleted: onboarding)
    }
    
    func save(_ s: SettingsDTO) throws {
        let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "Settings")
        request.fetchLimit = 1
        
        let entity = try context.fetch(request).first ?? NSEntityDescription.insertNewObject(forEntityName: "Settings", into: context)
        
        entity.setValue(s.id, forKey: "id")
        entity.setValue(Int16(s.voiceGuidance), forKey: "voiceGuidance")
        entity.setValue(s.hapticsEnabled, forKey: "hapticsEnabled")
        entity.setValue(s.onboardingCompleted, forKey: "onboardingCompleted")
        entity.setValue(Date(), forKey: "updatedAtUTC")
        
        try context.save()
    }
}

