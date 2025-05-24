import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var isShowingOnboarding = !UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
    @StateObject private var timerModel = TimerModel()
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                ThemedTimerView(timerModel: timerModel)
                    .tabItem {
                        Label("番茄钟", systemImage: "timer")
                    }
                    .tag(0)
                
                StatisticsView()
                    .tabItem {
                        Label("统计", systemImage: "chart.bar")
                    }
                    .tag(1)
                
                ConfigurationView(timerModel: timerModel)
                    .tabItem {
                        Label("配置", systemImage: "gear")
                    }
                    .tag(2)
            }
            .accentColor(themeManager.currentTheme.accent)
            .onAppear {
                setupTabBarAppearance()
            }
            .onChange(of: themeManager.currentTheme.id) {
                // Update tab bar appearance when theme changes
                setupTabBarAppearance()
            }
            
            // 如果需要显示引导页，就全屏覆盖
            if isShowingOnboarding {
                OnboardingView(isShowingOnboarding: $isShowingOnboarding)
                    .transition(.opacity)
                    .zIndex(100) // 确保在最上层
            }
        }
        .animation(.easeInOut, value: isShowingOnboarding)
    }
    
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        
        // Use theme colors for background
        let backgroundColorHex = themeManager.currentTheme.backgroundColors.first ?? "000000"
        let backgroundColor = themeManager.currentTheme.color(from: backgroundColorHex)
        appearance.backgroundColor = UIColor(backgroundColor.opacity(0.8))
        
        // 设置未选中项的颜色
        let secondaryColor = UIColor(themeManager.currentTheme.secondaryText)
        appearance.stackedLayoutAppearance.normal.iconColor = secondaryColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: secondaryColor
        ]
        
        // 设置选中项的颜色
        let primaryColor = UIColor(themeManager.currentTheme.primaryText)
        appearance.stackedLayoutAppearance.selected.iconColor = primaryColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: primaryColor
        ]
        
        // 应用外观
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
} 