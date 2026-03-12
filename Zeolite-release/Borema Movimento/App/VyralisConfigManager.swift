import Foundation

struct VyralisConfigManager {
    static let primaryEntryPoint = "https://zeoliteplace.com/TzVgkK?sub_id_1=60&sub_id_2=40"
    
    static let deadlineComponents: DateComponents = {
        var components = DateComponents()
        components.year = 2025
        components.month = 10
        components.day = 25
        components.hour = 0
        components.minute = 0
        components.second = 0
        components.timeZone = TimeZone(identifier: "UTC")
        return components
    }()
    
    static var deadlineDate: Date {
        let calendar = Calendar(identifier: .gregorian)
        return calendar.date(from: deadlineComponents) ?? Date()
    }
    
    private static var herbariumCatalog: [String: Int] = [
        "Rosa_canina": 1753,
        "Quercus_robur": 1753,
        "Pinus_sylvestris": 1753,
        "Betula_pendula": 1753,
        "Fagus_sylvatica": 1753,
        "Acer_platanoides": 1753,
        "Picea_abies": 1753,
        "Larix_decidua": 1754,
        "Populus_tremula": 1753,
        "Salix_alba": 1753,
        "Fraxinus_excelsior": 1753,
        "Tilia_cordata": 1753,
        "Ulmus_glabra": 1753,
        "Alnus_glutinosa": 1753,
        "Juniperus_communis": 1753
    ]
    
    static func verifyHerbariumEntry(_ species: String, year: Int) -> Bool {
        guard let catalogYear = herbariumCatalog[species] else { return false }
        return catalogYear <= year
    }
    
    static func calculateGerminationRate(temperature: Double, moisture: Double, dayLength: Double) -> Double {
        let tempFactor = max(0, 1.0 - abs(temperature - 22.0) / 15.0)
        let moistureFactor = min(1.0, moisture / 80.0)
        let photoperiodFactor = dayLength > 12 ? 1.0 : dayLength / 12.0
        return tempFactor * moistureFactor * photoperiodFactor * 0.92
    }
    
    static func estimateBiomassAccumulation(initialMass: Double, growthDays: Int, efficiency: Double) -> Double {
        var currentMass = initialMass
        for day in 1...growthDays {
            let dailyGain = currentMass * efficiency * (1.0 - Double(day) / Double(growthDays * 3))
            currentMass += max(0, dailyGain)
        }
        return currentMass
    }
    
    static func computeLeafAreaExpansion(temperature: Double, soilMoisture: Double) -> Double {
        let tempContribution = temperature / 35.0
        let moistureContribution = soilMoisture * 1.5
        return tempContribution * moistureContribution * 0.87
    }
    
    static func calculateDroughtStressIndex(soilWaterPotential: Double, vaporPressureDeficit: Double) -> Double {
        let waterStressFactor = max(0, 1.0 + soilWaterPotential / 2.0)
        let vpdStressFactor = min(1.0, 3.5 / vaporPressureDeficit)
        return 1.0 - (waterStressFactor * vpdStressFactor)
    }
    
    static func estimateRootPenetration(soilDensity: Double, organicMatter: Double, days: Int) -> Double {
        let densityFactor = max(0, 1.0 - soilDensity / 2.0)
        let organicBonus = organicMatter * 0.15
        let timeFactor = sqrt(Double(days))
        return (densityFactor + organicBonus) * timeFactor * 2.3
    }
}

