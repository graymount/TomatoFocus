import Foundation
import SwiftUI

class TimerModel: ObservableObject {
    @Published var isActive = false
    @Published var isPaused = false
    @Published var timeRemaining: Int
    @Published var mode: TimerMode = .focus
    @Published var completedPomodoros = 0
    
    private var initialTime: Int
    private var timer = Timer()
    
    init(minutes: Int = 25) {
        self.initialTime = minutes * 60
        self.timeRemaining = initialTime
    }
    
    enum TimerMode {
        case focus
        case shortBreak
        case longBreak
    }
    
    func start() {
        isActive = true
        isPaused = false
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, !self.isPaused else { return }
            
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
            } else {
                self.completeTimer()
            }
        }
    }
    
    func pause() {
        isPaused = true
    }
    
    func resume() {
        isPaused = false
    }
    
    func reset() {
        isActive = false
        isPaused = false
        timeRemaining = initialTime
        timer.invalidate()
    }
    
    func completeTimer() {
        timer.invalidate()
        isActive = false
        
        // Track statistics
        if mode == .focus {
            completedPomodoros += 1
            StatisticsStore.shared.addCompletedPomodoro()
        }
        
        // Handle transitions between different modes
        switch mode {
        case .focus:
            if completedPomodoros % 4 == 0 {
                mode = .longBreak
                setTime(minutes: 15)
            } else {
                mode = .shortBreak
                setTime(minutes: 5)
            }
        case .shortBreak, .longBreak:
            mode = .focus
            setTime(minutes: 25)
        }
        
        // Send notification
        NotificationManager.shared.sendTimerCompleteNotification(mode: mode)
    }
    
    func setTime(minutes: Int) {
        initialTime = minutes * 60
        timeRemaining = initialTime
    }
    
    func setCustomTime(minutes: Int) {
        setTime(minutes: minutes)
    }
    
    var progress: CGFloat {
        CGFloat(Double(initialTime - timeRemaining) / Double(initialTime))
    }
    
    var timeRemainingFormatted: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
} 