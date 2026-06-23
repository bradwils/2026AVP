import SwiftUI

/// Root layout for the instructions phase.
/// The 2D window contains the central instruction popup.
/// Left/right ornaments (separate windows or panels) host the
/// stopwatch and BPM widgets — exposed as `ornament` modifiers.
struct InstructionsRootView: View {

    @Environment(AppModel.self) private var appModel

    var body: some View {
        ZStack {
            backgroundGradient.ignoresSafeArea()

            HStack(alignment: .top, spacing: 0) {
                // LEFT: Session stopwatch
                SessionTimerWidget()
                    .frame(width: 200)
                    .padding(.leading, 24)

                Spacer()

                // CENTRE: Instruction card
                InstructionCardView()
                    .frame(maxWidth: 520)

                Spacer()

                // RIGHT: BPM + audio controls
                BPMWidget()
                    .frame(width: 220)
                    .padding(.trailing, 24)
            }
            .padding(.vertical, 32)
        }
        .frame(minWidth: 1100, minHeight: 700)
    }

    var backgroundGradient: some View {
        LinearGradient(
            colors: [Color(red: 0.05, green: 0.07, blue: 0.18),
                     Color(red: 0.08, green: 0.12, blue: 0.28)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Central instruction card

struct InstructionCardView: View {

    @Environment(AppModel.self) private var appModel

    var body: some View {
        let step = appModel.currentStep
        let allSteps = InstructionStep.allCases

        VStack(spacing: 0) {
            // Progress bar
            progressBar(allSteps: allSteps, current: step)
                .padding(.bottom, 24)

            // Card body
            VStack(spacing: 28) {

                // Icon
                ZStack {
                    Circle()
                        .fill(iconColor(step).opacity(0.15))
                        .frame(width: 96, height: 96)
                    Image(systemName: step.systemImage)
                        .font(.system(size: 44))
                        .foregroundStyle(iconColor(step))
                }

                // Title
                Text(step.title)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                // Body
                Text(step.body)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 8)

                Divider().overlay(Color.white.opacity(0.15))

                // Navigation buttons
                HStack(spacing: 20) {
                    if step != .prepareSurface {
                        Button {
                            withAnimation { appModel.previousInstruction() }
                        } label: {
                            Label("Back", systemImage: "chevron.left")
                                .font(.callout)
                        }
                        .buttonStyle(.bordered)
                        .tint(.white.opacity(0.5))
                    }

                    Spacer()

                    if step == .complete {
                        Button {
                            appModel.startQuiz()
                        } label: {
                            Label("Take the Quiz", systemImage: "checkmark.circle.fill")
                                .font(.title3.bold())
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    } else {
                        Button {
                            withAnimation { appModel.nextInstruction() }
                        } label: {
                            Label("Next", systemImage: "chevron.right")
                                .font(.title3.bold())
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(step == .compressions ? .red : .blue)
                    }
                }
            }
            .padding(36)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
    }

    private func progressBar(allSteps: [InstructionStep], current: InstructionStep) -> some View {
        let total = allSteps.count
        let currentIdx = allSteps.firstIndex(of: current) ?? 0

        return HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { i in
                Capsule()
                    .fill(i <= currentIdx ? Color.red : Color.white.opacity(0.2))
                    .frame(height: 4)
                    .animation(.easeInOut, value: current)
            }
        }
        .padding(.horizontal, 8)
    }

    private func iconColor(_ step: InstructionStep) -> Color {
        switch step {
        case .compressions: return .red
        case .callForHelp:  return .orange
        case .complete:     return .green
        default:            return .blue
        }
    }
}

// MARK: - Session stopwatch widget (left panel)

struct SessionTimerWidget: View {

    @Environment(AppModel.self) private var appModel

    var body: some View {
        VStack(spacing: 20) {
            Text("Session Time")
                .font(.caption.uppercaseSmallCaps())
                .foregroundStyle(.white.opacity(0.6))

            Text(appModel.sessionTimeString)
                .font(.system(size: 42, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
                .contentTransition(.numericText())

            Image(systemName: "timer")
                .font(.title2)
                .foregroundStyle(.blue.opacity(0.8))
        }
        .padding(24)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - BPM + audio widget (right panel)

struct BPMWidget: View {

    @Environment(AppModel.self) private var appModel

    var body: some View {
        VStack(spacing: 0) {

            // BPM display
            VStack(spacing: 12) {
                Text("Compression Rate")
                    .font(.caption.uppercaseSmallCaps())
                    .foregroundStyle(.white.opacity(0.6))

                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(appModel.detectedBPM == 0 ? "--" : "\(appModel.detectedBPM)")")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(bpmColor)
                        .contentTransition(.numericText())
                    Text("BPM")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }

                // Target range label
                Text("Target: 100–120 BPM")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))

                // Delta indicator
                if appModel.detectedBPM > 0 {
                    deltaLabel
                }
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))

            Spacer().frame(height: 16)

            // Audio controls
            VStack(spacing: 12) {
                Text("Audio")
                    .font(.caption.uppercaseSmallCaps())
                    .foregroundStyle(.white.opacity(0.6))

                // Heartbeat toggle
                Button {
                    appModel.toggleHeartbeat()
                } label: {
                    Label(appModel.heartbeatPlaying ? "Stop Heartbeat" : "Play Heartbeat",
                          systemImage: appModel.heartbeatPlaying ? "stop.circle.fill" : "heart.fill")
                        .font(.callout)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(appModel.heartbeatPlaying ? .red : .pink)

                // Mute toggle
                Button {
                    appModel.toggleMute()
                } label: {
                    Label(appModel.metronomeMuted ? "Unmute Beat" : "Mute Beat",
                          systemImage: appModel.metronomeMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.callout)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.white.opacity(0.6))

                // Volume slider
                HStack(spacing: 8) {
                    Image(systemName: "speaker.fill")
                        .foregroundStyle(.white.opacity(0.4))
                        .font(.caption)
                    Slider(value: Binding(
                        get: { Double(appModel.metronomeVolume) },
                        set: { appModel.setVolume(Float($0)) }
                    ), in: 0...1)
                    .tint(.white)
                    Image(systemName: "speaker.wave.3.fill")
                        .foregroundStyle(.white.opacity(0.4))
                        .font(.caption)
                }
            }
            .padding(16)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))

            Spacer().frame(height: 16)

            // Replay video button
            Button {
                appModel.replayVideo()
            } label: {
                Label("Replay Video", systemImage: "play.circle")
                    .font(.callout)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.white.opacity(0.5))
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))

            Spacer().frame(height: 12)

            // Quiz shortcut
            Button {
                appModel.startQuiz()
            } label: {
                Label("Take Quiz", systemImage: "checkmark.circle")
                    .font(.callout)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.indigo)
        }
    }

    private var bpmColor: Color {
        let bpm = appModel.detectedBPM
        if bpm == 0 { return .white.opacity(0.4) }
        if bpm >= 100 && bpm <= 120 { return .green }
        if bpm < 80 || bpm > 140 { return .red }
        return .orange
    }

    private var deltaLabel: some View {
        let delta = appModel.bpmDelta
        let label = delta > 0 ? "+\(delta) BPM — too fast" :
                    delta < 0 ? "\(delta) BPM — too slow" :
                                "Perfect rate!"
        let color: Color = abs(delta) <= 5 ? .green : .orange
        return Text(label)
            .font(.caption2)
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.15), in: Capsule())
    }
}
