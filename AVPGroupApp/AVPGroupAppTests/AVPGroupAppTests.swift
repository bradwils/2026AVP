//
//  AVPGroupAppTests.swift
//  AVPGroupAppTests
//
//  Created by brad wils on 23/6/26.
//

import Testing
@testable import AVPGroupApp

struct AVPGroupAppTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
        // Swift Testing Documentation
        // https://developer.apple.com/documentation/testing
    }

    /// Feeds a linear ramp of distance values into `detector`, stepping `timestamp` by `dt` each call.
    private func ramp(_ detector: inout PumpDetector, from start: Double, to end: Double, steps: Int, dt: Double, startTime: Double) -> Double {
        var time = startTime
        for i in 1...steps {
            let distance = start + (end - start) * Double(i) / Double(steps)
            time += dt
            _ = detector.update(distance: distance, timestamp: time)
        }
        return time
    }

    @Test func cleanSinglePump() async throws {
        var detector = PumpDetector()
        _ = detector.update(distance: 0.0, timestamp: 0.0)

        let time = ramp(&detector, from: 0.0, to: 0.08, steps: 5, dt: 0.05, startTime: 0.0)
        _ = ramp(&detector, from: 0.08, to: 0.0, steps: 5, dt: 0.05, startTime: time)

        #expect(detector.pumpCount == 1)
        #expect(detector.state == .near)
    }

    @Test func oscillationUnderThresholdDoesNotCount() async throws {
        var detector = PumpDetector()
        _ = detector.update(distance: 0.0, timestamp: 0.0)

        var time = 0.0
        for i in 0..<20 {
            let distance = i % 2 == 0 ? 0.03 : 0.0
            time += 0.05
            _ = detector.update(distance: distance, timestamp: time)
        }

        #expect(detector.pumpCount == 0)
    }

    @Test func baselineDriftTolerance() async throws {
        var detector = PumpDetector()
        _ = detector.update(distance: 0.10, timestamp: 0.0)

        var driftTime = ramp(&detector, from: 0.10, to: 0.15, steps: 20, dt: 0.5, startTime: 0.0)
        // Hold steady at the new level so the EMA (which lags a moving target) finishes settling.
        driftTime = ramp(&detector, from: 0.15, to: 0.15, steps: 10, dt: 0.5, startTime: driftTime)

        #expect(abs(detector.baseline! - 0.15) < 0.02)

        let time = ramp(&detector, from: 0.15, to: 0.20, steps: 5, dt: 0.05, startTime: driftTime)
        _ = ramp(&detector, from: 0.20, to: 0.15, steps: 5, dt: 0.05, startTime: time)

        #expect(detector.pumpCount == 1)
    }

    @Test func resetClearsEverything() async throws {
        var detector = PumpDetector()
        _ = detector.update(distance: 0.0, timestamp: 0.0)
        let time = ramp(&detector, from: 0.0, to: 0.08, steps: 5, dt: 0.05, startTime: 0.0)
        _ = ramp(&detector, from: 0.08, to: 0.0, steps: 5, dt: 0.05, startTime: time)
        #expect(detector.pumpCount == 1)

        detector.reset()

        #expect(detector.pumpCount == 0)
        #expect(detector.state == .near)
        #expect(detector.baseline == nil)
    }

}
