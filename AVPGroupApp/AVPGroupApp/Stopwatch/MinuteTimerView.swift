//
//  MinuteTimerView.swift
//  AVPGroupApp
//
//  Created by brad wils on 23/6/26.
//

import SwiftUI

struct MinuteTimerView: View {
    @Environment(MinuteTimerModel.self) private var model
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace

    @State private var isTransitioning = false

    private var formattedTime: String {
        let seconds = Int(model.timeRemaining.rounded(.up))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    private var bpmText: String {
        model.bpm > 0 ? "\(Int(model.bpm.rounded())) BPM" : "-- BPM"
    }

    var body: some View {
        VStack(spacing: 16) {
            Text(formattedTime)
                .font(.system(size: 48, weight: .semibold, design: .monospaced))
                .monospacedDigit()

            Text(bpmText)
                .font(.title2.monospacedDigit())
                .foregroundStyle(.secondary)

            Text("\(model.pumpCount) pumps")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Button(model.isRunning ? "Pause" : "Start") {
                    isTransitioning = true
                    if model.isRunning {
                        model.pause()
                        Task {
                            await dismissImmersiveSpace()
                            isTransitioning = false
                        }
                    } else {
                        model.start()
                        Task {
                            // Pump detection needs the hand-tracking immersive space open
                            _ = await openImmersiveSpace(id: "stopwatchImmersiveSpace")
                            isTransitioning = false
                        }
                    }
                }
                .disabled(model.isFinished || isTransitioning)

                Button("Reset") {
                    model.reset()
                }
            }
        }
        .padding(20)
        .glassBackgroundEffect()
    }
}

#Preview {
    MinuteTimerView()
        .environment(MinuteTimerModel())
}
