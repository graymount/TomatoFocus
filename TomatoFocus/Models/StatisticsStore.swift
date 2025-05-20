import Foundation
import Combine

class StatisticsStore: ObservableObject {
    static let shared = StatisticsStore()
    
    private let userDefaults = UserDefaults.standard
    private let pomodoroCountKey = "completedPomodoroCount"
    private let totalFocusTimeKey = "totalFocusTimeInMinutes"
    private let dailyStatsKey = "dailyStats"
    
    @Published private(set) var totalPomodoroCount: Int
    @Published private(set) var totalFocusTimeInMinutes: Int
    @Published private(set) var dailyStats: [String: DailyStats] = [:]
    
    private init() {
        // 从 UserDefaults 加载初始数据
        self.totalPomodoroCount = userDefaults.integer(forKey: pomodoroCountKey)
        self.totalFocusTimeInMinutes = userDefaults.integer(forKey: totalFocusTimeKey)
        loadDailyStats()
    }
    
    private func loadDailyStats() {
        guard let data = userDefaults.data(forKey: dailyStatsKey),
              let stats = try? JSONDecoder().decode([String: DailyStats].self, from: data) else {
            return
        }
        self.dailyStats = stats
    }
    
    // MARK: - Stats Tracking
    
    func addCompletedPomodoro() {
        // Update total count
        totalPomodoroCount += 1
        userDefaults.set(totalPomodoroCount, forKey: pomodoroCountKey)
        
        // Update daily stats
        updateDailyStats(minutesCompleted: 25)
    }
    
    func addFocusTime(minutes: Int) {
        totalFocusTimeInMinutes += minutes
        userDefaults.set(totalFocusTimeInMinutes, forKey: totalFocusTimeKey)
    }
    
    // MARK: - Stats Reading
    
    var totalFocusTimeFormatted: String {
        let total = totalFocusTimeInMinutes
        let hours = total / 60
        let minutes = total % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    // MARK: - Daily Stats
    
    private func updateDailyStats(minutesCompleted: Int) {
        let today = getCurrentDateString()
        var updatedStats = dailyStats
        
        if var todayStats = updatedStats[today] {
            todayStats.pomodoroCount += 1
            todayStats.focusMinutes += minutesCompleted
            updatedStats[today] = todayStats
        } else {
            updatedStats[today] = DailyStats(pomodoroCount: 1, focusMinutes: minutesCompleted)
        }
        
        // 更新本地变量和存储
        dailyStats = updatedStats
        saveDailyStats(updatedStats)
        addFocusTime(minutes: minutesCompleted)
    }
    
    func getDailyStats() -> [String: DailyStats] {
        return dailyStats
    }
    
    private func saveDailyStats(_ stats: [String: DailyStats]) {
        if let data = try? JSONEncoder().encode(stats) {
            userDefaults.set(data, forKey: dailyStatsKey)
        }
    }
    
    func getLastSevenDaysStats() -> [(date: String, stats: DailyStats)] {
        let calendar = Calendar.current
        
        return (0..<7).compactMap { dayOffset in
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else {
                return nil
            }
            
            let dateString = dateFormatter.string(from: date)
            let stats = dailyStats[dateString] ?? DailyStats(pomodoroCount: 0, focusMinutes: 0)
            
            return (dateString, stats)
        }.reversed()
    }
    
    // MARK: - Helpers
    
    func getCurrentDateString() -> String {
        return dateFormatter.string(from: Date())
    }
    
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }
}

struct DailyStats: Codable {
    var pomodoroCount: Int
    var focusMinutes: Int
} 