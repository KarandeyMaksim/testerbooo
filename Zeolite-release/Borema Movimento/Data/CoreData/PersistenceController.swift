import CoreData

class PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "BiteloMorina")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Core Data failed to load: \(error.localizedDescription)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        seedInitialData()
    }
    
    private func seedInitialData() {
        let context = container.viewContext
        
        let protocolsRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Protocol")
        let protocolsCount = try? context.count(for: protocolsRequest)
        
        if protocolsCount == 0 {
            seedProtocols(context: context)
            seedLevelProfiles(context: context)
            seedSettings(context: context)
            seedStabilityProgress(context: context)
            
            try? context.save()
        }
    }
    
    private func seedProtocols(context: NSManagedObjectContext) {
        let protocols: [(name: String, slug: String, category: Int16)] = [
            ("360 Breathing Supine", "breathing_supine", 1),
            ("Bear/Quadruped 360", "bear_quadruped", 1),
            ("Pallof Hold", "pallof_hold", 2),
            ("Dead Bug 360", "dead_bug", 1),
            ("Half-Kneeling Pressout", "half_kneel_pressout", 2),
            ("Side Plank Breathing", "side_plank_breathing", 2)
        ]
        
        for proto in protocols {
            let entity = NSEntityDescription.insertNewObject(forEntityName: "Protocol", into: context)
            entity.setValue(UUID(), forKey: "id")
            entity.setValue(proto.name, forKey: "name")
            entity.setValue(proto.slug, forKey: "slug")
            entity.setValue(proto.category, forKey: "categoryRaw")
            entity.setValue(Date(), forKey: "createdAtUTC")
        }
    }
    
    private func seedLevelProfiles(context: NSManagedObjectContext) {
        let protocolsRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "Protocol")
        guard let protocols = try? context.fetch(protocolsRequest) else { return }
        
        for proto in protocols {
            guard let protoId = proto.value(forKey: "id") as? UUID else { continue }
            
            for level in 1...3 {
                let entity = NSEntityDescription.insertNewObject(forEntityName: "LevelProfile", into: context)
                entity.setValue(UUID(), forKey: "id")
                entity.setValue(protoId, forKey: "protocolId")
                entity.setValue(Int16(level), forKey: "levelRaw")
                
                let phasesData = createPhasesJSON(level: level)
                entity.setValue(phasesData, forKey: "phasesJSON")
                
                let voiceCuesData = createVoiceCuesJSON()
                entity.setValue(voiceCuesData, forKey: "voiceCuesJSON")
                
                entity.setValue(Date(), forKey: "createdAtUTC")
                entity.setValue(Date(), forKey: "updatedAtUTC")
            }
        }
    }
    
    private func createPhasesJSON(level: Int) -> Data {
        let breathCycleDuration = level == 1 ? 10 : (level == 2 ? 8 : 6)
        var phases: [[String: Any]] = []
        
        var totalTime = 0
        while totalTime < 300 {
            let inhale: [String: Any] = ["type": 0, "duration": breathCycleDuration / 2, "side": NSNull()]
            let exhale: [String: Any] = ["type": 1, "duration": breathCycleDuration / 2, "side": NSNull()]
            phases.append(inhale)
            phases.append(exhale)
            totalTime += breathCycleDuration
        }
        
        return try! JSONSerialization.data(withJSONObject: phases, options: [])
    }
    
    private func createVoiceCuesJSON() -> Data {
        let cues: [String: String] = [
            "inhale": "Inhale 360",
            "exhale": "Exhale - ribs down",
            "neutral": "Breathe steadily",
            "sideSwitch": "Switch sides"
        ]
        return try! JSONSerialization.data(withJSONObject: cues, options: [])
    }
    
    private func seedSettings(context: NSManagedObjectContext) {
        let entity = NSEntityDescription.insertNewObject(forEntityName: "Settings", into: context)
        entity.setValue(UUID(), forKey: "id")
        entity.setValue(Int16(2), forKey: "voiceGuidance")
        entity.setValue(true, forKey: "hapticsEnabled")
        entity.setValue(false, forKey: "onboardingCompleted")
        entity.setValue(Date(), forKey: "createdAtUTC")
        entity.setValue(Date(), forKey: "updatedAtUTC")
    }
    
    private func seedStabilityProgress(context: NSManagedObjectContext) {
        let entity = NSEntityDescription.insertNewObject(forEntityName: "StabilityProgress", into: context)
        entity.setValue(UUID(), forKey: "id")
        entity.setValue(Int16(1), forKey: "currentLevelRaw")
        entity.setValue(Int16(0), forKey: "cleanStreakDays")
        entity.setValue(Date(), forKey: "lastEvaluatedAtUTC")
    }
}

