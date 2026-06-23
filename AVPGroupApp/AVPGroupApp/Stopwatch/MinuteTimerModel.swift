//
//  MinuteTimerModel.swift
//  AVPGroupApp
//
//  Created by brad wils on 23/6/26.
//

import ARKit
import Foundation
import Observation

/// Counts down from 60 seconds for CPR-cycle pacing, while tracking compressions
/// ("pumps") via hand-to-headset distance for the same active session.
@MainActor
@Observable
final class MinuteTimerModel {
    static let duration: TimeInterval = 30

    private(set) var timeRemaining: TimeInterval = duration
    private(set) var isRunning = false
    private(set) var pumpCount: Int = 0
    private(set) var isHandTracked: Bool = false
    private(set) var bpm: Double = 0

    private var timer: Timer?
    private let beepPlayer = BeepPlayer()
    private let pumpBeepPlayer = BeepPlayer(frequency: 1200, duration: 0.08)
    private var detector = PumpDetector()
    private var session: ARKitSession?
    private var handTracking: HandTrackingProvider?
    private var worldTracking: WorldTrackingProvider?
    private var processingTask: Task<Void, Never>?
    private var lastLeftWristWorldPosition: SIMD3<Float>?
    private var lastRightWristWorldPosition: SIMD3<Float>?
    private var pumpTimestamps: [Double] = []

    var isFinished: Bool {
        timeRemaining <= 0
    }

    func start() {
        guard !isRunning, !isFinished else { return }
        isRunning = true
        detector.reset()
        pumpCount = 0
        pumpTimestamps = []
        bpm = 0
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
        bpm = 0
    }

    func reset() {
        pause()
        timeRemaining = Self.duration
        pumpCount = 0
        bpm = 0
    }

    private func tick() {
        let wasFinished = isFinished
        timeRemaining = max(0, timeRemaining - 0.1)
        if isFinished && !wasFinished {
            pause()
            beepPlayer.play()
        }
    }

    func startSession() async {
        // A stopped ARKitSession can never be run again, so a fresh session
        // and fresh providers are created on every start to support repeated Start/Stop cycles.
        guard processingTask == nil else { return }
        guard HandTrackingProvider.isSupported, WorldTrackingProvider.isSupported else { return }

        lastLeftWristWorldPosition = nil
        lastRightWristWorldPosition = nil
        isHandTracked = false

        let session = ARKitSession()
        let handTracking = HandTrackingProvider()
        let worldTracking = WorldTrackingProvider()

        do {
            try await session.run([handTracking, worldTracking])
        } catch {
            return
        }

        self.session = session
        self.handTracking = handTracking
        self.worldTracking = worldTracking
        processingTask = Task { [weak self] in
            await self?.processHandUpdates(handTracking: handTracking, worldTracking: worldTracking)
        }
    }

    func stopSession() {
        processingTask?.cancel()
        processingTask = nil
        session?.stop()
        session = nil
        handTracking = nil
        worldTracking = nil
        isHandTracked = false
    }

    private func processHandUpdates(handTracking: HandTrackingProvider, worldTracking: WorldTrackingProvider) async {
        for await update in handTracking.anchorUpdates {
            let anchor = update.anchor
            guard anchor.isTracked else { continue }
            guard let wrist = anchor.handSkeleton?.joint(.wrist) else { continue }

            // Transform wrist joint from anchor space to world space
            let wristTransform = anchor.originFromAnchorTransform * wrist.anchorFromJointTransform
            let wristPosition = SIMD3<Float>(wristTransform.columns.3.x, wristTransform.columns.3.y, wristTransform.columns.3.z)

            switch anchor.chirality {
            case .left:
                lastLeftWristWorldPosition = wristPosition
            case .right:
                lastRightWristWorldPosition = wristPosition
            }

            guard let deviceAnchor = worldTracking.queryDeviceAnchor(atTimestamp: anchor.timestamp),
                  deviceAnchor.trackingState == .tracked else { continue }
            // Get headset position in world space to measure hand-to-headset distance
            let deviceTransform = deviceAnchor.originFromAnchorTransform
            let devicePosition = SIMD3<Float>(deviceTransform.columns.3.x, deviceTransform.columns.3.y, deviceTransform.columns.3.z)

            // Use average of both hands if available, fallback to whichever is tracked
            let combinedHandPosition: SIMD3<Float>
            switch (lastLeftWristWorldPosition, lastRightWristWorldPosition) {
            case let (.some(left), .some(right)):
                combinedHandPosition = (left + right) / 2
            case let (.some(left), nil):
                combinedHandPosition = left
            case let (nil, .some(right)):
                combinedHandPosition = right
            case (nil, nil):
                isHandTracked = false
                continue
            }
            isHandTracked = true

            let distance = simd_distance(combinedHandPosition, devicePosition)
            if isRunning {
                // Use hand anchor timestamp (not wall-clock) so detector's time deltas match actual sample intervals
                let counted = detector.update(distance: Double(distance), timestamp: anchor.timestamp)
                if counted {
                    pumpCount = detector.pumpCount
                    pumpBeepPlayer.play()
                    recordPump(at: anchor.timestamp)
                }
            }
        }
    }

    /// BPM is the average interval over the last 8 real pump events.
    private func recordPump(at timestamp: Double) {
        pumpTimestamps.append(timestamp)
        if pumpTimestamps.count > 8 {
            pumpTimestamps.removeFirst()
        }
        guard pumpTimestamps.count >= 2 else { return }
        let intervals = zip(pumpTimestamps, pumpTimestamps.dropFirst()).map { $1 - $0 }
        let avgInterval = intervals.reduce(0, +) / Double(intervals.count)
        bpm = avgInterval > 0 ? 60 / avgInterval : 0
    }
}
