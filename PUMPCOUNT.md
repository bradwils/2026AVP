# PumpCounter → Stopwatch merge: how this branch is wired

This branch (`pumpCounter`) merges what used to be a separate "Pump Counter"
feature into the Stopwatch feature, so there is now **one** element —
the Stopwatch — that owns both CPR-cycle timing and compression
(pump) counting. There is no `PumpCounter/` directory anymore and no
standalone pump-counter window/model/view. If you're wiring this branch
into `main`, read this before re-introducing anything pump-related — it
almost certainly already lives in `Stopwatch/`.

## App entry point and scene graph (`AVPGroupAppApp.swift`)

`AVPGroupAppApp` is the `@main` entry point. It owns two shared,
`@Observable` models as `@State`, created once and pushed down via
`.environment(...)` to whichever scene needs them:

- `appModel = AppModel()` — generic app-wide state (immersive space
  open/closed tracking for the *main* immersive experience, plus some
  unused/legacy lesson-flow scaffolding — see "Orphaned code" below).
- `stopwatchModel = MinuteTimerModel()` — **the single shared instance**
  backing the merged Stopwatch+PumpCounter feature. Created once at the
  app level (not locally inside a view) specifically so that both the
  2D stopwatch window and the hand-tracking immersive space can read/
  mutate the same instance.

Scenes declared in `body`:

| Scene | id | Content | Environment injected |
|---|---|---|---|
| `WindowGroup` | (default) | `ContentView()` | `appModel` |
| `WindowGroup` | `"stopwatch"` | `MinuteTimerView()` | `stopwatchModel` |
| `WindowGroup` | `"cpr-video"` | `CPRVideoView()` | — |
| `WindowGroup` | `"cpr-steps"` | `CPRStepsView()` | — |
| `ImmersiveSpace` | `"stopwatchImmersiveSpace"` | `StopwatchImmersiveView()` | `stopwatchModel` |
| `ImmersiveSpace` | `appModel.immersiveSpaceID` (`"ImmersiveSpace"`) | `ImmersiveView()` | `appModel` |

visionOS only allows **one immersive space open at a time**. The two
`ImmersiveSpace`s above are mutually exclusive — opening one implicitly
requires the other to be closed first. `"stopwatchImmersiveSpace"`
exists purely so the Stopwatch can get an ARKit hand-tracking session
running (ARKit sessions need an open immersive space); it renders
nothing visible itself.

## The merged feature: `AVPGroupApp/Stopwatch/`

Everything pump-related now lives here, alongside the timer:

- **`MinuteTimerModel.swift`** — the single source of truth. `@MainActor
  @Observable final class`. Combines what used to be two separate
  models (`MinuteTimerModel` + `PumpCounterModel`):
  - Countdown timer: `timeRemaining`, `isRunning`, `isFinished`,
    `start()` / `pause()` / `reset()`, driven by a repeating `Timer`
    that ticks every 0.1s. Plays a completion beep (`BeepPlayer`) when
    it reaches zero.
  - ARKit hand-tracking session: `startSession()` / `stopSession()`
    create/tear down an `ARKitSession` running `HandTrackingProvider`
    + `WorldTrackingProvider`. A *new* session/providers are created on
    every `startSession()` call because a stopped `ARKitSession` can
    never be re-run.
  - Pump detection: holds a `PumpDetector` (pure value-type state
    machine, see below), exposes `pumpCount`, `bpm`, `isHandTracked`.
    `processHandUpdates(...)` consumes `handTracking.anchorUpdates`,
    computes hand-to-headset distance, and — only while `isRunning` is
    true — feeds that distance into `detector.update(...)`. A detected
    pump plays a short high-pitched beep and is recorded into
    `pumpTimestamps` (last 8 events) to compute a rolling `bpm`.
  - `start()` resets the detector/count/bpm; `pause()`/`reset()` clear
    `bpm`. Pump counting is intentionally tied to the *timer's*
    running state (`isRunning`) rather than a separate monitoring flag
    — there is no independent "start/stop monitoring" concept anymore.

- **`PumpDetector.swift`** — unchanged pure logic, just relocated from
  the old `PumpCounter/` folder. Hysteresis (Schmitt trigger) state
  machine over a hand-to-headset distance stream: tracks an
  exponential-moving-average `baseline` (frozen during an excursion),
  flips `near` → `away` when distance rises `awayThreshold` above
  baseline, flips back `away` → `near` (incrementing `pumpCount`) when
  it falls back within `returnThreshold`. **The old
  `changePumpSensitivity(type:)` method and the three sensitivity
  presets ("sensitive"/"normal"/"weak") have been deleted.**
  `awayThreshold`/`returnThreshold` are now fixed at `0.02` with no UI
  or model path to change them. If a future requirement wants
  adjustable sensitivity back, it needs to be re-added here and exposed
  through `MinuteTimerModel`, not through a separate model/view.

- **`StopwatchImmersiveView.swift`** — renamed from
  `PumpCounterImmersiveView.swift`. Trivial `RealityView` that renders
  nothing; its only job is `.task { await model.startSession() }` /
  `.onDisappear { model.stopSession() }` against the shared
  `MinuteTimerModel` from the environment. This is what
  `"stopwatchImmersiveSpace"` opens.

- **`MinuteTimerView.swift`** — the single 2D UI element. Reads
  `MinuteTimerModel` from the environment (it does **not** own a local
  `@State` instance anymore — it must use the shared one injected by
  `AVPGroupAppApp`, otherwise it would talk to a different model than
  `StopwatchImmersiveView` does). Renders the countdown, current `bpm`,
  and `pumpCount` all in one view. The Start/Pause button does both
  jobs at once: starting the timer (`model.start()`) *and* opening
  `"stopwatchImmersiveSpace"` (which starts the ARKit session); pausing
  does the reverse (`model.pause()` + `dismissImmersiveSpace()`). There
  is no separate "start monitoring" affordance — it's one button, one
  element.

- **`BeepPlayer.swift`** — unchanged. Two instances exist in
  `MinuteTimerModel`: one default-pitch beep for "timer finished", one
  higher-pitched/shorter beep for "pump detected".

## `ContentView.swift`

`MainView` (the 2D hub window shown after the welcome screen) has a
single `Button("Open Stopwatch") { openWindow(id: "stopwatch") }`. The
old `Button("Open Pump Counter") { openWindow(id: "pumpCounter") }` has
been removed — there is nothing to wire it to anymore, since the
`"pumpCounter"` `WindowGroup` no longer exists.

## What to NOT re-introduce when merging into `main`

If `main` (or a PR being merged in) still has any of the following,
they are the **pre-merge** version of this feature and should be
deleted/reconciled in favor of what's described above, not kept
side-by-side:

- A `PumpCounter/` directory or any file named
  `PumpCounterModel.swift` / `PumpCounterView.swift` /
  `PumpCounterImmersiveView.swift`.
- A `WindowGroup(id: "pumpCounter")` or
  `ImmersiveSpace(id: "pumpCounterImmersiveSpace")` in
  `AVPGroupAppApp.swift`.
- A `pumpCounterModel` / `PumpCounterModel()` `@State` at the app level.
- Any "Pumping Sensitivity" UI (Sensitive/Normal/Weak buttons) or
  `changePumpSensitivity(_:)` calls.
- `MinuteTimerView` owning its own local `@State private var model =
  MinuteTimerModel()` instead of reading it from `@Environment`.

## Orphaned / unrelated code (do not confuse with this feature)

`AppModel.swift` contains a second, **unused**, parallel implementation
of compression tracking: `compressionCount`, `compressionBPM`,
`handPlacementCorrect`, `recordCompression()`, `resetCPRSession()`,
`rhythmFeedback`, `rhythmColor`, plus a `lessonPhase: LessonPhase`
enum (`welcome`/`lessonSelection`/`anatomy`/`scenario`/`cprPractice`/
`quiz`/`results`) driving `PLWelcomeView` (`WelcomeView.swift`) and
`LessonSelectionView.swift`. **Nothing calls `recordCompression()`**,
and `ContentView`'s actual welcome flow uses its own local
`showWelcome` `@State` + a different, in-file `WelcomeView`/`MainView`
— not `AppModel.lessonPhase` or `PLWelcomeView`. This looks like
leftover scaffolding from an earlier/parallel lesson-flow design and is
not wired into the live navigation path or into the Stopwatch feature.
Worth flagging to the team, but out of scope for this merge — don't
assume it's where pump/compression state should live.

## ⚠️ Manual reconciliation required: `AVPGroupAppApp.swift` and `ContentView.swift`

**These two files are intentionally NOT pushed as part of this branch's
diff**, because they would conflict with `main` (both files have moved
on independently on `main` since this branch forked — e.g. `main`
already has a bare `WindowGroup(id: "stopwatch") { MinuteTimerView() }`
with no model injection). Every other file described above (the
`Stopwatch/` folder contents, the `PumpCounter/` deletion) is pushed
normally and should merge cleanly. For these two files, whoever merges
this into `main` needs to **manually apply the following edits to
`main`'s current versions** rather than taking either side wholesale —
do not just resolve the conflict by picking one side, since `main`'s
copies will likely have additional unrelated changes by then too.

### `AVPGroupApp/AVPGroupApp/AVPGroupAppApp.swift`

Against `main` as of this writing, apply:

1. Add a shared model alongside `appModel`:
   ```swift
   @State private var appModel = AppModel()
   @State private var stopwatchModel = MinuteTimerModel()
   ```

2. Inject it into the existing stopwatch window:
   ```swift
   WindowGroup(id: "stopwatch") {
       MinuteTimerView()
           .environment(stopwatchModel)
   }
   .defaultSize(width: 300, height: 250)
   .windowResizability(.contentSize)
   ```

3. Add a new `ImmersiveSpace` for the stopwatch's hand-tracking session.
   Insert it **before** the existing main `ImmersiveSpace(id:
   appModel.immersiveSpaceID)` block (order doesn't matter functionally,
   but keeps it grouped with the stopwatch window above):
   ```swift
   ImmersiveSpace(id: "stopwatchImmersiveSpace") {
       StopwatchImmersiveView().environment(stopwatchModel)
   }
   ```

Do **not** add back a `pumpCounterModel`, a
`WindowGroup(id: "pumpCounter")`, or an
`ImmersiveSpace(id: "pumpCounterImmersiveSpace")` — those no longer
exist on either side and shouldn't be reintroduced.

### `AVPGroupApp/AVPGroupApp/ContentView.swift`

Against `main` as of this writing, apply:

1. `MainView` needs access to `openWindow` (main's current `MainView`
   has no `@Environment` at all):
   ```swift
   struct MainView: View {
       @Environment(\.openWindow) private var openWindow

       var body: some View {
           VStack {
               Model3D(named: "Scene", bundle: realityKitContentBundle)
                   .padding(.bottom, 50)

               Text("Hello, world!")

               Button("Open Stopwatch") {
                   openWindow(id: "stopwatch")
               }

               ToggleImmersiveSpaceButton()
           }
           .padding()
       }
   }
   ```
   (i.e. add the `@Environment(\.openWindow)` line and the
   `Button("Open Stopwatch") { openWindow(id: "stopwatch") }` block —
   everything else in `MainView` is unchanged.)

Do **not** add an `@Environment(\.openWindow)` to the outer
`ContentView` struct itself (an earlier version of this branch did,
but `openWindow` is only actually used in `MainView`, so it doesn't
belong on `ContentView`) and do **not** add a
`Button("Open Pump Counter")` — there is no `"pumpCounter"` window to
open.

After applying both edits by hand, rebuild
(`xcodebuildmcp simulator build ...`, see below) to confirm
`MinuteTimerView`/`StopwatchImmersiveView`/`stopwatchModel` all resolve
— a stale manual edit here is the most likely source of a "Cannot find
X in scope" error after this merge.

## Verifying after a merge

- Build: visionOS Simulator, scheme `AVPGroupApp`
  (`xcodebuildmcp simulator build --project-path
  AVPGroupApp/AVPGroupApp.xcodeproj --scheme AVPGroupApp
  --simulator-name "Apple Vision Pro"`).
- Tests: `AVPGroupAppTests.swift` exercises `PumpDetector` directly
  (now at `Stopwatch/PumpDetector.swift`) — no test currently exercises
  `MinuteTimerModel` itself (it touches ARKit/`HandTrackingProvider`,
  which isn't available off-device/in most test contexts).
- Hand tracking only works on-device, not in the simulator
  (`HandTrackingProvider`/`WorldTrackingProvider` need a real device);
  the simulator build will compile and run the timer half of the
  feature, but `pumpCount`/`bpm`/`isHandTracked` won't update there.
