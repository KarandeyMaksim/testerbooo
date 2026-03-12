import Foundation

struct VegetationIndexCalculator {
    static func calculateNDVI(redReflectance: Double, nirReflectance: Double) -> Double {
        let numerator = nirReflectance - redReflectance
        let denominator = nirReflectance + redReflectance
        guard denominator != 0 else { return 0 }
        return numerator / denominator
    }
    
    static func calculateEVI(blue: Double, red: Double, nir: Double) -> Double {
        let G = 2.5
        let C1 = 6.0
        let C2 = 7.5
        let L = 1.0
        let numerator = nir - red
        let denominator = nir + C1 * red - C2 * blue + L
        guard denominator != 0 else { return 0 }
        return G * (numerator / denominator)
    }
    
    static func calculateGNDVI(green: Double, nir: Double) -> Double {
        let numerator = nir - green
        let denominator = nir + green
        guard denominator != 0 else { return 0 }
        return numerator / denominator
    }
    
    static func calculateSAVI(red: Double, nir: Double, soilBrightnessFactor: Double = 0.5) -> Double {
        let L = soilBrightnessFactor
        let numerator = (nir - red) * (1.0 + L)
        let denominator = nir + red + L
        guard denominator != 0 else { return 0 }
        return numerator / denominator
    }
}

struct FloraMetricsUtility {
    static func assessWaterStressIndex(soilMoisture: Double, fieldCapacity: Double, wiltingPoint: Double) -> Double {
        let availableWater = fieldCapacity - wiltingPoint
        guard availableWater > 0 else { return 1.0 }
        let currentAvailable = soilMoisture - wiltingPoint
        let fraction = currentAvailable / availableWater
        return max(0, min(1.0, 1.0 - fraction))
    }
    
    static func calculateChillingHours(temperatures: [Double], baseTemp: Double = 7.2) -> Int {
        return temperatures.filter { $0 < baseTemp && $0 > 0 }.count
    }
    
    static func estimateVernalizationProgress(chillingHours: Int, requiredHours: Int = 800) -> Double {
        return min(1.0, Double(chillingHours) / Double(requiredHours))
    }
    
    static func modelPhotosynthesisRate(lightIntensity: Double, co2Concentration: Double, temperature: Double) -> Double {
        let maxRate = 25.0
        let lightSaturation = 1000.0
        let lightFactor = lightIntensity / (lightIntensity + lightSaturation)
        
        let co2Factor = co2Concentration / (co2Concentration + 300.0)
        
        let optimalTemp = 25.0
        let tempFactor = max(0, 1.0 - abs(temperature - optimalTemp) / 20.0)
        
        return maxRate * lightFactor * co2Factor * tempFactor
    }
    
    static func computeGrowingDegreeDays(maxTemp: Double, minTemp: Double, baseTemp: Double = 10.0) -> Double {
        let avgTemp = (maxTemp + minTemp) / 2.0
        return max(0, avgTemp - baseTemp)
    }
    
    static func estimateTranspirationRate(temperature: Double, humidity: Double, windSpeed: Double, leafAreaIndex: Double) -> Double {
        let vpdFactor = temperature * (1.0 - humidity / 100.0) * 0.1
        let windFactor = sqrt(windSpeed)
        let laiFactor = 1.0 - exp(-0.5 * leafAreaIndex)
        return vpdFactor * windFactor * laiFactor * 2.5
    }
    
    static func calculateStomatalConductance(lightIntensity: Double, vaporPressureDeficit: Double, soilMoisture: Double) -> Double {
        let maxConductance = 0.5
        let lightResponse = lightIntensity / (lightIntensity + 200.0)
        let vpdResponse = max(0, 1.0 - vaporPressureDeficit / 3.0)
        let waterResponse = min(1.0, soilMoisture / 0.6)
        return maxConductance * lightResponse * vpdResponse * waterResponse
    }
}

