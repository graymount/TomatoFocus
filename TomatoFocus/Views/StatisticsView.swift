import SwiftUI

struct StatisticsView: View {
    @ObservedObject private var statsStore = StatisticsStore.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    
    // Device detection for iPad
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    var body: some View {
        ZStack {
            // Background using theme
            themeManager.currentTheme.backgroundGradient
                .ignoresSafeArea()
            
            GeometryReader { geometry in
                ScrollView {
                    LazyVStack(spacing: isIPad ? 35 : 25) {
                        // Header
                        Text("专注统计")
                            .font(isIPad ? .largeTitle : .largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.currentTheme.primaryText)
                            .padding(.top, isIPad ? 20 : 10)
                        
                        // Content based on device and orientation
                        if isIPad && geometry.size.width > geometry.size.height {
                            // iPad landscape: horizontal layout
                            HStack(alignment: .top, spacing: 30) {
                                VStack(spacing: 25) {
                                    summaryCardsView
                                }
                                .frame(maxWidth: geometry.size.width * 0.4)
                                
                                VStack(spacing: 25) {
                                    weeklyStatsView
                                    monthlyOverviewView
                                }
                                .frame(maxWidth: geometry.size.width * 0.55)
                            }
                        } else {
                            // iPhone and iPad portrait: vertical layout
                            VStack(spacing: isIPad ? 35 : 25) {
                                summaryCardsView
                                weeklyStatsView
                                monthlyOverviewView
                            }
                        }
                        
                        // 自适应底部间距 - 确保内容不被Tab Bar遮挡
                        Spacer()
                            .frame(height: max(180, bottomSafeAreaPadding(geometry: geometry) + 80))
                    }
                    .padding(isIPad ? 30 : 20)
                }
                .scrollIndicators(.hidden) // 隐藏滚动指示器，更清洁的外观
                .refreshable {
                    // 下拉刷新功能
                    await refreshStatistics()
                }
            }
        }
    }
    
    private var summaryCardsView: some View {
        let cardSpacing: CGFloat = isIPad ? 20 : 15
        return VStack(spacing: cardSpacing) {
            // Total pomodoros completed
            StatCardView(
                title: "总番茄数",
                value: "\(statsStore.totalPomodoroCount)",
                iconName: "timer",
                color: themeManager.currentTheme.accent
            )
            
            // Total focus time
            StatCardView(
                title: "总专注时间",
                value: statsStore.totalFocusTimeFormatted,
                iconName: "clock",
                color: themeManager.currentTheme.focusTimerColor
            )
            
            // Today's pomodoros
            let todayStats = statsStore.getDailyStats()[statsStore.getCurrentDateString()] ?? DailyStats(pomodoroCount: 0, focusMinutes: 0)
            
            StatCardView(
                title: "今日番茄数",
                value: "\(todayStats.pomodoroCount)",
                iconName: "calendar",
                color: themeManager.currentTheme.shortBreakTimerColor
            )
            
            // Today's focus time
            StatCardView(
                title: "今日专注时间",
                value: "\(todayStats.focusMinutes)分钟",
                iconName: "stopwatch",
                color: themeManager.currentTheme.longBreakTimerColor
            )
        }
    }
    
    private var weeklyStatsView: some View {
        VStack(alignment: .leading, spacing: isIPad ? 15 : 10) {
            Text("近7天记录")
                .font(isIPad ? .title2 : .headline)
                .foregroundColor(themeManager.currentTheme.primaryText)
            
            // Chart
            chart
                .frame(height: isIPad ? 250 : 200)
                .padding(.top, isIPad ? 15 : 10)
        }
        .padding(isIPad ? 25 : 15)
        .background(themeManager.currentTheme.cardBackground.opacity(0.2))
        .cornerRadius(isIPad ? 20 : 15)
    }
    
    private var monthlyOverviewView: some View {
        VStack(alignment: .leading, spacing: isIPad ? 15 : 10) {
            HStack {
                Text("本月概览")
                    .font(isIPad ? .title2 : .headline)
                    .foregroundColor(themeManager.currentTheme.primaryText)
                
                Spacer()
                
                Text("\(currentMonthName())")
                    .font(isIPad ? .callout : .caption)
                    .foregroundColor(themeManager.currentTheme.secondaryText)
            }
            
            HStack(spacing: isIPad ? 30 : 20) {
                VStack {
                    Text("\(monthlyCompletedPomodoros())")
                        .font(isIPad ? .title : .title2)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.currentTheme.primaryText)
                    Text("完成番茄")
                        .font(isIPad ? .callout : .caption)
                        .foregroundColor(themeManager.currentTheme.secondaryText)
                }
                
                Divider()
                    .background(themeManager.currentTheme.secondaryText)
                
                VStack {
                    Text("\(monthlyActivedays())")
                        .font(isIPad ? .title : .title2)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.currentTheme.primaryText)
                    Text("活跃天数")
                        .font(isIPad ? .callout : .caption)
                        .foregroundColor(themeManager.currentTheme.secondaryText)
                }
                
                Divider()
                    .background(themeManager.currentTheme.secondaryText)
                
                VStack {
                    Text("\(monthlyAveragePerDay())")
                        .font(isIPad ? .title : .title2)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.currentTheme.primaryText)
                    Text("日均番茄")
                        .font(isIPad ? .callout : .caption)
                        .foregroundColor(themeManager.currentTheme.secondaryText)
                }
            }
            .frame(height: isIPad ? 80 : 60)
        }
        .padding(isIPad ? 25 : 15)
        .background(themeManager.currentTheme.cardBackground.opacity(0.2))
        .cornerRadius(isIPad ? 20 : 15)
    }
    
    private var chart: some View {
        let weekStats = statsStore.getLastSevenDaysStats()
        let maxPomodoros = max(1, weekStats.map { $0.stats.pomodoroCount }.max() ?? 1)
        
        return HStack(alignment: .bottom, spacing: 8) {
            ForEach(weekStats.indices, id: \.self) { index in
                let dayStats = weekStats[index]
                let chartHeight: CGFloat = isIPad ? 220 : 180
                let barHeight = dayStats.stats.pomodoroCount == 0 ? 0 : CGFloat(dayStats.stats.pomodoroCount) / CGFloat(maxPomodoros) * chartHeight
                
                VStack {
                    // The bar
                    ZStack(alignment: .bottom) {
                        RoundedRectangle(cornerRadius: isIPad ? 8 : 6)
                            .fill(themeManager.currentTheme.secondaryText.opacity(0.3))
                            .frame(width: isIPad ? 40 : 30, height: isIPad ? 220 : 180)
                        
                        RoundedRectangle(cornerRadius: isIPad ? 8 : 6)
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [
                                    themeManager.currentTheme.accent.opacity(0.7),
                                    themeManager.currentTheme.accent
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            ))
                            .frame(width: isIPad ? 40 : 30, height: barHeight)
                    }
                    
                    // The day label
                    Text(formatDayLabel(dayStats.date))
                        .font(isIPad ? .callout : .caption)
                        .foregroundColor(themeManager.currentTheme.secondaryText)
                    
                    // The count label
                    Text("\(dayStats.stats.pomodoroCount)")
                        .font(isIPad ? .callout : .caption)
                        .foregroundColor(themeManager.currentTheme.primaryText)
                }
            }
        }
    }
    
    private func formatDayLabel(_ dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        guard let date = dateFormatter.date(from: dateString) else {
            return ""
        }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "E"
        return displayFormatter.string(from: date)
    }
    
    // MARK: - Helper Methods for Monthly Stats
    
    private func currentMonthName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月"
        return formatter.string(from: Date())
    }
    
    private func monthlyCompletedPomodoros() -> Int {
        let calendar = Calendar.current
        let now = Date()
        let monthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
        
        let dailyStats = statsStore.getDailyStats()
        var total = 0
        
        for (dateString, stats) in dailyStats {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            if let date = formatter.date(from: dateString), date >= monthStart {
                total += stats.pomodoroCount
            }
        }
        
        return total
    }
    
    private func monthlyActivedays() -> Int {
        let calendar = Calendar.current
        let now = Date()
        let monthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
        
        let dailyStats = statsStore.getDailyStats()
        var activeDays = 0
        
        for (dateString, stats) in dailyStats {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            if let date = formatter.date(from: dateString), 
               date >= monthStart && stats.pomodoroCount > 0 {
                activeDays += 1
            }
        }
        
        return activeDays
    }
    
    private func monthlyAveragePerDay() -> Int {
        let completed = monthlyCompletedPomodoros()
        let activeDays = monthlyActivedays()
        return activeDays > 0 ? completed / activeDays : 0
    }
    
    // MARK: - Adaptive Bottom Padding
    private func bottomSafeAreaPadding(geometry: GeometryProxy) -> CGFloat {
        // 获取安全区域信息
        let bottomSafeArea = geometry.safeAreaInsets.bottom
        
        // 基础tab bar高度（不同设备可能不同）
        let baseTabBarHeight: CGFloat = isIPad ? 65 : 49
        
        // 设备特定的额外间距
        let deviceSpecificPadding: CGFloat = {
            if isIPad {
                return 20 // iPad通常需要更多间距
            } else {
                // iPhone的自适应间距
                let screenHeight = geometry.size.height
                switch screenHeight {
                case 668...750: // iPhone SE, iPhone 8系列
                    return 15
                case 812...844: // iPhone X系列, iPhone 12 mini等
                    return 20
                case 896...932: // iPhone XS Max, iPhone 14 Pro Max等大屏设备
                    return 25
                default:
                    return 20 // 默认值
                }
            }
        }()
        
        // 计算总的底部间距
        // 如果有安全区域（如iPhone X系列），使用安全区域 + 少量额外间距
        // 如果没有安全区域（如iPhone 8系列），使用tab bar高度 + 设备特定间距
        if bottomSafeArea > 0 {
            // 有底部安全区域的设备（如iPhone X及以后）
            return bottomSafeArea + deviceSpecificPadding
        } else {
            // 没有底部安全区域的设备（如iPhone 8及之前）
            return baseTabBarHeight + deviceSpecificPadding
        }
    }
    
    // MARK: - Refresh Statistics
    @MainActor
    private func refreshStatistics() async {
        // 添加轻微延迟以提供更好的用户体验
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1秒延迟
        
        // 刷新统计数据
        statsStore.refreshStats()
    }
}

struct StatCardView: View {
    let title: String
    let value: String
    let iconName: String
    let color: Color
    @ObservedObject private var themeManager = ThemeManager.shared
    
    // Device detection for iPad
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    var body: some View {
        HStack {
            // Icon
            Image(systemName: iconName)
                .font(isIPad ? .title : .title2)
                .foregroundColor(color)
                .frame(width: isIPad ? 50 : 40, height: isIPad ? 50 : 40)
                .background(color.opacity(0.2))
                .clipShape(Circle())
            
            // Text
            VStack(alignment: .leading) {
                Text(title)
                    .font(isIPad ? .callout : .subheadline)
                    .foregroundColor(themeManager.currentTheme.secondaryText)
                
                Text(value)
                    .font(isIPad ? .title : .title2)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.currentTheme.primaryText)
            }
            
            Spacer()
        }
        .padding(isIPad ? 20 : 15)
        .background(themeManager.currentTheme.cardBackground.opacity(0.1))
        .cornerRadius(isIPad ? 20 : 15)
    }
}

struct StatisticsView_Previews: PreviewProvider {
    static var previews: some View {
        StatisticsView()
    }
} 