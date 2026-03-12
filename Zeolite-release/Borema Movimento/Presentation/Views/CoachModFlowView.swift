import SwiftUI
import WebKit
import StoreKit

/// Основной View для альтернативного режима
struct CoachModFlowView: View {
    let entryURL: URL
    @State private var canGoBack = false
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            Color.black
            
            TraineeModFlowView(
                url: entryURL,
                canGoBack: $canGoBack,
                isLoading: $isLoading
            )
        }
        .statusBarHidden(true)
        .navigationBarHidden(true)
        .onAppear {
            checkRatingAlertEligibility()
        }
    }
    
    private func checkRatingAlertEligibility() {
        // Проверяем, был ли показан альтернативный режим при первом запуске
        if NewExerciseService.shared.hasShownAlternativeMode() &&
           !NewExerciseService.shared.hasShownRatingAlert() {
            // Показываем алерт при втором запуске (минимальная задержка)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                showRatingAlert()
            }
        }
    }
    
    private func showRatingAlert() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }
        
        let alert = UIAlertController(
            title: "Rate the App",
            message: "If you enjoy using this app, please take a moment to rate it!",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Rate", style: .default) { _ in
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                SKStoreReviewController.requestReview(in: windowScene)
            }
            NewExerciseService.shared.setHasShownRatingAlert(true)
        })
        
        alert.addAction(UIAlertAction(title: "Later", style: .cancel) { _ in
            NewExerciseService.shared.setHasShownRatingAlert(true)
        })
        
        rootViewController.present(alert, animated: true)
    }
}

/// WKWebView обертка для SwiftUI
struct TraineeModFlowView: UIViewRepresentable {
    let url: URL
    @Binding var canGoBack: Bool
    @Binding var isLoading: Bool
    
    func makeCoordinator() -> TraineeModCoordinator {
        TraineeModCoordinator(canGoBack: $canGoBack, isLoading: $isLoading)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences = preferences
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.suppressesIncrementalRendering = false
        configuration.allowsAirPlayForMediaPlayback = false
        
        let view = WKWebView(frame: .zero, configuration: configuration)
        view.navigationDelegate = context.coordinator
        view.uiDelegate = context.coordinator
        view.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_6_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.6 Mobile/15E148 Safari/604.1"
        
        // Оптимизации для отклика ввода
        view.scrollView.keyboardDismissMode = .interactive
        view.scrollView.delaysContentTouches = false
        view.scrollView.canCancelContentTouches = true
        view.scrollView.scrollsToTop = false
        view.allowsLinkPreview = false
        view.allowsBackForwardNavigationGestures = true
        
        // Безопасность
        if #available(iOS 16.4, *) {
            view.isInspectable = false
        }
        
        view.backgroundColor = .black
        view.scrollView.backgroundColor = .black
        
        // Полностью отключаем safe area insets для ScrollView
        view.scrollView.contentInsetAdjustmentBehavior = .never
        view.scrollView.contentInset = .zero
        view.scrollView.scrollIndicatorInsets = .zero
        
        context.coordinator.setView(view)
        CoordinatorObserver.shared.setView(view)
        
        // Загружаем URL
        print("проверки: начинаем загрузку URL в WebView: \(url.absoluteString)")
        let request = URLRequest(url: url)
        view.load(request)
        
        return view
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Обновляем ссылку на view в coordinator
        context.coordinator.setView(uiView)
        CoordinatorObserver.shared.setView(uiView)
        
        // Убеждаемся, что insets всегда нулевые
        uiView.scrollView.contentInset = .zero
        uiView.scrollView.scrollIndicatorInsets = .zero
        
        let newCanGoBack = uiView.canGoBack
        let newIsLoading = uiView.isLoading
        
        // Обновляем bindings
        DispatchQueue.main.async {
            self.canGoBack = newCanGoBack
            self.isLoading = newIsLoading
        }
    }
    
    static func dismantleUIView(_ uiView: WKWebView, coordinator: TraineeModCoordinator) {
        // Cleanup если нужно
    }
}

/// Coordinator для обработки навигации
class TraineeModCoordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
    @Binding var canGoBack: Bool
    @Binding var isLoading: Bool
    
    private weak var view: WKWebView?
    
    init(canGoBack: Binding<Bool>, isLoading: Binding<Bool>) {
        _canGoBack = canGoBack
        _isLoading = isLoading
    }
    
    func setView(_ view: WKWebView) {
        self.view = view
    }
    
    // MARK: - WKNavigationDelegate
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }
        
        let scheme = url.scheme?.lowercased() ?? ""
        
        if ["http", "https", "about", "data"].contains(scheme) {
            decisionHandler(.allow)
            return
        }
        
        let externalSchemes = ["tel", "mailto", "sms", "tg", "telegram", "viber", "whatsapp", "fb", "twitter", "instagram", "skype", "facetime", "maps", "itms", "itms-apps"]
        
        if externalSchemes.contains(scheme) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
            decisionHandler(.cancel)
            return
        }
        
        decisionHandler(.cancel)
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        DispatchQueue.main.async {
            self.isLoading = true
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.async {
            self.isLoading = false
            self.canGoBack = webView.canGoBack
        }
        
        if let currentURL = webView.url, currentURL.absoluteString != "about:blank" {
            print("проверки: WebView загрузил URL: \(currentURL.absoluteString)")
            // Проверяем на 404 ошибку
            CoordinatorObserver.shared.checkFor404Error(in: webView) { is404 in
                if is404 {
                    print("проверки: обнаружена 404 ошибка")
                    CoordinatorObserver.shared.handleLoadError(error: NSError(domain: "HTTPError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Page not found"]))
                } else {
                    // handleNavigationFinished уже сохраняет URL если нужно
                    CoordinatorObserver.shared.handleNavigationFinished(url: currentURL)
                }
            }
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        DispatchQueue.main.async {
            self.isLoading = false
        }
        CoordinatorObserver.shared.handleLoadError(error: error)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        DispatchQueue.main.async {
            self.isLoading = false
        }
        CoordinatorObserver.shared.handleLoadError(error: error)
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            if let serverTrust = challenge.protectionSpace.serverTrust {
                let credential = URLCredential(trust: serverTrust)
                completionHandler(.useCredential, credential)
                return
            }
        }
        completionHandler(.performDefaultHandling, nil)
    }
    
    // MARK: - WKUIDelegate
    
    func webView(_ webView: WKWebView, createViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
}
