# 🍅 TomatoFocus - iOS Pomodoro Timer App

TomatoFocus is a simple, elegant, and immersive Pomodoro timer app for iOS that helps you stay focused and productive.

## Features

### MVP (v1.0)

- **Pomodoro Timer**
  - Standard 25/5/15 minute cycles
  - Customizable timer durations
  - Visual timer with animations
  - Notifications when timer completes

- **Background Sounds**
  - Multiple ambient sounds (rain, ocean, forest, cafe, white noise)
  - Volume controls
  - Mix with notification sounds

- **Statistics Tracking**
  - Daily and total pomodoro counts
  - Total focus time statistics
  - 7-day activity graph

- **Immersive UI**
  - Distraction-free full-screen mode
  - Color-coded timer states
  - Clean, minimalist design

## Requirements

- iOS 15.0+
- Xcode 13.0+
- Swift 5.5+

## Installation

1. Clone the repository
2. Open the project in Xcode
3. Add sound files to the project:
   - rain.flac (or .aiff, .wav)
   - ocean.mp3 (or .flac, .aiff, .wav)
   - forest.mp3 (or .flac, .aiff, .wav)
   - cafe.mp3 (or .flac, .aiff, .wav)
   - white_noise.mp3 (or .flac, .aiff, .wav)
   - notification.mp3 (or .flac, .aiff, .wav)
4. Build and run the app

## Getting Started

1. Choose your timer mode (Focus, Short Break, Long Break)
2. Select a background sound (optional)
3. Start the timer and focus on your task
4. The app will notify you when it's time to take a break or resume work
5. View your statistics to track your productivity

## Project Structure

- **Models**: Core data models and business logic
- **Views**: SwiftUI user interface components
- **Services**: Supporting services like notifications

## Future Enhancements

- Task management with categorization
- Cloud sync with iCloud
- Additional sound packs
- More detailed statistics and insights
- Widget support 