import SwiftUI

struct OnboardingView: View {
    @Binding var isShowingOnboarding: Bool
    @State private var currentPage = 0
    
    // Device detection for iPad
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    var body: some View {
        TabView(selection: $currentPage) {
            onboardingPage(
                title: "欢迎使用番茄专注",
                description: "使用番茄工作法提升您的专注力和工作效率",
                imageName: "timer",
                backgroundColor: Color.red.opacity(0.8)
            )
            .tag(0)
            
            onboardingPage(
                title: "专注与休息循环",
                description: "25分钟专注工作，5分钟短休息，每完成4个周期获得15分钟长休息",
                imageName: "clock",
                backgroundColor: Color.orange.opacity(0.8)
            )
            .tag(1)
            
            onboardingPage(
                title: "沉浸式背景音",
                description: "选择合适的背景音效，帮助您保持专注并隔离干扰",
                imageName: "speaker.wave.3",
                backgroundColor: Color.blue.opacity(0.8)
            )
            .tag(2)
            
            onboardingPage(
                title: "跟踪专注进度",
                description: "记录您的专注时间和完成的番茄钟数量，查看每日统计和趋势图",
                imageName: "chart.bar",
                backgroundColor: Color.green.opacity(0.8)
            )
            .tag(3)
            
            VStack(spacing: isIPad ? 40 : 30) {
                Text("准备好提升专注力了吗？")
                    .font(isIPad ? .largeTitle : .largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Image(systemName: "checkmark.circle")
                    .font(.system(size: isIPad ? 120 : 100))
                    .foregroundColor(.white)
                
                Text("立即开始专注和提高效率")
                    .font(isIPad ? .title : .title2)
                    .multilineTextAlignment(.center)
                
                Button(action: {
                    // 关闭引导页
                    withAnimation {
                        isShowingOnboarding = false
                    }
                    
                    // 保存状态，以后不再显示
                    UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                }) {
                    Text("开始使用")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(isIPad ? 20 : 15)
                        .padding(.horizontal, isIPad ? 40 : 30)
                        .background(Color.red)
                        .cornerRadius(isIPad ? 35 : 30)
                        .shadow(radius: 10)
                }
                .padding(.top, isIPad ? 40 : 30)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple.opacity(0.7), Color.pink.opacity(0.7)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .tag(4)
        }
        .tabViewStyle(PageTabViewStyle())
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
        .overlay(
            // 添加底部导航按钮
            HStack {
                // 如果不是第一页，显示"上一页"按钮
                if currentPage > 0 {
                    Button(action: {
                        withAnimation {
                            currentPage -= 1
                        }
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("上一页")
                        }
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(15)
                    }
                }
                
                Spacer()
                
                // 如果不是最后一页，显示"下一页"按钮
                if currentPage < 4 {
                    Button(action: {
                        withAnimation {
                            currentPage += 1
                        }
                    }) {
                        HStack {
                            Text("下一页")
                            Image(systemName: "chevron.right")
                        }
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(15)
                    }
                }
            }
            .padding(.horizontal, isIPad ? 30 : 20)
            .padding(.bottom, isIPad ? 30 : 20),
            alignment: .bottom
        )
    }
    
    private func onboardingPage(title: String, description: String, imageName: String, backgroundColor: Color) -> some View {
        VStack(spacing: isIPad ? 40 : 30) {
            Spacer()
            
            Text(title)
                .font(isIPad ? .largeTitle : .largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, isIPad ? 30 : 20)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)
            
            Image(systemName: imageName)
                .font(.system(size: isIPad ? 140 : 120))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 10)
            
            Text(description)
                .font(isIPad ? .title : .title2)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, isIPad ? 40 : 30)
                .shadow(color: .black.opacity(0.3), radius: 1, x: 0.5, y: 0.5)
            
            Spacer()
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            backgroundColor
                .ignoresSafeArea()
        )
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(isShowingOnboarding: .constant(true))
    }
} 