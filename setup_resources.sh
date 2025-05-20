#!/bin/bash

# 创建资源目录
echo "创建资源目录..."
mkdir -p TomatoFocus/Resources/Sounds

# 如果Sounds目录为空，创建默认空音频文件
if [ ! "$(ls -A TomatoFocus/Resources/Sounds)" ]; then
    echo "创建默认空音频文件..."
    
    # 检查是否已经有rain声音文件
    if [ ! -f "TomatoFocus/Resources/Sounds/rain.flac" ] && [ ! -f "TomatoFocus/Resources/Sounds/rain.aiff" ] && [ ! -f "TomatoFocus/Resources/Sounds/rain.wav" ]; then
        echo "警告: 未找到rain声音文件"
        echo "请确保将rain.flac、rain.aiff或rain.wav文件放置在TomatoFocus/Resources/Sounds/目录下"
    fi
    
    # 创建其他空音频文件
    touch TomatoFocus/Resources/Sounds/ocean.mp3
    touch TomatoFocus/Resources/Sounds/forest.mp3
    touch TomatoFocus/Resources/Sounds/cafe.mp3
    touch TomatoFocus/Resources/Sounds/white_noise.mp3
    touch TomatoFocus/Resources/Sounds/notification.mp3
    
    # 如果有ffmpeg，创建有效的空音频文件
    if command -v ffmpeg &> /dev/null; then
        echo "使用ffmpeg创建有效的空音频文件..."
        ffmpeg -f lavfi -i anullsrc=r=44100:cl=mono -t 1 -q:a 9 -acodec libmp3lame TomatoFocus/Resources/Sounds/ocean.mp3
        ffmpeg -f lavfi -i anullsrc=r=44100:cl=mono -t 1 -q:a 9 -acodec libmp3lame TomatoFocus/Resources/Sounds/forest.mp3
        ffmpeg -f lavfi -i anullsrc=r=44100:cl=mono -t 1 -q:a 9 -acodec libmp3lame TomatoFocus/Resources/Sounds/cafe.mp3
        ffmpeg -f lavfi -i anullsrc=r=44100:cl=mono -t 1 -q:a 9 -acodec libmp3lame TomatoFocus/Resources/Sounds/white_noise.mp3
        ffmpeg -f lavfi -i anullsrc=r=44100:cl=mono -t 1 -q:a 9 -acodec libmp3lame TomatoFocus/Resources/Sounds/notification.mp3
    else
        echo "警告: 未安装ffmpeg，创建的音频文件不可播放"
        echo "如需创建有效音频，请安装ffmpeg: brew install ffmpeg"
    fi
fi

echo "资源设置完成!" 