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
    
    // Settings for each mode that will be updated by ConfigurationModel
    private var focusTime = 25
    private var shortBreakTime = 5
    private var longBreakTime = 15
    
    init(minutes: Int = 25) {
        self.focusTime = minutes
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
                setTime(minutes: longBreakTime)
            } else {
                mode = .shortBreak
                setTime(minutes: shortBreakTime)
            }
        case .shortBreak, .longBreak:
            mode = .focus
            setTime(minutes: focusTime)
        }
        
        // Send notification
        NotificationManager.shared.sendTimerCompleteNotification(mode: mode)
    }
    
    func setTime(minutes: Int) {
        initialTime = minutes * 60
        timeRemaining = initialTime
    }
    
    func setCustomTime(minutes: Int) {
        // Update the appropriate time setting based on current mode
        switch mode {
        case .focus:
            focusTime = minutes
        case .shortBreak:
            shortBreakTime = minutes
        case .longBreak:
            longBreakTime = minutes
        }
        
        setTime(minutes: minutes)
    }
    
    // MARK: - New Quick Action Methods
    
    /// Add minutes to current timer (only when not active or paused)
    func addMinutes(_ minutes: Int) {
        guard !isActive || isPaused else { return }
        
        let additionalSeconds = minutes * 60
        timeRemaining += additionalSeconds
        initialTime += additionalSeconds
    }
    
    /// Set custom duration in seconds
    func setCustomDuration(_ seconds: Int) {
        guard !isActive || isPaused else { return }
        
        initialTime = seconds
        timeRemaining = seconds
    }
    
    /// Reset to default time for current mode
    func resetToDefault() {
        guard !isActive || isPaused else { return }
        
        switch mode {
        case .focus:
            setTime(minutes: 25) // Default focus time
        case .shortBreak:
            setTime(minutes: 5)  // Default short break
        case .longBreak:
            setTime(minutes: 15) // Default long break
        }
    }
    
    // Update all time settings at once (used by ConfigurationModel)
    func updateTimeSettings(focusTime: Int, shortBreakTime: Int, longBreakTime: Int) {
        self.focusTime = focusTime
        self.shortBreakTime = shortBreakTime
        self.longBreakTime = longBreakTime
        
        // Update current timer if needed
        switch mode {
        case .focus:
            setTime(minutes: focusTime)
        case .shortBreak:
            setTime(minutes: shortBreakTime)
        case .longBreak:
            setTime(minutes: longBreakTime)
        }
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