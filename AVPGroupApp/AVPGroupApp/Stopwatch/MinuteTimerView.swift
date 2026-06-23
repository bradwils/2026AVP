//
//  MinuteTimerView.swift
//  AVPGroupApp
//
//  Created by brad wils on 23/6/26.
//

import SwiftUI

struct MinuteTimerView: View {
    @State private var model = MinuteTimerModel()

    private var formattedTime: String {
        let seconds = Int(model.timeRemaining.rounded(.up))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    var body: some View {
        VStack(spacing: 16) {
            Text(formattedTime)
                .font(.system(size: 48, weight: .semibold, design: .monospaced))
                .monospacedDigit()

            HStack(spacing: 12) {
                Button(model.isRunning ? "Pause" : "Start") {
                    model.isRunning ? model.pause() : model.start()
                }
                .disabled(model.isFinished)

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
}
