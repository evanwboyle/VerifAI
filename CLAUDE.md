# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

VerifAI is a SwiftUI-based iOS/macOS application for AI-powered verification and task management. The app integrates with OpenAI's API to enable intelligent features.

## Architecture

### Project Structure

- **VerifAI/VerifAI/**: Main application source code
  - **VerifAIApp.swift**: App entry point, sets up SwiftData container with the `Item` model
  - **ContentView.swift**: Primary navigation hub using `NavigationSplitView`, manages item list display and CRUD operations
  - **Views/**: Screen implementations (HomeView, CameraView, NewTaskView, RestrictView, SettingsView)
  - **Item.swift**: SwiftData model representing a timestamped item entity
  - **Secrets.swift**: Loads OpenAI API key from `Secrets.plist` at runtime

### Technology Stack

- **SwiftUI**: UI framework for iOS/macOS
- **SwiftData**: On-device data persistence (replaces CoreData)
- **OpenAI API**: Integrated for AI capabilities (key managed via Secrets.plist)

### Key Design Patterns

- **SwiftData for Persistence**: The app uses `ModelContainer` configured in `VerifAIApp.swift` to manage the `Item` model. All views access data through `@Query` and `@Environment(\.modelContext)`.
- **View-Based Navigation**: `NavigationSplitView` in ContentView handles primary/detail navigation for iOS and macOS.
- **Secrets Management**: OpenAI API key is stored in a `Secrets.plist` file (git-ignored) and loaded via the `Secrets` enum.

## Build and Run

### Build the App

```bash
xcodebuild build -scheme VerifAI
```

### Run on Simulator

```bash
xcodebuild run -scheme VerifAI -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Open in Xcode

```bash
open VerifAI.xcodeproj
```

Then build and run using Xcode's Run button or `Cmd+R`.

## Configuration

### Secrets Management

The app requires an OpenAI API key configured in `Secrets.plist`:

1. Create `VerifAI/Secrets.plist` with the following structure:
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <dict>
       <key>OPENAI_KEY</key>
       <string>your-api-key-here</string>
   </dict>
   </plist>
   ```

2. Add to Xcode project (not required for build to work, but needed at runtime)

3. Ensure `Secrets.plist` is in `.gitignore` to prevent committing credentials

## Development Notes

- **SwiftData Models**: Add new models to the `Schema` in `VerifAIApp.swift` and update `ModelContainer` configuration
- **View Creation**: Placeholder views (CameraView, NewTaskView, RestrictView, SettingsView) are scaffolded and ready for implementation
- **Platform Support**: The app supports both iOS (via conditional compilation `#if os(iOS)`) and macOS
