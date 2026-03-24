import SwiftUI
import WidgetKit

@main
struct WeatherWiseWidgetBundle: WidgetBundle {
    var body: some Widget {
        WeatherWidget()
        MoonWidget()
    }
}
