import SwiftUI

struct ConfigurationView: View {
    @StateObject var configModel: ConfigurationModel
    @State private var isAddingNewConfiguration = false
    @State private var selectedTabIndex = 0
    @State private var isSavingAsPreset = false
    @State private var presetNameToSave = ""
    @State private var isConfirmingOverwrite = false
    @State private var existingPresetName = ""
    @ObservedObject private var themeManager = ThemeManager.shared
    
    // Device detection for iPad
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    init(timerModel: TimerModel) {
        _configModel = StateObject(wrappedValue: ConfigurationModel(timerModel: timerModel))
    }
    
    var body: some View {
        ZStack {
            // Background using theme
            themeManager.currentTheme.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Header
                configHeader
                    .padding(.horizontal, isIPad ? 30 : 20)
                
                // Tabbed Content
                TabView(selection: $selectedTabIndex) {
                    // 主题设置页面
                    themeConfigView
                        .tag(0)
                    
                    // 预设配置页面  
                    timerPresetsView
                        .tag(1)
                        
                    // 自定义模式页面
                    customModesView
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
        }
        .sheet(isPresented: $isAddingNewConfiguration) {
            AddConfigurationView(
                isPresented: $isAddingNewConfiguration,
                configModel: configModel
            )
        }
        .alert("保存为预设", isPresented: $isSavingAsPreset) {
            TextField("预设名称", text: $presetNameToSave)
            Button("取消", role: .cancel) {
                presetNameToSave = ""
            }
            Button("保存") {
                saveCurrentAsPreset()
            }
            .disabled(presetNameToSave.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        } message: {
            Text("请输入一个描述性的预设名称，例如「专注学习」、「工作模式」等")
        }
        .alert("预设已存在", isPresented: $isConfirmingOverwrite) {
            Button("取消", role: .cancel) {
                existingPresetName = ""
            }
            Button("覆盖", role: .destructive) {
                performSave(name: existingPresetName)
                existingPresetName = ""
            }
            Button("重新输入") {
                existingPresetName = ""
                // 重新打开输入弹窗，保持之前的名称
                isSavingAsPreset = true
            }
        } message: {
            Text("预设「\(existingPresetName)」已存在。您希望覆盖现有预设，还是重新输入名称？")
        }
    }
    
    // MARK: - Header
    private var configHeader: some View {
        VStack(spacing: isIPad ? 20 : 15) {
            Text("设置")
                .font(isIPad ? .largeTitle : .largeTitle)
                .fontWeight(.bold)
                .foregroundColor(themeManager.currentTheme.primaryText)
                .padding(.top, isIPad ? 20 : 10)
            
            // Tab Selector
            HStack(spacing: 0) {
                ForEach(Array(["主题", "预设", "自定义"].enumerated()), id: \.offset) { index, title in
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedTabIndex = index
                        }
                    } label: {
                        VStack(spacing: isIPad ? 6 : 4) {
                            Text(title)
                                .font(.system(size: isIPad ? 16 : 14, weight: selectedTabIndex == index ? .bold : .medium))
                                .foregroundColor(selectedTabIndex == index ? 
                                    themeManager.currentTheme.primaryText : 
                                    themeManager.currentTheme.secondaryText)
                            
                            Rectangle()
                                .fill(themeManager.currentTheme.accent)
                                .frame(height: isIPad ? 3 : 2)
                                .opacity(selectedTabIndex == index ? 1 : 0)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.bottom, isIPad ? 15 : 10)
    }
    
    // MARK: - Theme Configuration View
    private var themeConfigView: some View {
        ScrollView {
            LazyVStack(spacing: isIPad ? 30 : 20) {
                // Current Theme Display
                currentThemeCard
                
                // Theme Grid
                themeGrid
                
                // 底部安全间距
                Spacer()
                    .frame(height: isIPad ? 100 : 80)
            }
            .padding(isIPad ? 30 : 20)
        }
        .scrollIndicators(.hidden)
    }
    
    private var currentThemeCard: some View {
        VStack(spacing: isIPad ? 15 : 12) {
            Text("当前主题")
                .font(isIPad ? .title2 : .headline)
                .foregroundColor(themeManager.currentTheme.primaryText)
            
            HStack(spacing: isIPad ? 20 : 15) {
                Text(themeManager.currentTheme.emoji)
                    .font(.system(size: isIPad ? 50 : 40))
                
                VStack(alignment: .leading, spacing: isIPad ? 6 : 4) {
                    Text(themeManager.currentTheme.name)
                        .font(isIPad ? .title : .title2)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.currentTheme.primaryText)
                    
                    // Show default sound for current theme
                    if let defaultSound = themeManager.getThemeDefaultSound() {
                        HStack(spacing: 6) {
                            Image(systemName: defaultSound.iconName)
                                .font(isIPad ? .callout : .caption)
                                .foregroundColor(themeManager.currentTheme.accent)
                            
                            Text("默认音效: \(defaultSound.displayName)")
                                .font(isIPad ? .callout : .caption)
                                .foregroundColor(themeManager.currentTheme.secondaryText)
                        }
                    }
                    
                    Text("轻触下方主题来切换")
                        .font(isIPad ? .callout : .caption)
                        .foregroundColor(themeManager.currentTheme.secondaryText)
                }
                
                Spacer()
            }
        }
        .padding(isIPad ? 25 : 20)
        .background(themeManager.currentTheme.cardBackground.opacity(0.2))
        .cornerRadius(isIPad ? 20 : 15)
    }
    
    private var themeGrid: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("选择主题")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.primaryText)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 15) {
                ForEach(ThemeManager.predefinedThemes) { theme in
                    ThemeCard(theme: theme, isSelected: theme.id == themeManager.currentTheme.id) {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            themeManager.setTheme(theme)
                        }
                    }
                }
            }
        }
    }
    

    

    
    // MARK: - Timer Presets View
    private var timerPresetsView: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Quick Access Presets
                quickPresetsSection
                
                // All Presets
                allPresetsSection
                
                // Current Configuration Details
                currentConfigSection
                
                // 底部安全间距
                Spacer()
                    .frame(height: isIPad ? 100 : 80)
            }
            .padding()
        }
        .scrollIndicators(.hidden)
    }
    
    private var quickPresetsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("快速预设")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.primaryText)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
                QuickPresetCard(title: "深度专注", subtitle: "45分钟", icon: "brain.head.profile") {
                    configModel.addQuickPreset(name: "深度专注", focusTime: 45, shortBreak: 10, longBreak: 25)
                }
                
                QuickPresetCard(title: "快速冲刺", subtitle: "15分钟", icon: "bolt.fill") {
                    configModel.addQuickPreset(name: "快速冲刺", focusTime: 15, shortBreak: 3, longBreak: 10)
                }
                
                QuickPresetCard(title: "学习模式", subtitle: "50分钟", icon: "book.fill") {
                    configModel.addQuickPreset(name: "学习模式", focusTime: 50, shortBreak: 10, longBreak: 25)
                }
                
                QuickPresetCard(title: "创意工作", subtitle: "30分钟", icon: "lightbulb.fill") {
                    configModel.addQuickPreset(name: "创意工作", focusTime: 30, shortBreak: 8, longBreak: 20)
                }
            }
        }
    }
    
    private var allPresetsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("所有预设")
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.primaryText)
                
                Spacer()
                
                Button("添加预设") {
                    isAddingNewConfiguration = true
                }
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(themeManager.currentTheme.cardBackground.opacity(0.2))
                .cornerRadius(15)
            }
            
            VStack(spacing: 10) {
                ForEach(configModel.configurations) { config in
                    PresetRow(
                        config: config, 
                        isSelected: config.id == configModel.selectedConfiguration.id,
                        onSelect: { configModel.selectedConfiguration = config },
                        onDelete: config.isCustom ? { configModel.deleteConfiguration(config) } : nil
                    )
                }
            }
        }
    }
    
    private var currentConfigSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("当前配置")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.primaryText)
            
            VStack(spacing: 10) {
                ConfigDetailRow(title: "专注时间", value: "\(configModel.selectedConfiguration.focusTime)分钟", icon: "timer")
                ConfigDetailRow(title: "短休息", value: "\(configModel.selectedConfiguration.shortBreakTime)分钟", icon: "pause.circle")
                ConfigDetailRow(title: "长休息", value: "\(configModel.selectedConfiguration.longBreakTime)分钟", icon: "moon")
            }
        }
    }
    
    // MARK: - Custom Modes View
    private var customModesView: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Custom Timer Builder
                customTimerBuilder
                
                // Advanced Settings
                advancedSettingsSection
                
                // Notification Settings
                notificationSettingsSection
                
                // Save as Preset Button (固定在底部)
                saveAsPresetButton
                
                // 底部安全间距
                Spacer()
                    .frame(height: isIPad ? 100 : 80)
            }
            .padding()
        }
        .scrollIndicators(.hidden)
    }
    
    private var customTimerBuilder: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("自定义计时器")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.primaryText)
            
            // Real-time Configuration Preview
            currentConfigPreviewCard
            
            VStack(spacing: 15) {
                CustomTimeSlider(
                    title: "专注时间",
                    value: Binding(
                        get: { configModel.selectedConfiguration.focusTime },
                        set: { configModel.updateFocusTime($0) }
                    ),
                    range: 5...120,
                    unit: "分钟"
                )
                
                CustomTimeSlider(
                    title: "短休息",
                    value: Binding(
                        get: { configModel.selectedConfiguration.shortBreakTime },
                        set: { configModel.updateShortBreakTime($0) }
                    ),
                    range: 1...30,
                    unit: "分钟"
                )
                
                CustomTimeSlider(
                    title: "长休息",
                    value: Binding(
                        get: { configModel.selectedConfiguration.longBreakTime },
                        set: { configModel.updateLongBreakTime($0) }
                    ),
                    range: 5...60,
                    unit: "分钟"
                )
            }
            .padding(20)
            .background(themeManager.currentTheme.cardBackground.opacity(0.2))
            .cornerRadius(15)
        }
    }
    
    // MARK: - Real-time Configuration Preview
    
    private var currentConfigPreviewCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("📱 当前配置")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeManager.currentTheme.primaryText)
                
                Spacer()
                
                Text(configModel.selectedConfiguration.name)
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.secondaryText)
            }
            
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("🎯")
                        .font(.title2)
                    Text("\(configModel.selectedConfiguration.focusTime)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(themeManager.currentTheme.accent)
                    Text("专注")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryText)
                }
                .frame(maxWidth: .infinity)
                
                VStack(spacing: 4) {
                    Text("☕️")
                        .font(.title2)
                    Text("\(configModel.selectedConfiguration.shortBreakTime)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(themeManager.currentTheme.accent)
                    Text("短休息")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryText)
                }
                .frame(maxWidth: .infinity)
                
                VStack(spacing: 4) {
                    Text("😴")
                        .font(.title2)
                    Text("\(configModel.selectedConfiguration.longBreakTime)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(themeManager.currentTheme.accent)
                    Text("长休息")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryText)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(15)
        .background(
            LinearGradient(
                colors: [themeManager.currentTheme.accent.opacity(0.1), themeManager.currentTheme.accent.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(themeManager.currentTheme.accent.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Save as Preset Button
    
    private var saveAsPresetButton: some View {
        Button {
            presetNameToSave = ""
            isSavingAsPreset = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 16, weight: .medium))
                
                Text("保存为预设")
                    .font(.system(size: 16, weight: .medium))
                
                Spacer()
                
                Text("\(configModel.selectedConfiguration.focusTime)/\(configModel.selectedConfiguration.shortBreakTime)/\(configModel.selectedConfiguration.longBreakTime)min")
                    .font(.caption)
                    .opacity(0.8)
            }
            .foregroundColor(themeManager.currentTheme.primaryText)
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            .background(
                LinearGradient(
                    colors: [themeManager.currentTheme.accent.opacity(0.15), themeManager.currentTheme.accent.opacity(0.05)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(themeManager.currentTheme.accent.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Actions
    
    private func saveCurrentAsPreset() {
        let trimmedName = presetNameToSave.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        // 检查名称是否已存在
        if configModel.configurationNameExists(trimmedName) {
            // 存在冲突，显示覆盖确认弹窗
            existingPresetName = trimmedName
            isConfirmingOverwrite = true
        } else {
            // 没有冲突，直接保存
            performSave(name: trimmedName)
        }
    }
    
    private func performSave(name: String) {
        configModel.saveCurrentConfigurationAsPreset(name: name)
        presetNameToSave = ""
        
        // 显示成功保存的反馈
        // 可以考虑添加一个简单的HUD提示或Toast
    }
    
    private var advancedSettingsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("高级设置")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.primaryText)
            
            VStack(spacing: 12) {
                ToggleRow(title: "自动开始休息", icon: "play.circle", isOn: $configModel.autoStartBreak)
                ToggleRow(title: "自动开始工作", icon: "arrow.clockwise", isOn: $configModel.autoStartWork)
                ToggleRow(title: "长休息提醒", icon: "bell", isOn: $configModel.longBreakReminder)
                ToggleRow(title: "统计追踪", icon: "chart.line.uptrend.xyaxis", isOn: $configModel.statisticsTracking)
            }
            .padding(20)
            .background(themeManager.currentTheme.cardBackground.opacity(0.2))
            .cornerRadius(15)
        }
    }
    
    private var notificationSettingsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("通知设置")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.primaryText)
            
            VStack(spacing: 12) {
                ToggleRow(title: "开始提醒", icon: "bell.badge", isOn: $configModel.startNotification)
                ToggleRow(title: "完成提醒", icon: "checkmark.circle", isOn: $configModel.completeNotification)
                ToggleRow(title: "振动反馈", icon: "iphone.radiowaves.left.and.right", isOn: $configModel.vibrationFeedback)
                ToggleRow(title: "声音提醒", icon: "speaker.wave.2", isOn: $configModel.soundReminder)
            }
            .padding(20)
            .background(themeManager.currentTheme.cardBackground.opacity(0.2))
            .cornerRadius(15)
        }
    }
}

// MARK: - Supporting Views

struct ThemeCard: View {
    let theme: AppTheme
    let isSelected: Bool
    let onTap: () -> Void
    
    // Get default sound for this theme
    private var defaultSound: AudioManager.BackgroundSound? {
        return AudioManager.BackgroundSound(rawValue: theme.defaultSoundId)
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                Text(theme.emoji)
                    .font(.system(size: 30))
                
                Text(theme.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.primaryText)
                
                // Display default sound
                if let sound = defaultSound {
                    HStack(spacing: 4) {
                        Image(systemName: sound.iconName)
                            .font(.caption2)
                        Text(sound.displayName)
                            .font(.caption2)
                    }
                    .foregroundColor(theme.primaryText.opacity(0.8))
                }
            }
            .frame(height: 100)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: theme.backgroundColors.map { theme.color(from: $0) },
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.white : Color.clear, lineWidth: 3)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
    }
}

struct QuickPresetCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let onTap: () -> Void
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(themeManager.currentTheme.accent)
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.currentTheme.primaryText)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.secondaryText)
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .background(themeManager.currentTheme.cardBackground.opacity(0.2))
            .cornerRadius(12)
        }
    }
}

struct PresetRow: View {
    let config: TimerConfiguration
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: (() -> Void)?
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack {
            Button(action: onSelect) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(config.name)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(themeManager.currentTheme.primaryText)
                        
                        Text("\(config.focusTime)min / \(config.shortBreakTime)min / \(config.longBreakTime)min")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.secondaryText)
                    }
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(themeManager.currentTheme.accent)
                    }
                }
            }
            
            if let onDelete = onDelete {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .padding(.leading, 10)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 15)
        .background(isSelected ? themeManager.currentTheme.cardBackground.opacity(0.3) : Color.clear)
        .cornerRadius(10)
    }
}

struct ConfigDetailRow: View {
    let title: String
    let value: String
    let icon: String
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(themeManager.currentTheme.accent)
                .frame(width: 24)
            
            Text(title)
                .foregroundColor(themeManager.currentTheme.primaryText)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(themeManager.currentTheme.primaryText)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 15)
        .background(themeManager.currentTheme.cardBackground.opacity(0.1))
        .cornerRadius(8)
    }
}

struct CustomTimeSlider: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let unit: String
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(title)
                    .foregroundColor(themeManager.currentTheme.primaryText)
                
                Spacer()
                
                Text("\(value) \(unit)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeManager.currentTheme.accent)
            }
            
            Slider(
                value: Binding(
                    get: { Double(value) },
                    set: { value = Int($0) }
                ),
                in: Double(range.lowerBound)...Double(range.upperBound),
                step: 1
            )
            .accentColor(themeManager.currentTheme.accent)
        }
    }
}

struct ToggleRow: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(themeManager.currentTheme.accent)
                .frame(width: 24)
            
            Text(title)
                .foregroundColor(themeManager.currentTheme.primaryText)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: themeManager.currentTheme.accent))
        }
    }
}

// MARK: - Mode Selection Components



// MARK: - Enhanced Add Configuration View

struct AddConfigurationView: View {
    @Binding var isPresented: Bool
    @ObservedObject var configModel: ConfigurationModel
    @ObservedObject private var themeManager = ThemeManager.shared
    
    @State private var name = ""
    @State private var focusTime = 25
    @State private var shortBreakTime = 5
    @State private var longBreakTime = 15
    @State private var selectedTemplate = 0
    
    private let templates = [
        ("自定义", 25, 5, 15),
        ("深度工作", 45, 10, 25),
        ("学习模式", 50, 10, 25),
        ("创意工作", 30, 8, 20),
        ("快速冲刺", 15, 3, 10)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Template Selection
                        VStack(alignment: .leading, spacing: 15) {
                            Text("选择模板")
                                .font(.headline)
                                .foregroundColor(themeManager.currentTheme.primaryText)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
                                ForEach(Array(templates.enumerated()), id: \.offset) { index, template in
                                    Button {
                                        selectedTemplate = index
                                        if index > 0 {
                                            name = template.0
                                            focusTime = template.1
                                            shortBreakTime = template.2
                                            longBreakTime = template.3
                                        }
                                    } label: {
                                        VStack(spacing: 6) {
                                            Text(template.0)
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(themeManager.currentTheme.primaryText)
                                            
                                            Text("\(template.1)min")
                                                .font(.caption)
                                                .foregroundColor(themeManager.currentTheme.secondaryText)
                                        }
                                        .frame(height: 60)
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            (selectedTemplate == index ? themeManager.currentTheme.accent : themeManager.currentTheme.cardBackground)
                                                .opacity(0.2)
                                        )
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(
                                                    selectedTemplate == index ? themeManager.currentTheme.accent : Color.clear,
                                                    lineWidth: 2
                                                )
                                        )
                                    }
                                }
                            }
                        }
                        
                        // Configuration Form
                        VStack(spacing: 20) {
                            // Name Input
                            VStack(alignment: .leading, spacing: 8) {
                                Text("配置名称")
                                    .font(.headline)
                                    .foregroundColor(themeManager.currentTheme.primaryText)
                                
                                TextField("输入名称", text: $name)
                                    .padding()
                                    .background(themeManager.currentTheme.cardBackground.opacity(0.2))
                                    .cornerRadius(10)
                                    .foregroundColor(themeManager.currentTheme.primaryText)
                            }
                            
                            // Time Settings
                            VStack(alignment: .leading, spacing: 15) {
                                Text("时间设置")
                                    .font(.headline)
                                    .foregroundColor(themeManager.currentTheme.primaryText)
                                
                                CustomTimeSlider(title: "专注时间", value: $focusTime, range: 5...120, unit: "分钟")
                                CustomTimeSlider(title: "短休息", value: $shortBreakTime, range: 1...30, unit: "分钟")
                                CustomTimeSlider(title: "长休息", value: $longBreakTime, range: 5...60, unit: "分钟")
                            }
                            .padding(20)
                            .background(themeManager.currentTheme.cardBackground.opacity(0.2))
                            .cornerRadius(15)
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .navigationTitle("新建配置")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("取消") { 
                    isPresented = false 
                }
                .foregroundColor(themeManager.currentTheme.primaryText),
                trailing: Button("保存") {
                    saveConfiguration()
                }
                .fontWeight(.bold)
                .foregroundColor(themeManager.currentTheme.accent)
                .disabled(name.isEmpty)
            )
        }
    }
    
    private func saveConfiguration() {
        configModel.addCustomConfiguration(
            name: name,
            focusTime: focusTime,
            shortBreakTime: shortBreakTime,
            longBreakTime: longBreakTime
        )
        isPresented = false
    }
}

struct ConfigurationView_Previews: PreviewProvider {
    static var previews: some View {
        ConfigurationView(timerModel: TimerModel())
    }
}