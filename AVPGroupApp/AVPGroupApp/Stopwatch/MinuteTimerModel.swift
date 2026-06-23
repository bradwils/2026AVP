//
//  MinuteTimerModel.swift
//  AVPGroupApp
//
//  Created by brad wils on 23/6/26.
//

import Foundation
import Observation

/// Counts down from 60 seconds, used for CPR-cycle pacing.
@MainActor
@Observable
final class MinuteTimerModel {
    static let duration: TimeInterval = 60

    private(set) var timeRemaining: TimeInterval = duration
    private(set) var isRunning = false

    private var timer: Timer?
    private let beepPlayer = BeepPlayer()

    var isFinished: Bool {
        timeRemaining <= 0
    }

    func start() {
        guard !isRunning, !isFinished else { return }
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    func reset() {
        pause()
        timeRemaining = Self.duration
    }

    private func tick() {
        let wasFinished = isFinished
        timeRemaining = max(0, timeRemaining - 0.1)
        if isFinished && !wasFinished {
            pause()
            beepPlayer.play()
        }
    }
}
