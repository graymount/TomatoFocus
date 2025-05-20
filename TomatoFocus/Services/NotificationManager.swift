import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {
        requestPermission()
    }
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("通知权限已获取")
            } else if let error = error {
                print("通知权限被拒绝: \(error)")
            }
        }
    }
    
    func sendTimerCompleteNotification(mode: TimerModel.TimerMode) {
        let content = UNMutableNotificationContent()
        
        switch mode {
        case .focus:
            content.title = "专注时间结束！"
            content.body = "该休息一下了，干得好！"
        case .shortBreak:
            content.title = "休息时间结束"
            content.body = "准备好再次专注了吗？"
        case .longBreak:
            content.title = "长休息结束"
            content.body = "让我们开始新的专注吧！"
        }
        
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
        
        // Also play notification sound
        AudioManager.shared.playNotificationSound()
    }
    
    func cancelAllPendingNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
} 