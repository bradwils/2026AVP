# PulseLab XR Current Code Workflow and Merge Notes

This document describes the current app structure, runtime flow, and merge constraints for the multi-window CPR training experience.

## Current Goal

The app is moving toward a Vision Pro workspace model:

- Main welcome window introduces PulseLab XR.
- Guided CPR video opens as one floating window.
- Guided CPR steps open as another floating window.
- Stopwatch opens as a compact support window.
- Immersive space opens for CPR practice.

This is intended to feel like multiple floating panels around the user, similar to the Vision Pro multi-window experience.

## Branch State

Current working branch:

```text
brian-cpr-flow
```

Recent local focus:

- Simplified the welcome flow.
- Removed old lesson selection and reserved welcome files.
- Kept `Get Started` visible.
- Made `Get Started` open a multi-window practice workspace on device.
- Kept simulator fallback behavior because `openWindow(id:)` is not reliable in the simulator.

## Main App Scenes

Defined in:

```text
AVPGroupApp/AVPGroupApp/AVPGroupAppApp.swift
```

Current scenes:

```swift
WindowGroup {
    ContentView()
        .environment(appModel)
}

WindowGroup(id: "stopwatch") {
    MinuteTimerView()
}

WindowGroup(id: "cpr-video") {
    CPRVideoView()
}

WindowGroup(id: "cpr-steps") {
    CPRStepsView()
}

ImmersiveSpace(id: appModel.immersiveSpaceID) {
    ImmersiveView()
        .environment(appModel)
}
```

Important window identifiers:

```text
stopwatch
cpr-video
cpr-steps
ImmersiveSpace
```

Do not rename these IDs casually. `ContentView` opens these windows by string ID.

## Welcome Screen Flow

Defined in:

```text
AVPGroupApp/AVPGroupApp/ContentView.swift
```

`ContentView` currently renders only:

```swift
WelcomeView()
```

There is no active lesson-selection flow in this branch.

### Guided Steps Card

The `Guided Steps` card behaves differently depending on runtime target:

Device:

```swift
openWindow(id: "cpr-video")
openWindow(id: "cpr-steps")
```

Simulator:

```swift
showGuide = true
```

The simulator path opens `CPRSideBySideView` as a sheet because multiple windows are unreliable in the visionOS simulator.

### Get Started Button

`Get Started` calls:

```swift
openTrainingWorkspace()
```

Device behavior:

```swift
openWindow(id: "cpr-video")
openWindow(id: "cpr-steps")
openWindow(id: "stopwatch")
openImmersiveSpace(id: appModel.immersiveSpaceID)
```

Simulator behavior:

```swift
showGuide = true
```

This means the simulator still shows the side-by-side guide sheet instead of trying to open several windows.

## CPR Guide UI

Defined in:

```text
AVPGroupApp/AVPGroupApp/CPRGuideView.swift
```

Main views:

- `CPRVideoView`: plays bundled `CPR_Guide.mp4`.
- `CPRStepsView`: scrollable CPR step script.
- `CPRSideBySideView`: sheet fallback that shows video and steps side by side.

`CPRSideBySideView` is currently a fallback/demo view, not the intended final Vision Pro device workflow.

## Stopwatch UI

Defined in:

```text
AVPGroupApp/AVPGroupApp/Stopwatch/MinuteTimerView.swift
AVPGroupApp/AVPGroupApp/Stopwatch/MinuteTimerModel.swift
AVPGroupApp/AVPGroupApp/Stopwatch/BeepPlayer.swift
```

The stopwatch is opened as a separate floating window with:

```swift
openWindow(id: "stopwatch")
```

It is intended to sit beside the CPR practice area as a compact support panel.

## Immersive Practice Area

Defined in:

```text
AVPGroupApp/AVPGroupApp/ImmersiveView.swift
```

The current branch does not take ownership of the immersive mannequin/practice implementation.

`ContentView` only opens the immersive space through:

```swift
openImmersiveSpace(id: appModel.immersiveSpaceID)
```

Merge rule:

- If another teammate updates `ImmersiveView.swift`, prefer their implementation.
- Keep `appModel.immersiveSpaceState` transitions intact unless replacing the whole immersive flow deliberately.

## Shared App State

Defined in:

```text
AVPGroupApp/AVPGroupApp/AppModel.swift
```

Important current state:

```swift
let immersiveSpaceID = "ImmersiveSpace"
var immersiveSpaceState = ImmersiveSpaceState.closed
var lessonPhase: LessonPhase = .welcome
var compressionCount: Int = 0
var compressionBPM: Double = 0
var handPlacementCorrect: Bool = false
```

Note:

- `lessonPhase` exists but is not currently driving `ContentView`.
- CPR feedback state exists but this branch does not add a CPR feedback/practice dashboard.
- If another teammate implements feedback, they should reuse `AppModel.recordCompression()` where possible.

## Removed or Inactive Flow

The following files are deleted in this branch:

```text
AVPGroupApp/AVPGroupApp/LessonSelectionView.swift
AVPGroupApp/AVPGroupApp/WelcomeView.swift
```

Reason:

- The app currently uses the `WelcomeView` embedded inside `ContentView.swift`.
- The lesson selection flow was considered unnecessary for the current demo path.

Merge rule:

- If another branch depends on `LessonSelectionView.swift`, decide whether the final app should restore lesson selection or keep the direct multi-window workspace.
- Avoid having two competing `WelcomeView` definitions.

## Simulator vs Device Constraint

Important constraint:

```text
openWindow(id:) can be unreliable in the visionOS simulator.
```

Current pattern:

```swift
#if targetEnvironment(simulator)
showGuide = true
#else
openWindow(id: "...")
#endif
```

Do not remove this fallback unless the team confirms simulator multi-window behavior is stable enough for demo.

## Merge Conflict Guidance

When merging with teammates' work:

1. Preserve `WindowGroup` IDs unless there is a coordinated rename.
2. Keep simulator fallbacks for demo reliability.
3. Do not add CPR feedback dashboard code in this branch unless the owner of that feature asks for integration.
4. If another branch adds hand tracking or mannequin interaction, keep this branch's `Get Started` workspace opener and merge their immersive logic into `ImmersiveView`.
5. If another branch adds a proper practice panel, add a new `WindowGroup(id:)` for that panel and open it from `openTrainingWorkspace()`.
6. Prefer multi-window UI for device and sheet fallback for simulator.

## Suggested Final Device Workflow

On Vision Pro device:

```text
User opens app
-> Welcome window appears
-> User taps Get Started
-> CPR video window opens
-> CPR steps window opens
-> Stopwatch window opens
-> Immersive CPR practice space opens
-> User arranges floating windows around the practice area
```

On simulator:

```text
User opens app
-> Welcome window appears
-> User taps Get Started or Guided Steps
-> Side-by-side guide sheet opens
```

## Build Validation

Last validation after multi-window changes:

```text
Xcode BuildProject: succeeded
```

Run a fresh build after merging any branch that touches:

- `ContentView.swift`
- `AVPGroupAppApp.swift`
- `CPRGuideView.swift`
- `ImmersiveView.swift`
- `AppModel.swift`

