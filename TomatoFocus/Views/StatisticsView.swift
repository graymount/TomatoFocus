import SwiftUI

struct StatisticsView: View {
    @ObservedObject private var statsStore = StatisticsStore.shared
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [Color(red: 0.1, green: 0.1, blue: 0.3), Color(red: 0.2, green: 0.2, blue: 0.5)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 25) {
                    // Header
                    Text("专注统计")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top)
                    
                    // Summary cards
                    summaryCardsView
                    
                    // Last 7 days chart
                    weeklyStatsView
                }
                .padding()
            }
        }
    }
    
    private var summaryCardsView: some View {
        VStack(spacing: 15) {
            // Total pomodoros completed
            StatCardView(
                title: "总番茄数",
                value: "\(statsStore.totalPomodoroCount)",
                iconName: "timer",
                color: Color.red
            )
            
            // Total focus time
            StatCardView(
                title: "总专注时间",
                value: statsStore.totalFocusTimeFormatted,
                iconName: "clock",
                color: Color.blue
            )
            
            // Today's pomodoros
            let todayStats = statsStore.getDailyStats()[statsStore.getCurrentDateString()] ?? DailyStats(pomodoroCount: 0, focusMinutes: 0)
            
            StatCardView(
                title: "今日番茄数",
                value: "\(todayStats.pomodoroCount)",
                iconName: "calendar",
                color: Color.green
            )
        }
    }
    
    private var weeklyStatsView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("近7天记录")
                .font(.headline)
                .foregroundColor(.white)
            
            // Chart
            chart
                .frame(height: 200)
                .padding(.top, 10)
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
    }
    
    private var chart: some View {
        let weekStats = statsStore.getLastSevenDaysStats()
        let maxPomodoros = max(1, weekStats.map { $0.stats.pomodoroCount }.max() ?? 1)
        
        return HStack(alignment: .bottom, spacing: 8) {
            ForEach(weekStats.indices, id: \.self) { index in
                let dayStats = weekStats[index]
                let barHeight = dayStats.stats.pomodoroCount == 0 ? 0 : CGFloat(dayStats.stats.pomodoroCount) / CGFloat(maxPomodoros) * 180
                
                VStack {
                    // The bar
                    ZStack(alignment: .bottom) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 30, height: 180)
                        
                        RoundedRectangle(cornerRadius: 6)
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [Color.red.opacity(0.7), Color.red]),
                                startPoint: .top,
                                endPoint: .bottom
                            ))
                            .frame(width: 30, height: barHeight)
                    }
                    
                    // The day label
                    Text(formatDayLabel(dayStats.date))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    // The count label
                    Text("\(dayStats.stats.pomodoroCount)")
                        .font(.caption)
                        .foregroundColor(.white)
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
}

struct StatCardView: View {
    let title: String
    let value: String
    let iconName: String
    let color: Color
    
    var body: some View {
        HStack {
            // Icon
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.2))
                .clipShape(Circle())
            
            // Text
            VStack(alignment: .leading) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
    }
}

struct StatisticsView_Previews: PreviewProvider {
    static var previews: some View {
        StatisticsView()
    }
} 