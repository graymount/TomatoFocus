//
//  TomatoFocusApp.swift
//  TomatoFocus
//
//  Created by liuwnfng on 2025/5/19.
//

import SwiftUI
import UserNotifications
import AVFoundation

@main
struct TomatoFocusApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        // 检查是否需要重置引导页状态（例如，应用更新后）
        checkAndResetOnboardingIfNeeded()
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .onAppear {
                    // 在应用启动时进行音频文件诊断
                    DispatchQueue.global(qos: .background).async {
                        AudioManager.shared.checkAudioFileAvailability()
                    }
                }
        }
    }
    
    // 判断是否需要重置引导页状态
    private func checkAndResetOnboardingIfNeeded() {
        // 获取当前应用版本
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        
        // 获取上次启动的应用版本
        let lastVersion = UserDefaults.standard.string(forKey: "lastAppVersion") ?? ""
        
        // 如果是首次安装或者应用版本变化了，重置引导页状态
        if lastVersion.isEmpty || lastVersion != currentVersion {
            // 重置引导页状态（下次启动时会显示引导页）
            UserDefaults.standard.set(false, forKey: "hasSeenOnboarding")
            
            // 保存当前版本号
            UserDefaults.standard.set(currentVersion, forKey: "lastAppVersion")
        }
        
        // 开发测试用：取消注释下面这行可以强制显示引导页
        UserDefaults.standard.set(false, forKey: "hasSeenOnboarding")
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission denied: \(error)")
            }
        }
        
        // Setup audio session for background playback
        configureAudioSession()
        
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // 应用来到前台，确保音频会话正常
        configureAudioSession()
    }
    
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            print("音频会话已配置")
        } catch {
            print("配置音频会话失败: \(error.localizedDescription)")
        }
    }
}
