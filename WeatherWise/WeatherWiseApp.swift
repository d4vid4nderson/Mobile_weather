import SwiftUI

@main
struct WeatherWiseApp: App {
    @StateObject private var viewModel = WeatherViewModel()

    init() {
        // Translucent tab bar that adapts to light/dark over gradient backgrounds
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithTransparentBackground()
        tabBarAppearance.backgroundEffect = UIBlurEffect(style: .systemThinMaterial)
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}
