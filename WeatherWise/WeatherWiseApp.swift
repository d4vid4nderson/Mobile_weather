import SwiftUI

@main
struct WeatherWiseApp: App {
    @StateObject private var viewModel = WeatherViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}
