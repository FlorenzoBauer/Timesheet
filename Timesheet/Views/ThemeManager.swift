import SwiftUI
import Combine

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    // MARK: - PERSISTENCE
    @AppStorage("accentColorHex") private var accentColorHex: String = "F4C2C2"
    @AppStorage("backgroundColorHex") private var backgroundColorHex: String = "1A1A1A"
    
    // NEW: Toggles to control behavior
    @AppStorage("isDarkMode") var isDarkMode: Bool = true
    @AppStorage("useCustomColors") var useCustomColors: Bool = false
    
    @Published var accentColor: Color = Color(hex: "F4C2C2")
    @Published var backgroundColor: Color = Color(hex: "1A1A1A")

    // MARK: - COMPUTED COLORS
    /// Use this in your Views! snap-back logic to Pink Blush asset
    var effectiveAccent: Color {
        useCustomColors ? accentColor : Color("AccentMain")
    }

    private init() {
        self.accentColor = Color(hex: accentColorHex)
        self.backgroundColor = Color(hex: backgroundColorHex)
    }
    
    // MARK: - UPDATERS
    func updateAccentColor(_ color: Color) {
        let hex = color.toHex() ?? "F4C2C2"
        accentColorHex = hex
        accentColor = color
    }
    
    func updateBackgroundColor(_ color: Color) {
        let hex = color.toHex() ?? "1A1A1A"
        backgroundColorHex = hex
        backgroundColor = color
    }
}

// MARK: - Hex Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 255, 255, 1)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }

    func toHex() -> String? {
        let uic = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        
        // Ensure we handle different color spaces (like Display P3)
        guard uic.getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        
        return String(format: "%02X%02X%02X",
                      Int(max(0, min(255, r * 255))),
                      Int(max(0, min(255, g * 255))),
                      Int(max(0, min(255, b * 255))))
    }
}
