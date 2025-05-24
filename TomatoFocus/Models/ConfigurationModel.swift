import Foundation
import SwiftUI

// Represents a configuration preset
struct TimerConfiguration: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var focusTime: Int // in minutes
    var shortBreakTime: Int // in minutes
    var longBreakTime: Int // in minutes
    var isCustom: Bool = false
    
    static func == (lhs: TimerConfiguration, rhs: TimerConfiguration) -> Bool {
        lhs.id == rhs.id
    }
}

class ConfigurationModel: ObservableObject {
    @Published var configurations: [TimerConfiguration] {
        didSet {
            saveConfigurations()
        }
    }
    
    @Published var selectedConfiguration: TimerConfiguration {
        didSet {
            saveSelectedConfiguration()
            applyConfiguration()
        }
    }
    
    // Advanced Settings
    @Published var autoStartBreak: Bool = false {
        didSet { UserDefaults.standard.set(autoStartBreak, forKey: "autoStartBreak") }
    }
    
    @Published var autoStartWork: Bool = false {
        didSet { UserDefaults.standard.set(autoStartWork, forKey: "autoStartWork") }
    }
    
    @Published var longBreakReminder: Bool = true {
        didSet { UserDefaults.standard.set(longBreakReminder, forKey: "longBreakReminder") }
    }
    
    @Published var statisticsTracking: Bool = true {
        didSet { UserDefaults.standard.set(statisticsTracking, forKey: "statisticsTracking") }
    }
    
    // Notification Settings
    @Published var startNotification: Bool = true {
        didSet { UserDefaults.standard.set(startNotification, forKey: "startNotification") }
    }
    
    @Published var completeNotification: Bool = true {
        didSet { UserDefaults.standard.set(completeNotification, forKey: "completeNotification") }
    }
    
    @Published var vibrationFeedback: Bool = true {
        didSet { UserDefaults.standard.set(vibrationFeedback, forKey: "vibrationFeedback") }
    }
    
    @Published var soundReminder: Bool = true {
        didSet { UserDefaults.standard.set(soundReminder, forKey: "soundReminder") }
    }
    
    private var timerModel: TimerModel
    

    
    init(timerModel: TimerModel) {
        // Enhanced default preset configurations
        let defaultConfigurations = [
            TimerConfiguration(name: "经典番茄", focusTime: 25, shortBreakTime: 5, longBreakTime: 15),
            TimerConfiguration(name: "程序员专注", focusTime: 30, shortBreakTime: 5, longBreakTime: 20),
            TimerConfiguration(name: "深度工作", focusTime: 45, shortBreakTime: 10, longBreakTime: 25),
            TimerConfiguration(name: "学习模式", focusTime: 50, shortBreakTime: 10, longBreakTime: 25),
            TimerConfiguration(name: "创意工作", focusTime: 30, shortBreakTime: 8, longBreakTime: 20),
            TimerConfiguration(name: "快速冲刺", focusTime: 15, shortBreakTime: 3, longBreakTime: 10),
            TimerConfiguration(name: "休闲模式", focusTime: 20, shortBreakTime: 10, longBreakTime: 20)
        ]
        
        // Initialize configurations from UserDefaults or use defaults
        let loadedConfigurations: [TimerConfiguration]
        if let data = UserDefaults.standard.data(forKey: "timerConfigurations"),
           let decoded = try? JSONDecoder().decode([TimerConfiguration].self, from: data) {
            loadedConfigurations = decoded
        } else {
            loadedConfigurations = defaultConfigurations
        }
        
        // Initialize selectedConfiguration from UserDefaults
        var initialSelectedConfig: TimerConfiguration = loadedConfigurations[0]
        if let data = UserDefaults.standard.data(forKey: "selectedTimerConfiguration"),
           let decodedConfig = try? JSONDecoder().decode(TimerConfiguration.self, from: data),
           let config = loadedConfigurations.first(where: { $0.id.uuidString == decodedConfig.id.uuidString }) {
            initialSelectedConfig = config
        }
        
        // Initialize all stored properties
        self.timerModel = timerModel
        self.configurations = loadedConfigurations
        self.selectedConfiguration = initialSelectedConfig
        
        // Load settings from UserDefaults
        self.autoStartBreak = UserDefaults.standard.bool(forKey: "autoStartBreak")
        self.autoStartWork = UserDefaults.standard.bool(forKey: "autoStartWork")
        self.longBreakReminder = UserDefaults.standard.object(forKey: "longBreakReminder") as? Bool ?? true
        self.statisticsTracking = UserDefaults.standard.object(forKey: "statisticsTracking") as? Bool ?? true
        self.startNotification = UserDefaults.standard.object(forKey: "startNotification") as? Bool ?? true
        self.completeNotification = UserDefaults.standard.object(forKey: "completeNotification") as? Bool ?? true
        self.vibrationFeedback = UserDefaults.standard.object(forKey: "vibrationFeedback") as? Bool ?? true
        self.soundReminder = UserDefaults.standard.object(forKey: "soundReminder") as? Bool ?? true
        
        // Now that all properties are initialized, we can apply the configuration
        applyConfiguration()
    }
    
    // Apply the current configuration to the timer model
    func applyConfiguration() {
        timerModel.updateTimeSettings(
            focusTime: selectedConfiguration.focusTime,
            shortBreakTime: selectedConfiguration.shortBreakTime,
            longBreakTime: selectedConfiguration.longBreakTime
        )
    }
    
    // Add a new custom configuration
    func addCustomConfiguration(name: String, focusTime: Int, shortBreakTime: Int, longBreakTime: Int) {
        let newConfiguration = TimerConfiguration(
            name: name,
            focusTime: focusTime,
            shortBreakTime: shortBreakTime,
            longBreakTime: longBreakTime,
            isCustom: true
        )
        configurations.append(newConfiguration)
        selectedConfiguration = newConfiguration // Auto-select the new configuration
    }
    
    // Add a quick preset configuration
    func addQuickPreset(name: String, focusTime: Int, shortBreak: Int, longBreak: Int) {
        // Check if a configuration with this name already exists
        if configurations.contains(where: { $0.name == name }) {
            // If exists, just select it
            if let existingConfig = configurations.first(where: { $0.name == name }) {
                selectedConfiguration = existingConfig
            }
        } else {
            // If doesn't exist, create it
            let newConfig = TimerConfiguration(
                name: name,
                focusTime: focusTime,
                shortBreakTime: shortBreak,
                longBreakTime: longBreak,
                isCustom: true
            )
            configurations.append(newConfig)
            selectedConfiguration = newConfig
        }
    }
    
    // Delete a configuration
    func deleteConfiguration(_ configuration: TimerConfiguration) {
        guard configuration.isCustom else { return } // Only allow deleting custom configurations
        
        if selectedConfiguration.id == configuration.id {
            // If the deleted configuration is currently selected, switch to default
            selectedConfiguration = configurations[0]
        }
        
        configurations.removeAll(where: { $0.id == configuration.id })
    }
    
    // MARK: - Real-time Configuration Updates
    
    // Update focus time and apply immediately
    func updateFocusTime(_ minutes: Int) {
        var updatedConfig = selectedConfiguration
        updatedConfig.focusTime = minutes
        
        // If it's a custom configuration, update it directly
        if selectedConfiguration.isCustom {
            if let index = configurations.firstIndex(where: { $0.id == selectedConfiguration.id }) {
                configurations[index] = updatedConfig
            }
            selectedConfiguration = updatedConfig
        } else {
            // If it's a preset, create a new custom configuration
            createCustomFromCurrent(updatedConfig: updatedConfig)
        }
    }
    
    // Update short break time and apply immediately
    func updateShortBreakTime(_ minutes: Int) {
        var updatedConfig = selectedConfiguration
        updatedConfig.shortBreakTime = minutes
        
        if selectedConfiguration.isCustom {
            if let index = configurations.firstIndex(where: { $0.id == selectedConfiguration.id }) {
                configurations[index] = updatedConfig
            }
            selectedConfiguration = updatedConfig
        } else {
            createCustomFromCurrent(updatedConfig: updatedConfig)
        }
    }
    
    // Update long break time and apply immediately
    func updateLongBreakTime(_ minutes: Int) {
        var updatedConfig = selectedConfiguration
        updatedConfig.longBreakTime = minutes
        
        if selectedConfiguration.isCustom {
            if let index = configurations.firstIndex(where: { $0.id == selectedConfiguration.id }) {
                configurations[index] = updatedConfig
            }
            selectedConfiguration = updatedConfig
        } else {
            createCustomFromCurrent(updatedConfig: updatedConfig)
        }
    }
    
    // Helper method to create a custom configuration from a preset
    private func createCustomFromCurrent(updatedConfig: TimerConfiguration) {
        var newCustomConfig = updatedConfig
        newCustomConfig.id = UUID()
        newCustomConfig.name = "自定义 - \(selectedConfiguration.name)"
        newCustomConfig.isCustom = true
        
        configurations.append(newCustomConfig)
        selectedConfiguration = newCustomConfig
    }
    
    // Get configuration by name (for quick access)
    func getConfigurationByName(_ name: String) -> TimerConfiguration? {
        return configurations.first { $0.name == name }
    }
    
    // Get all preset (non-custom) configurations
    func getPresetConfigurations() -> [TimerConfiguration] {
        return configurations.filter { !$0.isCustom }
    }
    
    // Get all custom configurations
    func getCustomConfigurations() -> [TimerConfiguration] {
        return configurations.filter { $0.isCustom }
    }
    
    // Duplicate a configuration
    func duplicateConfiguration(_ config: TimerConfiguration) {
        let duplicatedConfig = TimerConfiguration(
            name: "\(config.name) 副本",
            focusTime: config.focusTime,
            shortBreakTime: config.shortBreakTime,
            longBreakTime: config.longBreakTime,
            isCustom: true
        )
        configurations.append(duplicatedConfig)
    }
    
    // Check if configuration name already exists
    func configurationNameExists(_ name: String) -> Bool {
        return configurations.contains(where: { $0.name == name })
    }
    
    // Save current configuration as a new preset (force save, no conflict checking)
    func saveCurrentConfigurationAsPreset(name: String, forceOverwrite: Bool = false) {
        // Create a new preset configuration with the current settings
        let newPreset = TimerConfiguration(
            name: name,
            focusTime: selectedConfiguration.focusTime,
            shortBreakTime: selectedConfiguration.shortBreakTime,
            longBreakTime: selectedConfiguration.longBreakTime,
            isCustom: true
        )
        
        // Check if a configuration with this name already exists
        if let existingIndex = configurations.firstIndex(where: { $0.name == name }) {
            // If exists, update it
            configurations[existingIndex] = newPreset
            selectedConfiguration = newPreset
        } else {
            // If doesn't exist, add it
            configurations.append(newPreset)
            selectedConfiguration = newPreset
        }
    }
    
    // Reset to default configurations
    func resetToDefaults() {
        let defaultConfigurations = [
            TimerConfiguration(name: "经典番茄", focusTime: 25, shortBreakTime: 5, longBreakTime: 15),
            TimerConfiguration(name: "程序员专注", focusTime: 30, shortBreakTime: 5, longBreakTime: 20),
            TimerConfiguration(name: "深度工作", focusTime: 45, shortBreakTime: 10, longBreakTime: 25),
            TimerConfiguration(name: "学习模式", focusTime: 50, shortBreakTime: 10, longBreakTime: 25),
            TimerConfiguration(name: "创意工作", focusTime: 30, shortBreakTime: 8, longBreakTime: 20),
            TimerConfiguration(name: "快速冲刺", focusTime: 15, shortBreakTime: 3, longBreakTime: 10),
            TimerConfiguration(name: "休闲模式", focusTime: 20, shortBreakTime: 10, longBreakTime: 20)
        ]
        
        configurations = defaultConfigurations
        selectedConfiguration = defaultConfigurations[0]
    }
    
    // MARK: - Persistence
    
    private func saveConfigurations() {
        if let encoded = try? JSONEncoder().encode(configurations) {
            UserDefaults.standard.set(encoded, forKey: "timerConfigurations")
        }
    }
    
    private func saveSelectedConfiguration() {
        if let encoded = try? JSONEncoder().encode(selectedConfiguration) {
            UserDefaults.standard.set(encoded, forKey: "selectedTimerConfiguration")
        }
    }
} 