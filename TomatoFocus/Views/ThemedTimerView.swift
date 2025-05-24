import SwiftUI

struct ThemedTimerView: View {
    @ObservedObject var timerModel: TimerModel
    @State private var isImmersiveMode = false
    @State private var pulseAmount: CGFloat = 1.0
    @State private var buttonScale: CGFloat = 1.0
    @State private var previousTimeRemaining: Int = 0
    @ObservedObject private var audioManager = AudioManager.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    
    // Constructor with default for backward compatibility and previews
    init(timerModel: TimerModel = TimerModel()) {
        self.timerModel = timerModel
        self._previousTimeRemaining = State(initialValue: timerModel.timeRemaining)
    }
    
    // Device detection
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient using theme with transition animation
                themeManager.currentTheme.backgroundGradient
                    .ignoresSafeArea()
                    .transition(.opacity)
                
                if isImmersiveMode {
                    immersiveView(geometry: geometry)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    regularView(geometry: geometry)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .onDisappear {
            // Make sure we pause the timer when leaving the view
            if timerModel.isActive && !timerModel.isPaused {
                timerModel.pause()
            }
        }
        .onChange(of: timerModel.timeRemaining) { oldValue, newValue in
            // Trigger number change animation
            withAnimation(.easeInOut(duration: 0.3)) {
                previousTimeRemaining = oldValue
            }
        }
        .onAppear {
            startPulseAnimation()
        }
    }
    
    // MARK: - Views
    
    private func regularView(geometry: GeometryProxy) -> some View {
        let screenWidth = geometry.size.width
        let screenHeight = geometry.size.height
        let isLandscape = screenWidth > screenHeight
        
        return Group {
            if isIPad && isLandscape {
                // iPad横屏布局
                HStack(spacing: 30) {
                    // 左侧：计时器和快捷操作
                    VStack(spacing: 25) {
                        timerCircleView(size: min(screenHeight * 0.6, 350))
                        
                        quickActionsView
                            .padding(.horizontal, 15)
                    }
                    .frame(maxWidth: screenWidth * 0.5)
                    
                    // 右侧：控制面板（可滑动）
                    ScrollView {
                        LazyVStack(spacing: 25) {
                            headerView
                            
                            controlButtonsView
                            
                            soundControlView
                                .padding(.top, 15)
                            
                            // 新增内容区域（为未来扩展做准备）
                            additionalContentView
                            
                            // 底部安全间距
                            Spacer()
                                .frame(height: isIPad ? 100 : 80)
                        }
                        .padding(.top, 25)
                    }
                    .frame(maxWidth: screenWidth * 0.4)
                    .scrollIndicators(.hidden)
                }
                .padding(isIPad ? 30 : 20)
            } else {
                // iPhone和iPad竖屏布局（可滑动）
                ScrollView {
                    LazyVStack(spacing: isIPad ? 30 : 25) {
                        // Header with theme selector
                        headerView
                            .padding(.top, isIPad ? 15 : 10)
                        
                        // Timer Display
                        timerCircleView(size: isIPad ? min(screenWidth * 0.6, 400) : 280)
                            .padding(.bottom, isIPad ? 20 : 15)
                        
                        // Quick Actions (New Feature)
                        quickActionsView
                            .padding(.horizontal, isIPad ? 30 : 20)
                        
                        // Control Buttons
                        controlButtonsView
                        
                        // Sound controls
                        soundControlView
                            .padding(.top, isIPad ? 20 : 15)
                            .padding(.horizontal, isIPad ? 30 : 0)
                        
                        // 新增内容区域（为未来扩展做准备）
                        additionalContentView
                        
                        // 底部安全间距 - 确保内容不被Tab Bar遮挡
                        Spacer()
                            .frame(height: max(120, bottomSafeAreaPadding(geometry: geometry)))
                    }
                    .padding(isIPad ? 30 : 20)
                }
                .scrollIndicators(.hidden)
            }
        }
    }
    
    private func immersiveView(geometry: GeometryProxy) -> some View {
        let screenWidth = geometry.size.width
        let screenHeight = geometry.size.height
        
        return VStack {
            // Immersive Mode: just the timer and a button to exit
            ZStack {
                timerCircleView(size: isIPad ? min(min(screenWidth, screenHeight) * 0.7, 500) : 320)
                    .scaleEffect(isIPad ? 1.0 : 1.3)
                    .padding(.bottom, isIPad ? 80 : 50)
                
                VStack {
                    Spacer()
                    
                    HStack(spacing: isIPad ? 40 : 20) {
                        // Control buttons
                        if timerModel.isActive {
                            if timerModel.isPaused {
                                immersiveControlButton(iconName: "play.fill") {
                                    triggerButtonAnimation()
                                    timerModel.resume()
                                }
                            } else {
                                immersiveControlButton(iconName: "pause.fill") {
                                    triggerButtonAnimation()
                                    timerModel.pause()
                                }
                            }
                        } else {
                            immersiveControlButton(iconName: "play.fill") {
                                triggerButtonAnimation()
                                timerModel.start()
                            }
                        }
                        
                        // Exit immersive mode button
                        immersiveControlButton(iconName: "arrow.down.right.and.arrow.up.left") {
                            triggerButtonAnimation()
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                isImmersiveMode = false
                            }
                        }
                    }
                    .padding(.bottom, isIPad ? 60 : 40)
                }
            }
        }
    }
    
    private func immersiveControlButton(iconName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: iconName)
                .font(isIPad ? .largeTitle : .title2)
                .foregroundColor(themeManager.currentTheme.primaryText)
                .padding(isIPad ? 20 : 15)
                .background(themeManager.currentTheme.buttonBackground.opacity(0.3))
                .clipShape(Circle())
                .scaleEffect(buttonScale)
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: isIPad ? 8 : 6) {
                HStack {
                    Text(timerModel.mode.emoji)
                        .font(isIPad ? .title2 : .title3)
                        .scaleEffect(timerModel.isActive ? 1.2 : 1.0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: timerModel.isActive)
                    
                    Text(timerModel.mode.title)
                        .font(isIPad ? .title : .title2)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.currentTheme.primaryText)
                }
                
                // Status indicator
                HStack(spacing: isIPad ? 4 : 3) {
                    // Progress indicator
                    if timerModel.isActive {
                        Image(systemName: "timer")
                            .font(isIPad ? .callout : .caption)
                            .foregroundColor(themeManager.getTimerColor(for: timerModel.mode))
                            .opacity(timerModel.isPaused ? 0.5 : 1.0)
                            .animation(.easeInOut(duration: 0.5), value: timerModel.isPaused)
                        
                        Text(timerModel.isPaused ? "已暂停" : "进行中")
                            .font(isIPad ? .callout : .caption)
                            .foregroundColor(themeManager.currentTheme.secondaryText)
                    } else {
                        Text("准备就绪")
                            .font(isIPad ? .callout : .caption)
                            .foregroundColor(themeManager.currentTheme.secondaryText)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .leading)))
            }
            
            Spacer()
            
            // 沉浸模式按钮
            Button {
                triggerButtonAnimation()
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    isImmersiveMode = true
                }
            } label: {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(isIPad ? .title3 : .title3)
                    .foregroundColor(themeManager.currentTheme.primaryText)
                    .padding(isIPad ? 10 : 8)
                    .background(themeManager.currentTheme.buttonBackground.opacity(0.2))
                    .clipShape(Circle())
                    .scaleEffect(buttonScale)
            }
        }
        .padding(.top, isIPad ? 15 : 10)
    }
    
    // MARK: - Simplified Quick Actions View
    private var quickActionsView: some View {
        // This view will be empty for now, or we can add other relevant quick actions later.
        // For now, let's return an EmptyView or a minimal placeholder.
        EmptyView()
    }
    
    private func timerCircleView(size: CGFloat = 280) -> some View {
        ZStack {
            // Outer circle with subtle glow effect
            Circle()
                .stroke(lineWidth: isIPad ? 20 : 15)
                .opacity(0.3)
                .foregroundColor(themeManager.currentTheme.primaryText)
                .shadow(color: themeManager.currentTheme.primaryText.opacity(0.1), radius: isIPad ? 15 : 10)
            
            // Progress circle with theme color and enhanced animations
            Circle()
                .trim(from: 0.0, to: timerModel.progress)
                .stroke(style: StrokeStyle(lineWidth: isIPad ? 20 : 15, lineCap: .round, lineJoin: .round))
                .foregroundColor(themeManager.getTimerColor(for: timerModel.mode))
                .rotationEffect(Angle(degrees: 270.0))
                .scaleEffect(pulseAmount)
                .shadow(color: themeManager.getTimerColor(for: timerModel.mode).opacity(0.4), radius: pulseAmount * (isIPad ? 8 : 5))
                .animation(.easeInOut(duration: 0.5), value: timerModel.progress)
                .onChange(of: timerModel.isActive) { _, isActive in
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        pulseAmount = isActive && !timerModel.isPaused ? 1.05 : 1.0
                    }
                }
                .onChange(of: timerModel.isPaused) { _, isPaused in
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        pulseAmount = timerModel.isActive && !isPaused ? 1.05 : 1.0
                    }
                }
            
            // Time display with number transition animation
            VStack(spacing: isIPad ? 8 : 6) {
                // Animated time text with improved iPad sizing
                HStack(spacing: isIPad ? 3 : 2) {
                    let timeComponents = timerModel.timeRemainingFormatted.components(separatedBy: ":")
                    let fontSize: CGFloat = isIPad ? min(size * 0.18, 72) : size * 0.25
                    
                    if timeComponents.count == 2 {
                        // Minutes
                        AnimatedNumberText(text: timeComponents[0])
                            .font(.system(size: fontSize, weight: .bold, design: .rounded))
                            .foregroundColor(themeManager.currentTheme.primaryText)
                        
                        Text(":")
                            .font(.system(size: fontSize, weight: .bold, design: .rounded))
                            .foregroundColor(themeManager.currentTheme.primaryText)
                        
                        // Seconds
                        AnimatedNumberText(text: timeComponents[1])
                            .font(.system(size: fontSize, weight: .bold, design: .rounded))
                            .foregroundColor(themeManager.currentTheme.primaryText)
                    } else {
                        // Fallback to original display
                        Text(timerModel.timeRemainingFormatted)
                            .font(.system(size: fontSize, weight: .bold, design: .rounded))
                            .foregroundColor(themeManager.currentTheme.primaryText)
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: timerModel.timeRemaining)
                
                // Mode description with proper sizing
                Text(timerModel.mode.description)
                    .font(isIPad ? .title3 : .headline)
                    .foregroundColor(themeManager.currentTheme.secondaryText)
                    .opacity(timerModel.isActive ? 0.8 : 1.0)
                    .animation(.easeInOut(duration: 0.5), value: timerModel.isActive)
            }
        }
        .frame(width: size, height: size)
        .rotationEffect(.degrees(timerModel.isActive ? 0 : -5))
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: timerModel.isActive)
    }
    
    private var controlButtonsView: some View {
        HStack(spacing: isIPad ? 25 : 18) {
            if timerModel.isActive {
                if timerModel.isPaused {
                    animatedControlButton(title: "继续", iconName: "play.fill") {
                        triggerButtonAnimation()
                        timerModel.resume()
                    }
                    .transition(.scale.combined(with: .opacity))
                } else {
                    animatedControlButton(title: "暂停", iconName: "pause.fill") {
                        triggerButtonAnimation()
                        timerModel.pause()
                    }
                    .transition(.scale.combined(with: .opacity))
                }
                
                animatedControlButton(title: "重置", iconName: "arrow.counterclockwise") {
                    triggerButtonAnimation()
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        timerModel.reset()
                    }
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                animatedControlButton(title: "开始", iconName: "play.fill") {
                    triggerButtonAnimation()
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        timerModel.start()
                    }
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: timerModel.isActive)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: timerModel.isPaused)
    }
    
    private func animatedControlButton(title: String, iconName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: iconName)
                .font(isIPad ? .title2 : .title3)
                .foregroundColor(themeManager.currentTheme.primaryText)
                .padding(isIPad ? 16 : 12)
                .background(themeManager.currentTheme.buttonBackground.opacity(0.2))
                .clipShape(Circle())
                .scaleEffect(buttonScale)
                .shadow(color: themeManager.currentTheme.buttonBackground.opacity(0.3), radius: isIPad ? 4 : 3)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var soundControlView: some View {
        VStack(spacing: isIPad ? 15 : 12) {
            // 声音选择
            HStack {
                Image(systemName: audioManager.selectedSound.iconName)
                    .foregroundColor(themeManager.currentTheme.primaryText)
                    .font(isIPad ? .title3 : .body)
                
                Menu {
                    ForEach(AudioManager.BackgroundSound.allCases) { sound in
                        Button(sound.displayName) {
                            audioManager.selectSound(sound)
                        }
                    }
                } label: {
                    Text(audioManager.selectedSound.displayName)
                        .foregroundColor(themeManager.currentTheme.primaryText)
                        .font(isIPad ? .callout : .callout)
                    
                    Image(systemName: "chevron.down")
                        .foregroundColor(themeManager.currentTheme.secondaryText)
                        .font(isIPad ? .callout : .caption)
                }
                
                Spacer()
                
                // 播放/暂停按钮
                Button {
                    if audioManager.isPlaying {
                        audioManager.stopSound()
                    } else {
                        audioManager.playSound()
                    }
                } label: {
                    Image(systemName: audioManager.isPlaying ? "pause.circle" : "play.circle")
                        .font(isIPad ? .title : .title2)
                        .foregroundColor(themeManager.currentTheme.primaryText)
                }
                .frame(width: isIPad ? 44 : 36, height: isIPad ? 44 : 36)
                .contentShape(Rectangle())
            }
            
            // 音量控制
            HStack(spacing: isIPad ? 12 : 10) {
                // 音量图标
                Image(systemName: audioManager.volume < 0.1 ? "speaker.slash" : 
                    (audioManager.volume < 0.5 ? "speaker.wave.1" : "speaker.wave.3"))
                    .foregroundColor(themeManager.currentTheme.primaryText)
                    .frame(width: isIPad ? 26 : 20)
                    .font(isIPad ? .title3 : .body)
                
                // 音量滑块
                Slider(value: Binding(
                    get: { audioManager.volume },
                    set: { audioManager.setVolume($0) }
                ), in: 0...1, step: 0.05)
                .accentColor(themeManager.currentTheme.accent)
                
                // 音量数值显示
                Text("\(Int(audioManager.volume * 100))%")
                    .foregroundColor(themeManager.currentTheme.primaryText)
                    .frame(width: isIPad ? 40 : 32, alignment: .trailing)
                    .font(isIPad ? .callout : .caption)
            }
        }
        .padding(isIPad ? 18 : 14)
        .background(themeManager.currentTheme.cardBackground.opacity(0.2))
        .cornerRadius(isIPad ? 16 : 12)
    }
    
    // MARK: - Animation Functions
    
    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulseAmount = timerModel.isActive && !timerModel.isPaused ? 1.1 : 1.0
        }
    }
    
    private func triggerButtonAnimation() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            buttonScale = 0.95
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                buttonScale = 1.0
            }
        }
    }
    
    // MARK: - Additional Content View
    
    /// 新增内容区域，为未来功能扩展做准备
    private var additionalContentView: some View {
        VStack(spacing: isIPad ? 20 : 15) {
            // 这里可以添加更多功能，比如：
            // - 今日完成的番茄数统计
            // - 专注时长统计
            // - 快捷设置
            // - 激励语句
            // 目前暂时为空，为未来扩展预留位置
            EmptyView()
        }
    }
    
    // MARK: - Adaptive Bottom Padding
    
    /// 计算自适应底部间距，确保内容不被Tab Bar遮挡
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
}

// MARK: - Extensions

extension TimerModel.TimerMode {
    var title: String {
        switch self {
        case .focus: return "专注时间"
        case .shortBreak: return "短休息"
        case .longBreak: return "长休息"
        }
    }
    
    var description: String {
        switch self {
        case .focus: return "保持专注"
        case .shortBreak: return "休息一下"
        case .longBreak: return "享受长休息"
        }
    }
    
    var emoji: String {
        switch self {
        case .focus: return "🍅"
        case .shortBreak: return "☕"
        case .longBreak: return "🛋️"
        }
    }
    
    // Legacy support - these are now handled by ThemeManager
    var color: Color {
        return ThemeManager.shared.getTimerColor(for: self)
    }
    
    var gradientColors: [Color] {
        return ThemeManager.shared.getGradientColors(for: self)
    }
}

// MARK: - Animated Number Text Component

struct AnimatedNumberText: View {
    let text: String
    @State private var animatedText: String = ""
    
    var body: some View {
        Text(animatedText)
            .onAppear {
                animatedText = text
            }
            .onChange(of: text) { oldValue, newValue in
                withAnimation(.easeInOut(duration: 0.3)) {
                    animatedText = newValue
                }
            }
    }
}

struct ThemedTimerView_Previews: PreviewProvider {
    static var previews: some View {
        ThemedTimerView()
    }
} 