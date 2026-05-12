import SwiftUI

@main
struct BuildToolsApp: App {
    @StateObject private var appState = AppState()
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            SplashView()
                .environmentObject(appState)
        }
    }
}

// MARK: - Root View (routing)
struct RootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if !appState.hasCompletedOnboarding {
                OnboardingView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
            } else if !appState.isLoggedIn {
                WelcomeView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .opacity
                    ))
            } else {
                MainTabView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .opacity
                    ))
            }
        }
        .animation(DS.spring, value: appState.isLoggedIn)
        .animation(DS.spring, value: appState.hasCompletedOnboarding)
        .preferredColorScheme(appState.colorScheme)
    }
}
