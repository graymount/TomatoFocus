import Foundation
import AVFoundation
import AudioToolbox

class AudioManager: ObservableObject {
    static let shared = AudioManager()
    
    @Published var isPlaying = false
    @Published var volume: Float = 0.5
    @Published var selectedSound: BackgroundSound = .rain
    
    private var audioPlayer: AVAudioPlayer?
    private var audioEngine: AVAudioEngine?
    private var audioPlayerNode: AVAudioPlayerNode?
    private var audioUnitSampler: AVAudioUnitSampler?
    private var audioMixer: AVAudioMixerNode?
    
    enum BackgroundSound: String, CaseIterable, Identifiable {
        case rain = "rain"
        case ocean = "ocean"
        case forest = "forest"
        case cafe = "cafe"
        case whiteNoise = "white_noise"
        
        var id: String { self.rawValue }
        
        var displayName: String {
            switch self {
            case .rain: return "Rain"
            case .ocean: return "Ocean Waves"
            case .forest: return "Forest"
            case .cafe: return "Cafe Ambience"
            case .whiteNoise: return "White Noise"
            }
        }
        
        var iconName: String {
            switch self {
            case .rain: return "cloud.rain"
            case .ocean: return "water.waves"
            case .forest: return "leaf"
            case .cafe: return "cup.and.saucer"
            case .whiteNoise: return "speaker.wave.3"
            }
        }
        
        var frequency: Double {
            switch self {
            case .rain: return 500
            case .ocean: return 300
            case .forest: return 800
            case .cafe: return 400
            case .whiteNoise: return 1000
            }
        }
        
        // 获取可能的文件扩展名
        var possibleExtensions: [String] {
            switch self {
            case .rain:
                return ["flac", "aiff", "wav"] // 雨声优先检查 flac 格式，然后是 aiff 和 wav
            default:
                return ["mp3", "flac", "aiff", "wav"] // 其他声音优先检查 mp3 格式，然后是 flac、aiff 和 wav
            }
        }
    }
    
    private init() {
        print("AudioManager 初始化")
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            print("设置音频会话...")
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            print("音频会话设置成功")
        } catch {
            print("🔴 音频会话设置失败: \(error)")
        }
    }
    
    func playSound() {
        print("准备播放声音: \(selectedSound.rawValue)")
        
        // 重置音频会话，确保音频可以播放
        do {
            try AVAudioSession.sharedInstance().setActive(false)
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            print("重置音频会话成功")
        } catch {
            print("重置音频会话失败: \(error.localizedDescription)")
        }
        
        // 完全停止之前的播放
        stopSound()
        
        // 使用简单的普通同步代码流程，避免复杂的异步调度导致的问题
        var foundValidFile = false
        
        // 尝试加载不同格式的音频文件
        for fileExtension in selectedSound.possibleExtensions {
            print("正在尝试加载 \(selectedSound.rawValue).\(fileExtension)")
            
            // 预先检查文件是否存在
            let soundFilename = selectedSound.rawValue
            guard let soundURL = Bundle.main.url(forResource: soundFilename, withExtension: fileExtension) else {
                print("找不到文件: \(selectedSound.rawValue).\(fileExtension)")
                continue
            }
            
            print("找到文件: \(soundURL.path)")
            
            do {
                // 检查文件是否可以访问
                if !FileManager.default.fileExists(atPath: soundURL.path) {
                    print("🔴 文件存在于Bundle中但无法访问: \(soundURL.path)")
                    continue
                }
                
                let attributes = try FileManager.default.attributesOfItem(atPath: soundURL.path)
                let fileSize = attributes[.size] as? Int ?? 0
                print("文件大小: \(fileSize) 字节")
                
                // 如果文件太小，可能不是有效的音频文件
                if fileSize < 1024 {
                    print("文件太小，可能不是有效的音频文件")
                    continue
                }
                
                print("🟢 正在播放 \(fileExtension) 格式的 \(selectedSound.rawValue) 声音")
                
                // 创建新的播放器
                let player = try AVAudioPlayer(contentsOf: soundURL)
                
                // 设置播放参数
                player.numberOfLoops = -1 // 无限循环
                player.volume = self.volume
                
                // 预加载音频文件以避免播放时的延迟
                if !player.prepareToPlay() {
                    print("🔴 预加载失败")
                    continue
                }
                
                // 尝试播放
                let playSuccess = player.play()
                
                if playSuccess {
                    print("🟢 播放成功开始")
                    self.audioPlayer = player
                    self.isPlaying = true
                    foundValidFile = true
                    return // 成功找到并播放了文件，直接返回
                } else {
                    print("🔴 play() 方法返回 false，播放失败")
                }
            } catch {
                print("🔴 \(fileExtension) 文件加载失败: \(error.localizedDescription)")
                debugPrint(error)
            }
        }
        
        // 如果没有找到有效的音频文件，使用生成的声音
        if !foundValidFile {
            handleNoValidSoundFile()
        }
    }
    
    private func handleNoValidSoundFile() {
        print("没有找到有效的声音文件，使用生成的声音")
        playSimpleGeneratedSound(frequency: selectedSound.frequency)
    }
    
    // 使用更简单的同步方法生成声音，避免多线程问题
    private func playSimpleGeneratedSound(frequency: Double) {
        print("准备生成声音，频率: \(frequency)Hz")
        stopSound()
        
        // 创建新的音频引擎
        self.audioEngine = AVAudioEngine()
        guard let audioEngine = self.audioEngine else {
            print("🔴 无法创建音频引擎")
            return
        }
        
        // 创建新的节点
        self.audioPlayerNode = AVAudioPlayerNode()
        self.audioMixer = audioEngine.mainMixerNode
        
        guard let playerNode = self.audioPlayerNode,
              let mixer = self.audioMixer else {
            print("🔴 无法创建音频节点")
            return
        }
        
        print("添加音频节点到引擎...")
        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode, to: mixer, format: mixer.outputFormat(forBus: 0))
        
        // 获取正确的输出格式
        let outputFormat = mixer.outputFormat(forBus: 0)
        print("输出格式: 采样率=\(outputFormat.sampleRate)Hz, 通道数=\(outputFormat.channelCount)")
        
        let duration = 2.0
        let frameCount = AVAudioFrameCount(outputFormat.sampleRate * duration)
        
        // 使用与输出格式匹配的通道数创建缓冲区
        guard let buffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: frameCount) else {
            print("🔴 无法创建音频缓冲区")
            return
        }
        
        buffer.frameLength = frameCount
        
        // 根据声音类型生成对应的音频数据
        if self.selectedSound == .whiteNoise {
            print("生成白噪音...")
            self.generateWhiteNoise(buffer: buffer, volume: self.volume)
        } else {
            print("生成正弦波音频...")
            self.generateTone(buffer: buffer, frequency: frequency, volume: self.volume)
        }
        
        do {
            print("启动音频引擎...")
            try audioEngine.start()
            
            print("调度缓冲区...")
            playerNode.scheduleBuffer(buffer, at: nil, options: .loops)
            playerNode.play()
            
            self.isPlaying = true
            print("🟢 生成的音频开始播放")
        } catch {
            print("🔴 音频引擎启动失败: \(error.localizedDescription)")
            debugPrint(error)
        }
    }
    
    private func generateTone(buffer: AVAudioPCMBuffer, frequency: Double, volume: Float) {
        // 获取所有通道的数据
        let channelCount = Int(buffer.format.channelCount)
        
        for channel in 0..<channelCount {
            guard let channelData = buffer.floatChannelData?[channel] else { continue }
            
            let sampleRate = Float(buffer.format.sampleRate)
            let theta = 2.0 * Float.pi * Float(frequency) / sampleRate
            
            for frame in 0..<Int(buffer.frameLength) {
                let sampleVal = sin(theta * Float(frame)) * volume
                channelData[frame] = sampleVal
            }
        }
    }
    
    private func generateWhiteNoise(buffer: AVAudioPCMBuffer, volume: Float) {
        // 获取所有通道的数据
        let channelCount = Int(buffer.format.channelCount)
        
        for channel in 0..<channelCount {
            guard let channelData = buffer.floatChannelData?[channel] else { continue }
            
            for frame in 0..<Int(buffer.frameLength) {
                let randomValue = Float.random(in: -1.0...1.0) * volume
                channelData[frame] = randomValue
            }
        }
    }
    
    func stopSound() {
        print("停止所有声音")
        
        // 停止AVAudioPlayer
        if let player = audioPlayer {
            player.stop()
            print("停止了AVAudioPlayer")
            audioPlayer = nil
        }
        
        // 停止音频播放节点
        if let node = audioPlayerNode {
            if node.isPlaying {
                node.stop()
                print("停止了AudioPlayerNode")
            }
            audioEngine?.detach(node)
        }
        
        // 停止音频引擎
        if let engine = audioEngine {
            if engine.isRunning {
                engine.stop()
                print("停止了AudioEngine")
            }
            engine.reset()
        }
        
        // 完全释放引擎资源
        audioPlayerNode = nil
        audioEngine = nil
        audioMixer = nil
        
        isPlaying = false
        
        // 短暂延迟确保所有资源被释放
        Thread.sleep(forTimeInterval: 0.05)
    }
    
    func setVolume(_ volume: Float) {
        print("设置音量: \(volume)")
        self.volume = volume
        audioPlayer?.volume = volume
        
        if audioEngine != nil && audioEngine!.isRunning && audioPlayerNode != nil {
            let currentFrequency = selectedSound.frequency
            playSimpleGeneratedSound(frequency: currentFrequency)
        }
    }
    
    func selectSound(_ sound: BackgroundSound) {
        print("选择声音: \(sound.rawValue)")
        
        // 尝试重置音频会话以防出现问题
        do {
            try AVAudioSession.sharedInstance().setActive(false)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("重置音频会话失败: \(error.localizedDescription)")
        }
        
        // 停止当前声音
        stopSound()
        
        // 等待一下确保资源被完全释放
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            
            // 更新选择的声音
            self.selectedSound = sound
            
            // 播放新选择的声音
            self.playSound()
        }
    }
    
    func playNotificationSound() {
        print("准备播放通知声音")
        // 尝试播放通知声音文件
        for fileExtension in ["mp3", "flac", "aiff", "wav"] {
            if let soundURL = Bundle.main.url(forResource: "notification", withExtension: fileExtension) {
                print("找到通知声音文件: \(soundURL.path)")
                
                do {
                    let attributes = try FileManager.default.attributesOfItem(atPath: soundURL.path)
                    let fileSize = attributes[.size] as? Int ?? 0
                    print("通知文件大小: \(fileSize) 字节")
                    
                    if fileSize > 10240 {
                        print("🟢 播放通知声音文件")
                        let notificationPlayer = try AVAudioPlayer(contentsOf: soundURL)
                        notificationPlayer.volume = 1.0
                        
                        if notificationPlayer.play() {
                            print("🟢 通知声音播放成功")
                        } else {
                            print("🔴 通知声音播放失败")
                        }
                        
                        return
                    }
                } catch {
                    print("🔴 通知声音文件加载失败: \(error)")
                }
            } else {
                print("未找到 notification.\(fileExtension) 文件")
            }
        }
        
        // 如果没有找到有效的通知声音文件，使用系统声音
        print("使用系统声音作为通知")
        AudioServicesPlaySystemSound(1007) // 系统通知声音
    }
    
    // 调试方法：检查资源包中的所有文件
    func debugListAllFiles() {
        print("--- 列出应用资源包中的所有文件 ---")
        guard let resourcePath = Bundle.main.resourcePath else {
            print("无法获取资源路径")
            return
        }
        
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(atPath: resourcePath)
            for file in fileURLs {
                print("文件: \(file)")
            }
        } catch {
            print("列出文件失败: \(error)")
        }
        
        // 特别检查声音文件夹
        let soundsPath = resourcePath + "/Sounds"
        print("检查声音文件夹: \(soundsPath)")
        
        if FileManager.default.fileExists(atPath: soundsPath) {
            do {
                let soundFiles = try FileManager.default.contentsOfDirectory(atPath: soundsPath)
                for file in soundFiles {
                    let filePath = soundsPath + "/" + file
                    let attributes = try FileManager.default.attributesOfItem(atPath: filePath)
                    let fileSize = attributes[.size] as? Int ?? 0
                    print("  - 声音文件: \(file) (大小: \(fileSize) 字节)")
                }
            } catch {
                print("列出声音文件失败: \(error)")
            }
        } else {
            print("声音文件夹不存在!")
        }
    }
    
    // MARK: - 辅助诊断方法
    
    func checkAudioFileAvailability() {
        print("\n===== 音频文件诊断 =====")
        
        // 检查资源目录
        guard let resourcePath = Bundle.main.resourcePath else {
            print("无法获取资源路径")
            return
        }
        
        let soundsDir = resourcePath + "/Sounds"
        let fileManager = FileManager.default
        
        // 列出资源目录
        print("检查资源目录: \(resourcePath)")
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: resourcePath)
            print("资源根目录内容: \(contents)")
            
            // 检查Sounds目录
            if contents.contains("Sounds") {
                print("Sounds目录存在")
                let soundFiles = try fileManager.contentsOfDirectory(atPath: soundsDir)
                print("Sounds目录包含: \(soundFiles)")
            } else {
                // 在根资源目录中查找音频文件
                let audioFiles = contents.filter { 
                    let ext = $0.components(separatedBy: ".").last?.lowercased() ?? ""
                    return ["mp3", "flac", "aiff", "wav"].contains(ext) 
                }
                print("在根目录找到的音频文件: \(audioFiles)")
            }
        } catch {
            print("列出资源目录失败: \(error.localizedDescription)")
        }
        
        // 检查每种声音类型
        for soundType in BackgroundSound.allCases {
            checkSoundFileStatus(for: soundType)
        }
        
        // 检查通知声音
        print("\n检查通知声音:")
        for ext in ["mp3", "flac", "aiff", "wav"] {
            let hasFile = Bundle.main.path(forResource: "notification", ofType: ext) != nil
            print("notification.\(ext): \(hasFile ? "存在" : "不存在")")
        }
        
        // 检查音频会话状态
        let audioSession = AVAudioSession.sharedInstance()
        print("\n音频会话状态:")
        print("分类: \(audioSession.category.rawValue)")
        print("活跃: \(audioSession.isOtherAudioPlaying ? "否(有其他音频在播放)" : "是")")
        print("输出音量: \(audioSession.outputVolume)")
        
        print("===== 诊断结束 =====\n")
    }
    
    private func checkSoundFileStatus(for sound: BackgroundSound) {
        print("\n检查声音文件: \(sound.rawValue)")
        
        for ext in sound.possibleExtensions {
            guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: ext) else {
                print("\(sound.rawValue).\(ext): 不存在")
                continue
            }
            
            print("\(sound.rawValue).\(ext): 存在 (路径: \(url.path))")
            
            do {
                if FileManager.default.fileExists(atPath: url.path) {
                    let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
                    let size = attrs[.size] as? Int ?? 0
                    let isReadable = FileManager.default.isReadableFile(atPath: url.path)
                    print("  - 大小: \(size) 字节")
                    print("  - 可读: \(isReadable ? "是" : "否")")
                    
                    // 尝试初始化播放器验证文件有效性
                    do {
                        _ = try AVAudioPlayer(contentsOf: url)
                        print("  - 格式: 有效")
                    } catch {
                        print("  - 格式: 无效 (\(error.localizedDescription))")
                    }
                } else {
                    print("  - 文件存在URL但无法在路径中找到")
                }
            } catch {
                print("  - 检查文件属性失败: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - 错误恢复方法
    
    private func recoverFromAudioError() {
        print("尝试恢复音频会话...")
        
        // 重置音频会话
        do {
            try AVAudioSession.sharedInstance().setActive(false)
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
            print("音频会话已重置")
        } catch {
            print("重置音频会话失败: \(error.localizedDescription)")
        }
        
        // 确保所有音频资源已释放
        stopSound()
        
        // 检查文件可用性
        checkAudioFileAvailability()
    }
} 