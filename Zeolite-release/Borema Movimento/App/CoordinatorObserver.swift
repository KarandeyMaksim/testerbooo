import Foundation
import WebKit
import Combine

/// Singleton менеджер для логики WebView
final class CoordinatorObserver {
    static let shared = CoordinatorObserver()
    
    private var currentView: WKWebView?
    private var shouldSaveNextURL = false
    private var lastLoadedURL: URL?
    private var stateUpdateTimer: Timer?
    
    private init() {
    }
    
    func setView(_ view: WKWebView) {
        self.currentView = view
        startStateUpdateTimer()
    }
    
    func setSaveNextURL(_ shouldSave: Bool) {
        self.shouldSaveNextURL = shouldSave
    }
    
    func getShouldSaveNextURL() -> Bool {
        return shouldSaveNextURL
    }
    
    func setLastLoadedURL(_ url: URL?) {
        self.lastLoadedURL = url
    }
    
    func getLastLoadedURL() -> URL? {
        return lastLoadedURL
    }
    
    func handleNavigationFinished(url: URL?) {
        guard let url = url else { return }
        
        // Предотвращаем бесконечные перезагрузки
        if let lastURL = lastLoadedURL, lastURL.absoluteString == url.absoluteString {
            print("проверки: URL уже загружен, пропускаем сохранение")
            return
        }
        
        lastLoadedURL = url
        
        if shouldSaveNextURL {
            print("проверки: сохраняем финальный URL из WebView: \(url.absoluteString)")
            NewExerciseService.shared.saveFinalURL(url)
            shouldSaveNextURL = false
            
            // Извлекаем pathId из URL
            if let pathId = NewExerciseService.shared.extractPathId(from: url, htmlData: nil) {
                NewExerciseService.shared.savePathId(pathId)
            }
        }
    }
    
    func handleLoadError(error: Error) {
        let nsError = error as NSError
        let errorCode = nsError.code
        
        // Проверяем, был ли показан альтернативный режим
        if NewExerciseService.shared.hasShownAlternativeMode() {
            // Проверяем тип ошибки (404, timeout, connection errors)
            if errorCode == NSURLErrorTimedOut || 
               errorCode == NSURLErrorCannotConnectToHost ||
               errorCode == NSURLErrorNetworkConnectionLost ||
               errorCode == NSURLErrorNotConnectedToInternet ||
               errorCode == 404 {
                
                NewExerciseService.shared.handleFallback { fallbackURL in
                    if let url = fallbackURL {
                        DispatchQueue.main.async {
                            self.currentView?.load(URLRequest(url: url))
                        }
                    }
                }
            }
        }
    }
    
    func checkFor404Error(in view: WKWebView, completion: @escaping (Bool) -> Void) {
        view.evaluateJavaScript("document.title") { result, error in
            if let title = result as? String, title.lowercased().contains("404") {
                completion(true)
                return
            }
            
            view.evaluateJavaScript("document.body.innerText") { result, error in
                if let bodyText = result as? String {
                    let has404 = bodyText.lowercased().contains("404") || 
                                bodyText.lowercased().contains("not found") ||
                                bodyText.lowercased().contains("page not found")
                    completion(has404)
                } else {
                    completion(false)
                }
            }
        }
    }
    
    private func startStateUpdateTimer() {
        stateUpdateTimer?.invalidate()
        stateUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            self?.updateStateFromView()
        }
    }
    
    private func updateStateFromView() {
        guard let view = currentView else { return }
        // Состояние обновляется через bindings в SwiftUI
    }
    
    deinit {
        stateUpdateTimer?.invalidate()
    }
}
