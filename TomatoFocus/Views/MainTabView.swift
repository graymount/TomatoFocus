import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var isShowingOnboarding = !UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                TimerView()
                    .tabItem {
                        Label("番茄钟", systemImage: "timer")
                    }
                    .tag(0)
                
                StatisticsView()
                    .tabItem {
                        Label("统计", systemImage: "chart.bar")
                    }
                    .tag(1)
            }
            .accentColor(.white) // 使用白色作为选中状态的颜色
            .onAppear {
                // 自定义TabBar外观
                let appearance = UITabBarAppearance()
                appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
                appearance.backgroundColor = UIColor(Color.black.opacity(0.6))
                
                // 设置未选中项的颜色
                appearance.stackedLayoutAppearance.normal.iconColor = UIColor.lightGray
                appearance.stackedLayoutAppearance.normal.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.lightGray]
                
                // 设置选中项的颜色
                appearance.stackedLayoutAppearance.selected.iconColor = UIColor.white
                appearance.stackedLayoutAppearance.selected.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
                
                // 应用外观
                UITabBar.appearance().standardAppearance = appearance
                if #available(iOS 15.0, *) {
                    UITabBar.appearance().scrollEdgeAppearance = appearance
                }
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
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
} 