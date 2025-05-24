import SwiftUI
import Foundation

// MARK: - Theme Definition
struct AppTheme: Identifiable, Codable {
    let id: String
    let name: String
    let emoji: String
    
    // Default background sound for this theme
    let defaultSoundId: String
    
    // Background gradients
    let backgroundColors: [String] // Color hex strings
    let cardBackgroundColor: String
    
    // Timer colors for different modes
    let focusColor: String
    let shortBreakColor: String  
    let longBreakColor: String
    
    // Text colors
    let primaryTextColor: String
    let secondaryTextColor: String
    
    // Accent colors
    let accentColor: String
    let buttonBackgroundColor: String
    
    // Convert hex string to Color
    func color(from hex: String) -> Color {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        return Color(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    // Computed properties for easy access
    var backgroundGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: backgroundColors.map { color(from: $0) }),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var cardBackground: Color {
        color(from: cardBackgroundColor)
    }
    
    var focusTimerColor: Color {
        color(from: focusColor)
    }
    
    var shortBreakTimerColor: Color {
        color(from: shortBreakColor)
    }
    
    var longBreakTimerColor: Color {
        color(from: longBreakColor)
    }
    
    var primaryText: Color {
        color(from: primaryTextColor)
    }
    
    var secondaryText: Color {
        color(from: secondaryTextColor)
    }
    
    var accent: Color {
        color(from: accentColor)
    }
    
    var buttonBackground: Color {
        color(from: buttonBackgroundColor)
    }
}

// MARK: - Theme Manager
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: AppTheme
    
    private let userDefaults = UserDefaults.standard
    private let themeKey = "selectedTheme"
    
    init() {
        // Load saved theme or default to forest theme
        let savedThemeId = userDefaults.string(forKey: themeKey) ?? "forest"
        self.currentTheme = Self.predefinedThemes.first { $0.id == savedThemeId } ?? Self.predefinedThemes[0]
        
        // Switch to theme's default sound after a short delay to ensure AudioManager is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.switchToThemeDefaultSound()
        }
    }
    
    // MARK: - Predefined Themes
    static let predefinedThemes: [AppTheme] = [
        // 🌸 森林主题 (绿色系)
        AppTheme(
            id: "forest",
            name: "森林",
            emoji: "🌸",
            defaultSoundId: "forest",
            backgroundColors: ["2D5016", "3E7F2D", "5BA046"],
            cardBackgroundColor: "4CAF50",
            focusColor: "388E3C",
            shortBreakColor: "66BB6A", 
            longBreakColor: "81C784",
            primaryTextColor: "FFFFFF",
            secondaryTextColor: "E8F5E8",
            accentColor: "4CAF50",
            buttonBackgroundColor: "2E7D32"
        ),
        
        // 🌊 海洋主题 (蓝色系)
        AppTheme(
            id: "ocean",
            name: "海洋",
            emoji: "🌊",
            defaultSoundId: "ocean",
            backgroundColors: ["0D47A1", "1565C0", "1976D2"],
            cardBackgroundColor: "1976D2",
            focusColor: "1565C0",
            shortBreakColor: "42A5F5",
            longBreakColor: "64B5F6", 
            primaryTextColor: "FFFFFF",
            secondaryTextColor: "E3F2FD",
            accentColor: "2196F3",
            buttonBackgroundColor: "0D47A1"
        ),
        
        // ☕ 咖啡厅主题 (棕色系)
        AppTheme(
            id: "cafe",
            name: "咖啡厅",
            emoji: "☕",
            defaultSoundId: "cafe",
            backgroundColors: ["3E2723", "5D4037", "6D4C41"],
            cardBackgroundColor: "6D4C41",
            focusColor: "5D4037",
            shortBreakColor: "8D6E63",
            longBreakColor: "A1887F",
            primaryTextColor: "FFFFFF",
            secondaryTextColor: "EFEBE9",
            accentColor: "795548",
            buttonBackgroundColor: "3E2723"
        ),
        
        // 🌙 极简主题 (黑白系)
        AppTheme(
            id: "minimal",
            name: "极简",
            emoji: "🌙",
            defaultSoundId: "white_noise",
            backgroundColors: ["212121", "424242", "616161"],
            cardBackgroundColor: "424242",
            focusColor: "757575",
            shortBreakColor: "9E9E9E",
            longBreakColor: "BDBDBD",
            primaryTextColor: "FFFFFF",
            secondaryTextColor: "E0E0E0",
            accentColor: "9E9E9E",
            buttonBackgroundColor: "212121"
        ),
        
        // 🎵 Lofi主题 (暖色系)
        AppTheme(
            id: "lofi",
            name: "Lofi",
            emoji: "🎵",
            defaultSoundId: "rain",
            backgroundColors: ["4A148C", "6A1B9A", "7B1FA2"],
            cardBackgroundColor: "7B1FA2",
            focusColor: "6A1B9A",
            shortBreakColor: "9C27B0",
            longBreakColor: "BA68C8",
            primaryTextColor: "FFFFFF",
            secondaryTextColor: "F3E5F5",
            accentColor: "9C27B0",
            buttonBackgroundColor: "4A148C"
        ),
        
        // 🚀 科技主题 (紫色系)
        AppTheme(
            id: "tech",
            name: "科技",
            emoji: "🚀",
            defaultSoundId: "white_noise",
            backgroundColors: ["1A237E", "283593", "303F9F"],
            cardBackgroundColor: "303F9F",
            focusColor: "283593",
            shortBreakColor: "5C6BC0",
            longBreakColor: "7986CB",
            primaryTextColor: "FFFFFF",
            secondaryTextColor: "E8EAF6",
            accentColor: "3F51B5",
            buttonBackgroundColor: "1A237E"
        )
    ]
    
    // MARK: - Theme Management
    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
        userDefaults.set(theme.id, forKey: themeKey)
        
        // Auto-switch to theme's default sound
        switchToThemeDefaultSound()
    }
    
    // Get default sound for current theme
    func getThemeDefaultSound() -> AudioManager.BackgroundSound? {
        return AudioManager.BackgroundSound(rawValue: currentTheme.defaultSoundId)
    }
    
    // Switch to the current theme's default sound
    private func switchToThemeDefaultSound() {
        if let defaultSound = getThemeDefaultSound() {
            DispatchQueue.main.async {
                AudioManager.shared.selectSound(defaultSound)
            }
        }
    }
    
    func nextTheme() {
        guard let currentIndex = Self.predefinedThemes.firstIndex(where: { $0.id == currentTheme.id }) else { return }
        let nextIndex = (currentIndex + 1) % Self.predefinedThemes.count
        setTheme(Self.predefinedThemes[nextIndex])
    }
    
    func getTimerColor(for mode: TimerModel.TimerMode) -> Color {
        switch mode {
        case .focus:
            return currentTheme.focusTimerColor
        case .shortBreak:
            return currentTheme.shortBreakTimerColor
        case .longBreak:
            return currentTheme.longBreakTimerColor
        }
    }
    
    func getGradientColors(for mode: TimerModel.TimerMode) -> [Color] {
        let baseColor = getTimerColor(for: mode)
        // Create a gradient by darkening the base color
        return [baseColor, baseColor.opacity(0.7)]
    }
}

// MARK: - View Extensions for Theme Support
extension View {
    func themedBackground() -> some View {
        self.background(ThemeManager.shared.currentTheme.backgroundGradient.ignoresSafeArea())
    }
    
    func themedCardBackground() -> some View {
        self.background(ThemeManager.shared.currentTheme.cardBackground.opacity(0.2))
    }
    
    func themedPrimaryText() -> some View {
        self.foregroundColor(ThemeManager.shared.currentTheme.primaryText)
    }
    
    func themedSecondaryText() -> some View {
        self.foregroundColor(ThemeManager.shared.currentTheme.secondaryText)
    }
    
    func themedAccent() -> some View {
        self.foregroundColor(ThemeManager.shared.currentTheme.accent)
    }
} 