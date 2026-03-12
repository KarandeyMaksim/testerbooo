import SwiftUI
import Combine

@main
struct BiteloMorinaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup {
            VyralisAppRouter()
        }
    }
}

class AppState: ObservableObject {
    @Published var isOnboardingCompleted: Bool
    
    init() {
        self.isOnboardingCompleted = DependencyContainer.shared.isOnboardingCompleted()
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // AppsFlyer теперь запускается из bootSequence после проверки даты
        return true
    }
}
