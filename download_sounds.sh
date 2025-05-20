#!/bin/bash

# 创建目录
mkdir -p TomatoFocus/Resources/Sounds

# 下载免费音效
echo "正在下载音效文件..."

# 雨声 - 已经使用flac格式，不再下载mp3
# 使用rain.flac替代rain.mp3

# 海浪声
curl -L "https://cdn.pixabay.com/download/audio/2021/08/09/audio_c8ea0cfcd7.mp3" -o TomatoFocus/Resources/Sounds/ocean.mp3

# 森林声
curl -L "https://cdn.pixabay.com/download/audio/2022/05/09/audio_2ca66107ad.mp3" -o TomatoFocus/Resources/Sounds/forest.mp3

# 咖啡厅声
curl -L "https://cdn.pixabay.com/download/audio/2021/11/22/audio_cb2878a681.mp3" -o TomatoFocus/Resources/Sounds/cafe.mp3

# 白噪音
curl -L "https://cdn.pixabay.com/download/audio/2022/03/10/audio_270f49b96e.mp3" -o TomatoFocus/Resources/Sounds/white_noise.mp3

# 通知声
curl -L "https://cdn.pixabay.com/download/audio/2021/08/04/audio_0625c6a379.mp3" -o TomatoFocus/Resources/Sounds/notification.mp3

# 裁剪音频文件到20秒，循环播放会更顺畅
if command -v ffmpeg &> /dev/null; then
    echo "正在裁剪音频文件..."
    for file in TomatoFocus/Resources/Sounds/{ocean,forest,cafe,white_noise}.mp3; do
        ffmpeg -y -i "$file" -t 20 -c copy "${file}.tmp" && mv "${file}.tmp" "$file"
    done
    
    # 确保通知音效简短
    ffmpeg -y -i TomatoFocus/Resources/Sounds/notification.mp3 -t 1 -c copy TomatoFocus/Resources/Sounds/notification.mp3.tmp && mv TomatoFocus/Resources/Sounds/notification.mp3.tmp TomatoFocus/Resources/Sounds/notification.mp3
else
    echo "警告: 未安装ffmpeg，无法裁剪音频文件。"
    echo "如需裁剪，请安装ffmpeg: brew install ffmpeg"
fi

echo "音效文件已下载到 TomatoFocus/Resources/Sounds/"
echo "音效来源: Pixabay.com (免费音效，CC0许可)" 