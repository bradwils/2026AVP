# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A SwiftUI/RealityKit app for Apple Vision Pro (visionOS), built for a hackathon. Goal: guide a user through CPR practice. Planned features:

- Hand tracking on a 3D dummy (or fallback: user practices on a pillow/surface/air if no dummy model is available)
- A instructional video overlay that can be played/paused
- A stopwatch
- A metronome/beat audio at the correct CPR compression rate (100–120 BPM)

The codebase is currently the unmodified Xcode "visionOS App" template — `ContentView.swift` still has the placeholder `Model3D`/"Hello, world!" content. None of the CPR-specific features exist yet.

## Build, run, test

This is an Xcode project (`AVPGroupApp/AVPGroupApp.xcodeproj`) targeting visionOS only (`SDKROOT = xros`, `XROS_DEPLOYMENT_TARGET = 26.5`). There is no Swift Package CLI entry point — use Xcode or `xcodebuild`.

- Use the **xcodebuildmcp-cli** skill for building, running, and viewing logs on the visionOS simulator — it wraps `xcodebuild`/simctl correctly for this kind of project and should be preferred over raw shell invocations.
- Scheme: `AVPGroupApp`. Project path: `AVPGroupApp/AVPGroupApp.xcodeproj`.
- Tests use the Swift Testing framework (`import Testing`, `@Test`, `#expect`), not XCTest. Test target: `AVPGroupAppTests`.
- There is a local Swift package dependency, `AVPGroupApp/Packages/RealityKitContent`, which holds RealityKit scenes/materials authored in Reality Composer Pro (`Package.realitycomposerpro`). Edit `.usda`/RC Pro content through Reality Composer Pro, not by hand.

## Architecture

- **`AVPGroupAppApp.swift`** — app entry point. Declares two scenes: a 2D `WindowGroup` (`ContentView`) and a full-immersion `ImmersiveSpace` (`ImmersiveView`), both sharing one `AppModel` injected via `.environment(appModel)`. Immersion style is `.full`.
- **`AppModel.swift`** — single `@Observable` source of truth for app-wide state, currently just `immersiveSpaceState` (`.closed` / `.inTransition` / `.open`). Any new cross-view state (CPR session state, stopwatch state, BPM, current video) belongs here rather than in individual views.
- **`ContentView.swift`** — the 2D window UI (non-immersive). This is where 2D controls (play/pause, stopwatch display, start/stop session) should live.
- **`ImmersiveView.swift`** — the full-immersion `RealityView`, where the 3D dummy entity, hand-tracking visuals, and spatial audio for the beat should be added. Loads entities from the `RealityKitContent` package bundle (`realityKitContentBundle`) by name (e.g. `Entity(named: "Immersive", in: realityKitContentBundle)`).
- **`ToggleImmersiveSpaceButton.swift`** — encapsulates the open/dismiss state machine for the immersive space via `openImmersiveSpace`/`dismissImmersiveSpace` environment actions, driven by `AppModel.immersiveSpaceState`. Note the comments explaining why state transitions are *not* set directly in the button action but instead in `ImmersiveView.onAppear`/`onDisappear` — there can be multiple paths in/out of the immersive space, so this is the single source of truth for open/closed state.
- **`Packages/RealityKitContent`** — local Swift package for RealityKit/Reality Composer Pro authored content (3D scenes, materials), consumed by both `ContentView` and `ImmersiveView` via `import RealityKitContent`.

## Working in this codebase

- This targets **visionOS 26**, a recent/beta-adjacent platform. Before implementing hand tracking, RealityKit anchoring, spatial audio, or other visionOS-specific APIs, check current Apple documentation (ARKit `HandTrackingProvider`, RealityKit, AVFoundation for audio) rather than relying on older iOS/macOS patterns — APIs in this space change across visionOS versions.
- Hand tracking requires an `ImmersiveSpace` with full immersion (already set up) and ARKit's `HandTrackingProvider`/`WorldTrackingProvider`, which need entitlements (`NSHandsTrackingUsageDescription` in `Info.plist`) and only run on-device, not in the simulator.
- The `swiftui-pro` skill should be used when reading, writing, or reviewing SwiftUI code in this repo.
