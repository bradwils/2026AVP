//
//  PumpDetector.swift
//  AVPGroupApp
//
//  Created by brad wils on 23/6/26.
//

import Foundation

/// Detects a CPR compression ("pump") from a hand-to-headset distance stream using a hysteresis (Schmitt trigger) state machine.
struct PumpDetector {
    enum State { case near, away }
    

    var awayThreshold: Double = 0.02
    var returnThreshold: Double = 0.02
    var baselineHalfLife: Double = 1

    private(set) var state: State = .near
    private(set) var baseline: Double? = nil
    private(set) var pumpCount: Int = 0
    private var lastSampleTime: Double? = nil
    
    mutating func changePumpSensitivity(type: String) {
        switch type {
        case "sensitive":
            awayThreshold = 0.01
            returnThreshold = 0.01
            break;
            
        case "normal":
            awayThreshold = 0.02
            returnThreshold = 0.02
            break;
        case "weak":
            awayThreshold = 0.03
            returnThreshold = 0.03
        default:
            awayThreshold = 0.03
            returnThreshold = 0.03
            
        }
    }

    mutating func update(distance: Double, timestamp: Double) -> Bool {
        guard let baseline else {
            self.baseline = distance
            lastSampleTime = timestamp
            return false
        }

        let dt = min(timestamp - lastSampleTime!, 0.2)
        lastSampleTime = timestamp

        // Freeze the baseline during an excursion so the pump motion itself can't drag it along
        if state == .near {
            // Exponential moving average: alpha decays distance error over baselineHalfLife
            let alpha = 1 - exp(-log(2) * dt / baselineHalfLife)
            self.baseline = baseline + alpha * (distance - baseline)
        }

        let delta = distance - self.baseline!

        // Hysteresis state machine: separate thresholds prevent jitter near boundaries
        switch state {
        case .near:
            if delta > awayThreshold {
                state = .away
            }
        case .away:
            if delta < returnThreshold {
                state = .near
                pumpCount += 1
                return true
            }
        }
        return false
    }

    mutating func reset() {
        state = .near
        baseline = nil
        pumpCount = 0
        lastSampleTime = nil
    }
}
