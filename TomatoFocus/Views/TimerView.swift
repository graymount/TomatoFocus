import SwiftUI

struct TimerView: View {
    @StateObject private var timerModel = TimerModel()
    @State private var isImmersiveMode = false
    @ObservedObject private var audioManager = AudioManager.shared
    
    var body: some View {
        ZStack {
            // Background gradient
            backgroundGradient
                .ignoresSafeArea()
            
            if isImmersiveMode {
                immersiveView
            } else {
                regularView
            }
        }
        .onDisappear {
            // Make sure we pause the timer when leaving the view
            if timerModel.isActive && !timerModel.isPaused {
                timerModel.pause()
            }
        }
    }
    
    // MARK: - Views
    
    private var regularView: some View {
        VStack(spacing: 30) {
            // Header
            headerView
            
            Spacer()
            
            // Timer Display
            timerCircleView
                .padding(.bottom, 20)
            
            // Control Buttons
            controlButtonsView
            
            // Sound controls
            soundControlView
                .padding(.top, 20)
            
            Spacer()
        }
        .padding()
    }
    
    private var immersiveView: some View {
        VStack {
            // Immersive Mode: just the timer and a button to exit
            ZStack {
                timerCircleView
                    .scaleEffect(1.3)
                    .padding(.bottom, 50)
                
                VStack {
                    Spacer()
                    
                    HStack {
                        // Control buttons
                        if timerModel.isActive {
                            if timerModel.isPaused {
                                controlButton(title: "Resume", iconName: "play.fill") {
                                    timerModel.resume()
                                }
                            } else {
                                controlButton(title: "Pause", iconName: "pause.fill") {
                                    timerModel.pause()
                                }
                            }
                        } else {
                            controlButton(title: "Start", iconName: "play.fill") {
                                timerModel.start()
                            }
                        }
                        
                        // Exit immersive mode button
                        Button {
                            withAnimation {
                                isImmersiveMode = false
                            }
                        } label: {
                            Image(systemName: "arrow.down.right.and.arrow.up.left")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.3))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            Text(timerModel.mode.title)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Spacer()
            
            Button {
                withAnimation {
                    isImmersiveMode = true
                }
            } label: {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.2))
                    .clipShape(Circle())
            }
        }
        .padding(.top)
    }
    
    private var timerCircleView: some View {
        ZStack {
            // Outer circle
            Circle()
                .stroke(lineWidth: 15)
                .opacity(0.3)
                .foregroundColor(Color.white)
            
            // Progress circle
            Circle()
                .trim(from: 0.0, to: timerModel.progress)
                .stroke(style: StrokeStyle(lineWidth: 15, lineCap: .round, lineJoin: .round))
                .foregroundColor(timerModel.mode.color)
                .rotationEffect(Angle(degrees: 270.0))
                .animation(.linear, value: timerModel.progress)
            
            // Time display
            VStack(spacing: 8) {
                Text(timerModel.timeRemainingFormatted)
                    .font(.system(size: 70, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(timerModel.mode.description)
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .frame(width: 280, height: 280)
    }
    
    private var controlButtonsView: some View {
        HStack(spacing: 20) {
            if timerModel.isActive {
                if timerModel.isPaused {
                    controlButton(title: "继续", iconName: "play.fill") {
                        timerModel.resume()
                    }
                } else {
                    controlButton(title: "暂停", iconName: "pause.fill") {
                        timerModel.pause()
                    }
                }
                
                controlButton(title: "重置", iconName: "arrow.counterclockwise") {
                    timerModel.reset()
                }
            } else {
                controlButton(title: "开始", iconName: "play.fill") {
                    timerModel.start()
                }
                
                // Mode selection buttons
                Menu {
                    Button("专注 (25分钟)") { timerModel.setTime(minutes: 25); timerModel.mode = .focus }
                    Button("短休息 (5分钟)") { timerModel.setTime(minutes: 5); timerModel.mode = .shortBreak }
                    Button("长休息 (15分钟)") { timerModel.setTime(minutes: 15); timerModel.mode = .longBreak }
                    
                    Section("自定义") {
                        ForEach([10, 15, 20, 30, 45, 60], id: \.self) { minutes in
                            Button("\(minutes)分钟") {
                                timerModel.setCustomTime(minutes: minutes)
                            }
                        }
                    }
                } label: {
                    Image(systemName: "clock")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.2))
                        .clipShape(Circle())
                }
            }
        }
    }
    
    private var soundControlView: some View {
        VStack(spacing: 15) {
            // 声音选择
            HStack {
                Image(systemName: audioManager.selectedSound.iconName)
                    .foregroundColor(.white)
                
                Menu {
                    ForEach(AudioManager.BackgroundSound.allCases) { sound in
                        Button(sound.displayName) {
                            audioManager.selectSound(sound)
                        }
                    }
                } label: {
                    Text(audioManager.selectedSound.displayName)
                        .foregroundColor(.white)
                    
                    Image(systemName: "chevron.down")
                        .foregroundColor(.white.opacity(0.7))
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
                        .font(.title2)
                        .foregroundColor(.white)
                }
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
            }
            
            // 音量控制
            HStack(spacing: 12) {
                // 音量图标
                Image(systemName: audioManager.volume < 0.1 ? "speaker.slash" : 
                    (audioManager.volume < 0.5 ? "speaker.wave.1" : "speaker.wave.3"))
                    .foregroundColor(.white)
                    .frame(width: 24)
                
                // 音量滑块
                Slider(value: Binding(
                    get: { audioManager.volume },
                    set: { audioManager.setVolume($0) }
                ), in: 0...1, step: 0.05)
                .accentColor(.white)
                
                // 音量数值显示
                Text("\(Int(audioManager.volume * 100))%")
                    .foregroundColor(.white)
                    .frame(width: 40, alignment: .trailing)
                    .font(.caption)
            }
        }
        .padding()
        .background(Color.black.opacity(0.2))
        .cornerRadius(15)
    }
    
    private func controlButton(title: String, iconName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(.white)
                .padding()
                .background(Color.black.opacity(0.2))
                .clipShape(Circle())
        }
    }
    
    // MARK: - Background and styling
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: timerModel.mode.gradientColors),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
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
    
    var color: Color {
        switch self {
        case .focus: return Color.red
        case .shortBreak: return Color.green
        case .longBreak: return Color.blue
        }
    }
    
    var gradientColors: [Color] {
        switch self {
        case .focus:
            return [Color(red: 0.9, green: 0.3, blue: 0.3), Color(red: 0.8, green: 0.1, blue: 0.1)]
        case .shortBreak:
            return [Color(red: 0.3, green: 0.8, blue: 0.4), Color(red: 0.1, green: 0.6, blue: 0.2)]
        case .longBreak:
            return [Color(red: 0.3, green: 0.5, blue: 0.9), Color(red: 0.1, green: 0.3, blue: 0.8)]
        }
    }
}

struct TimerView_Previews: PreviewProvider {
    static var previews: some View {
        TimerView()
    }
} 