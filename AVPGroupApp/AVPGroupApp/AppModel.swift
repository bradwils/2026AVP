//
//  AppModel.swift
//  AVPGroupApp
//

import SwiftUI
import Observation

enum LessonPhase: Equatable {
    case welcome
    case lessonSelection
    case anatomy
    case scenario
    case cprPractice
    case quiz
    case results
}

/// Maintains app-wide state for PulseLab XR
@MainActor
@Observable
class AppModel {
    let immersiveSpaceID = "ImmersiveSpace"

    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }
    var immersiveSpaceState = ImmersiveSpaceState.closed

    // Lesson navigation
    var lessonPhase: LessonPhase = .welcome

    // CPR session data
    var compressionCount: Int = 0
    var compressionBPM: Double = 0
    private var compressionTimestamps: [Date] = []
    var handPlacementCorrect: Bool = false

    // Results
    var quizScore: Int = 0
    var lesson1Completed: Bool = false

    func recordCompression() {
        let now = Date()
        compressionTimestamps.append(now)
        compressionCount += 1
        if compressionTimestamps.count > 6 {
            compressionTimestamps.removeFirst()
        }
        if compressionTimestamps.count >= 2 {
            let intervals = zip(compressionTimestamps, compressionTimestamps.dropFirst())
                .map { $1.timeIntervalSince($0) }
            let avg = intervals.reduce(0, +) / Double(intervals.count)
            compressionBPM = avg > 0 ? 60.0 / avg : 0
        }
    }

    func resetCPRSession() {
        compressionCount = 0
        compressionBPM = 0
        compressionTimestamps = []
        handPlacementCorrect = false
    }

    var rhythmFeedback: String {
        guard compressionCount >= 2 else { return "Place hands on chest target and begin" }
        if compressionBPM < 100 { return "Too slow — push faster" }
        if compressionBPM > 120 { return "Too fast — slow down" }
        return "Good rhythm — keep going"
    }

    var rhythmColor: Color {
        guard compressionCount >= 2 else { return .white }
        if compressionBPM < 100 { return .orange }
        if compressionBPM > 120 { return .red }
        return .green
    }
}
