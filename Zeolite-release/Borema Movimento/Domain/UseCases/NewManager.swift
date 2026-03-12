//
//  AppsFlyerManager.swift
//  ApsTest
//
//  Простая инициализация AppsFlyer
//

import Foundation
import AppsFlyerLib
import AppTrackingTransparency
import AdSupport
import UIKit

class AppsFlyerManager: NSObject, AppsFlyerLibDelegate {
    
    static let shared = AppsFlyerManager()
    
    private var isInitialized = false
    private var attStatusReceived = false
    private var initializationCompletion: (() -> Void)?
    
    private override init() {
        super.init()
        setupAppsFlyer()
    }
    
    // Настройка AppsFlyer
    private func setupAppsFlyer() {
        let appsFlyer = AppsFlyerLib.shared()
        appsFlyer.appsFlyerDevKey = "7pVWrzNLTSKXGHFWUoBdCN"
        appsFlyer.appleAppID = "6755532237"
        appsFlyer.waitForATTUserAuthorization(timeoutInterval: 10)
        appsFlyer.delegate = self
    }
    
    // Запрос разрешения и старт с completion
    func start(completion: @escaping () -> Void) {
        initializationCompletion = completion
        
        // Минимальная задержка для готовности UI к показу ATT диалога
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let self = self else { return }
            
            if #available(iOS 14, *) {
                let currentStatus = ATTrackingManager.trackingAuthorizationStatus
                print("ATT Current Status: \(currentStatus.rawValue)")
                
                if currentStatus == .notDetermined {
                    print("🔔 Requesting ATT authorization...")
                    ATTrackingManager.requestTrackingAuthorization { [weak self] status in
                        let statusString: String
                        switch status {
                        case .notDetermined: statusString = "notDetermined"
                        case .restricted: statusString = "restricted"
                        case .denied: statusString = "denied"
                        case .authorized: statusString = "authorized"
                        @unknown default: statusString = "unknown"
                        }
                        print("✅ ATT Status after request: \(statusString) (\(status.rawValue))")
                        self?.attStatusReceived = true
                        AppsFlyerLib.shared().start()
                        self?.waitForAppsFlyerData()
                    }
                } else {
                    let statusString: String
                    switch currentStatus {
                    case .notDetermined: statusString = "notDetermined"
                    case .restricted: statusString = "restricted"
                    case .denied: statusString = "denied"
                    case .authorized: statusString = "authorized"
                    @unknown default: statusString = "unknown"
                    }
                    print("ℹ️ ATT already determined: \(statusString) (\(currentStatus.rawValue))")
                    self.attStatusReceived = true
                    AppsFlyerLib.shared().start()
                    self.waitForAppsFlyerData()
                }
            } else {
                AppsFlyerLib.shared().start()
                self.waitForAppsFlyerData()
            }
        }
    }
    
    // Ожидание данных AppsFlyer (sub1 и sub2)
    private func waitForAppsFlyerData() {
        let startTime = Date()
        let timeout: TimeInterval = 2.0
        
        func checkData() {
            let appsFlyerUID = AppsFlyerLib.shared().getAppsFlyerUID() ?? ""
            let advertisingID = ASIdentifierManager.shared().advertisingIdentifier.uuidString
            
            let hasValidUID = !appsFlyerUID.isEmpty
            let hasValidIDFA = advertisingID != "00000000-0000-0000-0000-000000000000"
            
            let elapsed = Date().timeIntervalSince(startTime)
            
            if (hasValidUID && hasValidIDFA && isInitialized) || elapsed >= timeout {
                if elapsed >= timeout {
                    print("⚠️ AppsFlyer timeout - proceeding anyway")
                }
                
                print("📊 AppsFlyer UID (sub1): \(appsFlyerUID)")
                print("📱 Advertising ID (sub2): \(advertisingID)")
                
                initializationCompletion?()
                initializationCompletion = nil
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    checkData()
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            checkData()
        }
    }
    
    // Получение AppsFlyer UID (sub1)
    func getAppsFlyerUID() -> String {
        return AppsFlyerLib.shared().getAppsFlyerUID() ?? ""
    }
    
    // Получение IDFA (sub2)
    func getAdvertisingID() -> String {
        return ASIdentifierManager.shared().advertisingIdentifier.uuidString
    }
    
    // Генерация кастомной ссылки с sub1 и sub2
    func getCustomLink(baseURL: String) -> String {
        let appsFlyerUID = getAppsFlyerUID()
        let advertisingID = getAdvertisingID()
        
        let separator = baseURL.contains("?") ? "&" : "?"
        let customLink = "\(baseURL)\(separator)sub1=\(appsFlyerUID)&sub2=\(advertisingID)"
        
        print("🔗 Custom Link: \(customLink)")
        print("📊 AppsFlyer UID (sub1): \(appsFlyerUID)")
        print("📱 Advertising ID (sub2): \(advertisingID)")
        
        return customLink
    }
    
    // Callback с данными атрибуции
    func onConversionDataSuccess(_ conversionInfo: [AnyHashable : Any]) {
        print("LOG : \(conversionInfo)")
        isInitialized = true
    }
    
    func onConversionDataFail(_ error: Error) {
        print("❌ Error: \(error.localizedDescription)")
        isInitialized = true // Продолжаем даже при ошибке
    }
    
    // Отправка кастомного ивента
    func logEvent() {
        AppsFlyerLib.shared().logEvent("myTestEvent", withValues: nil)
        print("📊 Event sent: myTestEvent")
    }
    
    // Отправка ивента с параметрами (опционально)
    func logEventWithParams(params: [String: Any]) {
        AppsFlyerLib.shared().logEvent("myTestEvent", withValues: params)
        print("📊 Event sent: myTestEvent with params: \(params)")
    }
}

