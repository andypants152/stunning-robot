# stunning-robot

A small Swift game experiment built with a SwiftUI shell around a UIKit game view. You fling a bouncing square around the screen, collect moving targets for points, avoid penalties, and chase a local high score.

## Current Features

- SwiftUI overlay for score, best score, and menu/restart text
- UIKit-powered game view using `CADisplayLink` for the main update loop
- Flick/drag controls that directly change the box velocity
- Multiple target types with different point values:
  - Green: +10
  - Blue: +25
  - Red: -15 penalty
  - Purple: +50
  - Yellow: +5
- Target labels showing point values
- Local high score persistence with `@AppStorage` / `UserDefaults`
- Collision sound effects generated in code with `AVAudioPlayer`
- Particle bursts when targets are hit
- Corner-bounce bonus worth +100 with corner confetti
- Scene phase handling so the game loop pauses when the app is inactive

## Requirements

- Xcode 26 or newer
- iOS 17.0 or newer

## Open and Run

1. Open `stunning-robot.xcodeproj` in Xcode.
2. Select the `stunning-robot` scheme.
3. Choose an iPhone or iPad simulator, or a connected iOS device.
4. Press Run.

## How to Play

1. Tap to start.
2. Drag or flick the white square to change its direction and speed.
3. Hit colored targets to gain or lose points.
4. Bounce into a corner to trigger a +100 bonus and confetti.
5. Try to beat the saved best score.

## Project Structure

```text
stunning-robot/
├── ContentView.swift                 # SwiftUI overlay and state bridge
├── BouncingBoxRepresentable.swift    # SwiftUI wrapper for the UIKit game view
├── BouncingBoxView.swift             # Main UIKit game view and loop
├── PhysicsEngine.swift               # Movement, wall bounces, particles, confetti
├── TargetSystem.swift                # Target types, colors, scores, speeds
├── TargetManager.swift               # Target spawning, collision handling, respawning
├── CollisionSoundPlayer.swift        # Procedural collision sounds
├── Assets.xcassets
└── stunning_robotApp.swift
```

## Notes

This project is intentionally simple and code-first. There are no bundled sound files right now; collision sounds are generated at runtime. The core gameplay is split into small Swift files so the SwiftUI wrapper, UIKit view, physics, targets, and audio can evolve independently.
