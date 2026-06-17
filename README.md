# Lakshya

Lakshya is an iPhone alarm and timer app built around a simple idea: alerts should not disappear with one sleepy tap. Each timer or alarm ends with a short stop mission, such as a checklist or a quick math prompt, before it can be dismissed.

## Features

- Focus timer with preset durations
- Reusable alarms with custom titles
- Two stop modes: checklist and math challenge
- Persistent local state for alarms and active timer
- Apple-like SwiftUI interface optimized for iPhone

## Technologies Used

- Swift
- SwiftUI
- Observation framework with `@Observable`
- UserDefaults for local persistence
- XcodeGen-style `Project.json` project configuration
- Bitrig iPhone app project structure

## Project Structure

- `App/` contains the SwiftUI app, models, and views
- `Project.json` defines the app target and build settings
- `App/Assets.xcassets/` contains the accent color and app icon assets

## Main Files

- `App/LakshyaApp.swift`
- `App/Presentation/Views/ContentView.swift`
- `App/Presentation/ViewModels/AlarmDashboardViewModel.swift`
- `App/Presentation/Views/ActiveAlertView.swift`
- `App/Data/UserDefaultsAlarmRepository.swift`

## Running the App
<img width="1206" height="2622" alt="Screen1 0" src="https://github.com/user-attachments/assets/54d758b0-417e-4e5b-b776-b65979187bd8" />
<img width="1206" height="2622" alt="Screen1 2" src="https://github.com/user-attachments/assets/9ff10f0a-f203-400d-ab63-c26bcf8e038f" />

Open the project in Bitrig or generate the Xcode project from `Project.json`, then run the iPhone target.
