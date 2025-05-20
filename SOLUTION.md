# 解决方案: "Multiple commands produce Info.plist" 错误

## 问题原因

这个错误是因为Xcode试图以两种不同的方式生成Info.plist文件:

1. 项目设置中的`GENERATE_INFOPLIST_FILE = YES`告诉Xcode自动生成一个Info.plist
2. 同时项目根目录中已经存在一个手动创建的Info.plist文件

这导致了构建系统冲突，因为同一个输出路径有两个不同的来源。

## 解决方法

我们采用以下步骤解决了问题:

1. 将原始的Info.plist文件复制为CustomInfo.plist
   ```
   cp TomatoFocus/Info.plist TomatoFocus/CustomInfo.plist
   ```

2. 删除原始的Info.plist文件以避免冲突
   ```
   rm TomatoFocus/Info.plist
   ```

3. 修改项目设置，使用CustomInfo.plist而不是自动生成的文件
   ```
   sed -i '' 's/TomatoFocus\/Info.plist/TomatoFocus\/CustomInfo.plist/g' TomatoFocus.xcodeproj/project.pbxproj
   ```

4. 确保项目设置中`GENERATE_INFOPLIST_FILE = NO`

5. 清理构建文件夹
   ```
   rm -rf ~/Library/Developer/Xcode/DerivedData/*
   ```

## 注意事项

- 确保CustomInfo.plist包含应用所需的所有设置，特别是后台音频支持
- 如果您修改了Info.plist的内容，请确保更新CustomInfo.plist
- 这种解决方案适用于Xcode 14及更高版本

## 背景音频功能

为了确保番茄钟的背景音频功能正常工作:

1. Info.plist中需要包含以下设置:
   ```xml
   <key>UIBackgroundModes</key>
   <array>
       <string>audio</string>
   </array>
   ```

2. 在AppDelegate中正确设置音频会话:
   ```swift
   try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
   try AVAudioSession.sharedInstance().setActive(true)
   ``` 