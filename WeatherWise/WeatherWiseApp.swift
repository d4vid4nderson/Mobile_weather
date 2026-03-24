import SwiftUI

@main
struct WeatherWiseApp: App {
    @StateObject private var viewModel = WeatherViewModel()

    init() {
        // Force tab bar to dark translucent so it works over gradient backgrounds
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithTransparentBackground()
        tabBarAppearance.backgroundEffect = UIBlurEffect(style: .systemThinMaterialDark)
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
