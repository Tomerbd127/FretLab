import SwiftUI

/// Colors for scale tones, keyed by interval number so a 3rd is always the same color
/// whether it is major or minor.
enum DegreeColors {
    static func color(for interval: Interval) -> Color {
        switch (interval.number - 1) % 7 + 1 {
        case 1: .accentColor
        case 2: Color(hue: 0.48, saturation: 0.75, brightness: 0.62) // teal
        case 3: Color(hue: 0.36, saturation: 0.70, brightness: 0.58) // green
        case 4: Color(hue: 0.76, saturation: 0.55, brightness: 0.70) // purple
        case 5: Color(hue: 0.07, saturation: 0.85, brightness: 0.85) // orange
        case 6: Color(hue: 0.92, saturation: 0.60, brightness: 0.78) // pink
        default: Color(hue: 0.00, saturation: 0.72, brightness: 0.75) // red
        }
    }
}
