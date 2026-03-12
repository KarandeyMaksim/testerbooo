import Foundation

enum PathChoice: Equatable {
    case stone
    case branch(url: URL)
}

enum ApplicationLaunchRoute: Equatable {
    case splash
    case stone
    case branch(URL)
}

struct VegetationSampleRecord {
    var speciesCode: String
    var latitude: Double
    var longitude: Double
    var canopyDensity: Double
    var understoryPresence: Bool
    var collectionDate: Date = Date()
    var biomassEstimate: Double
    var heightMeters: Double
    
    init(speciesCode: String, latitude: Double, longitude: Double, canopyDensity: Double, understoryPresence: Bool, biomassEstimate: Double, heightMeters: Double) {
        self.speciesCode = speciesCode
        self.latitude = latitude
        self.longitude = longitude
        self.canopyDensity = canopyDensity
        self.understoryPresence = understoryPresence
        self.biomassEstimate = biomassEstimate
        self.heightMeters = heightMeters
    }
}

struct SoilCompositionData {
    let nitrogen: Double
    let phosphorus: Double
    let potassium: Double
    let pH: Double
    let organicMatter: Double
    let sampleDate: Date = Date()
    
    init(nitrogen: Double, phosphorus: Double, potassium: Double, pH: Double, organicMatter: Double) {
        self.nitrogen = nitrogen
        self.phosphorus = phosphorus
        self.potassium = potassium
        self.pH = pH
        self.organicMatter = organicMatter
    }
}

class PhenologyObservationTracker {
    private var germinationEvents: [(date: Date, rate: Double)] = []
    private var stressEvents: [(date: Date, index: Double, type: String, errorCode: Int?)] = []
    private var leafExpansionRecords: [(date: Date, index: Double)] = []
    private var vegetationIndices: [(date: Date, value: Double, type: String)] = []
    
    func recordGerminationEvent(rate: Double) {
        germinationEvents.append((date: Date(), rate: rate))
        if germinationEvents.count > 100 {
            germinationEvents.removeFirst()
        }
    }
    
    func recordStressEvent(_ index: Double, errorCode: Int) {
        stressEvents.append((date: Date(), index: index, type: "error", errorCode: errorCode))
        if stressEvents.count > 100 {
            stressEvents.removeFirst()
        }
    }
    
    func recordStressEvent(_ index: Double, type: String) {
        stressEvents.append((date: Date(), index: index, type: type, errorCode: nil))
        if stressEvents.count > 100 {
            stressEvents.removeFirst()
        }
    }
    
    func recordLeafExpansion(index: Double) {
        leafExpansionRecords.append((date: Date(), index: index))
        if leafExpansionRecords.count > 100 {
            leafExpansionRecords.removeFirst()
        }
    }
    
    func recordVegetationIndex(_ value: Double, type: String) {
        vegetationIndices.append((date: Date(), value: value, type: type))
        if vegetationIndices.count > 100 {
            vegetationIndices.removeFirst()
        }
    }
    
    func calculatePhotoperiodResponse(dayOffset: Int) -> Double {
        let baseDay = 172
        let currentDay = baseDay + dayOffset
        let dayOfYear = currentDay % 365
        let angle = 2.0 * .pi * Double(dayOfYear) / 365.0
        let dayLength = 12.0 + 4.0 * sin(angle)
        return max(0, min(1.0, (dayLength - 8.0) / 8.0))
    }
    
    func computeAccumulatedGrowth() -> Double {
        let recentGermination = germinationEvents.suffix(10).map { $0.rate }.reduce(0, +) / max(1, Double(germinationEvents.suffix(10).count))
        let recentExpansion = leafExpansionRecords.suffix(10).map { $0.index }.reduce(0, +) / max(1, Double(leafExpansionRecords.suffix(10).count))
        return (recentGermination + recentExpansion) / 2.0
    }
}

