//
//  AppModel.swift
//  AVPGroupApp
//

import SwiftUI
import Observation
import AudioToolbox

enum LessonPhase: Equatable {
    case welcome
    case lessonSelection
    case anatomy
    case scenario
    case cprPractice
    case quiz
    case results
}

enum AppPhase: Equatable {
    case landing
    case watchingVideo
    case instructions
    case quiz
    case quizResults
}

enum InstructionStep: Int, CaseIterable {
    case prepareSurface = 0
    case checkScene
    case checkPerson
    case callForHelp
    case positioning
    case compressions
    case complete

    var title: String {
        switch self {
        case .prepareSurface: return "Prepare the Surface"
        case .checkScene: return "Check the Scene"
        case .checkPerson: return "Check the Person"
        case .callForHelp: return "Call for Help"
        case .positioning: return "Hand Positioning"
        case .compressions: return "Begin Compressions"
        case .complete: return "Well Done"
        }
    }

    var body: String {
        switch self {
        case .prepareSurface:
            return "Place a semi-soft surface, like a pillow, where the torso is shown. This helps you practise compressions against a realistic target."
        case .checkScene:
            return "Look around and make sure the scene is safe. Remove hazards before approaching the person."
        case .checkPerson:
            return "Tap the person's shoulders firmly and shout, Are you OK? Check for normal breathing for no more than 10 seconds."
        case .callForHelp:
            return "Call 000 in Australia, or your local emergency number, immediately. Ask a bystander to call while you begin CPR."
        case .positioning:
            return "Kneel beside the person. Place the heel of one hand on the centre of the chest, on the lower half of the breastbone. Place your other hand on top and interlace your fingers."
        case .compressions:
            return "Push hard and fast at 100-120 compressions per minute. Allow full chest recoil between compressions and follow the beat on the right."
        case .complete:
            return "You have completed the CPR walkthrough. Continue practising, replay the video, or take the quiz."
        }
    }

    var systemImage: String {
        switch self {
        case .prepareSurface: return "bed.double.fill"
        case .checkScene: return "eye.fill"
        case .checkPerson: return "hand.tap.fill"
        case .callForHelp: return "phone.fill"
        case .positioning: return "hand.raised.fill"
        case .compressions: return "heart.fill"
        case .complete: return "checkmark.seal.fill"
        }
    }
}

struct QuizQuestion {
    let question: String
    let options: [String]
    let correctIndex: Int
    let explanation: String
}

let cprQuizQuestions: [QuizQuestion] = [
    QuizQuestion(
        question: "How deep should chest compressions be for an adult?",
        options: ["2-3 cm", "At least 5 cm", "7-8 cm", "As deep as possible"],
        correctIndex: 1,
        explanation: "Adult compressions should be at least 5 cm deep to help circulate blood."
    ),
    QuizQuestion(
        question: "What is the correct compression rate for CPR?",
        options: ["60-80 BPM", "80-100 BPM", "100-120 BPM", "120-140 BPM"],
        correctIndex: 2,
        explanation: "The recommended rate is 100-120 compressions per minute."
    ),
    QuizQuestion(
        question: "Where should you place your hands for chest compressions?",
        options: ["On the stomach", "Near the collarbone", "Centre of the chest on the lower breastbone", "Left side over the heart"],
        correctIndex: 2,
        explanation: "Place the heel of one hand on the lower half of the sternum, in the centre of the chest."
    ),
    QuizQuestion(
        question: "What should you do first when you find an unresponsive person?",
        options: ["Begin compressions immediately", "Check response and breathing, then call for help", "Give rescue breaths first", "Wait for someone else"],
        correctIndex: 1,
        explanation: "Check responsiveness and breathing first, then call emergency services before or while starting CPR."
    ),
    QuizQuestion(
        question: "After each compression, what should happen?",
        options: ["Keep pressure on the chest", "Allow the chest to fully recoil", "Press harder on the next compression", "Pause for 2 seconds"],
        correctIndex: 1,
        explanation: "Full recoil allows the heart to refill with blood before the next compression."
    )
]

/// Maintains app-wide state for PulseLab XR.
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

    // Existing lesson navigation kept for compatibility with current project views.
    var lessonPhase: LessonPhase = .welcome

    // Attached trainer flow.
    var phase: AppPhase = .landing
    var videoDidFinish = false
    var currentStep: InstructionStep = .prepareSurface

    // CPR session data.
    var compressionCount = 0
    var compressionBPM: Double = 0
    var handPlacementCorrect = false
    private var compressionTimestamps: [Date] = []

    // Session timer.
    var sessionElapsed: TimeInterval = 0
    var sessionRunning = false
    private var sessionTimer: Timer?

    // Quiz timer.
    var quizElapsed: TimeInterval = 0
    var quizRunning = false
    private var quizTimer: Timer?

    // BPM and audio.
    var targetBPM = 110
    var detectedBPM = 0
    var metronomeEnabled = true
    var metronomeMuted = false
    var metronomeVolume: Float = 0.8
    var audioEnabled = true
    var heartbeatPlaying = false
    private var metronomeTimer: Timer?

    // Quiz state.
    var quizQuestions: [QuizQuestion] = cprQuizQuestions
    var currentQuestionIndex = 0
    var selectedAnswerIndex: Int?
    var wrongAnswers = 0
    var quizAnswered: [Bool?] = Array(repeating: nil, count: cprQuizQuestions.count)
    var isFlatline = false

    // Results.
    var quizScore: Int {
        quizAnswered.compactMap { $0 }.filter { $0 }.count
    }
    var lesson1Completed = false

    var sessionTimeString: String { formatTime(sessionElapsed) }
    var quizTimeString: String { formatTime(quizElapsed) }
    var bpmDelta: Int { detectedBPM - targetBPM }

    var currentQuestion: QuizQuestion? {
        guard quizQuestions.indices.contains(currentQuestionIndex) else { return nil }
        return quizQuestions[currentQuestionIndex]
    }

    func startVideo() {
        phase = .watchingVideo
    }

    func skipVideo() {
        videoDidFinish = true
        phase = .instructions
        startSession()
    }

    func videoFinished() {
        videoDidFinish = true
        phase = .instructions
        startSession()
    }

    func replayVideo() {
        videoDidFinish = false
        phase = .watchingVideo
    }

    func nextInstruction() {
        let steps = InstructionStep.allCases
        guard let index = steps.firstIndex(of: currentStep), index + 1 < steps.count else {
            currentStep = .complete
            return
        }

        currentStep = steps[index + 1]
        if currentStep == .compressions {
            startMetronome()
        }
    }

    func previousInstruction() {
        let steps = InstructionStep.allCases
        guard let index = steps.firstIndex(of: currentStep), index > 0 else { return }
        currentStep = steps[index - 1]
        if currentStep != .compressions {
            stopMetronome()
        }
    }

    func startQuiz() {
        phase = .quiz
        currentQuestionIndex = 0
        selectedAnswerIndex = nil
        wrongAnswers = 0
        isFlatline = false
        quizAnswered = Array(repeating: nil, count: quizQuestions.count)
        stopMetronome()
        stopHeartbeat()
        startQuizTimer()
    }

    func submitAnswer(_ index: Int) {
        guard let question = currentQuestion, selectedAnswerIndex == nil else { return }
        selectedAnswerIndex = index
        let correct = index == question.correctIndex
        quizAnswered[currentQuestionIndex] = correct

        if !correct {
            wrongAnswers += 1
            if wrongAnswers >= 3 {
                isFlatline = true
                detectedBPM = 0
            }
        }
    }

    func nextQuestion() {
        selectedAnswerIndex = nil
        if currentQuestionIndex + 1 < quizQuestions.count {
            currentQuestionIndex += 1
        } else {
            phase = .quizResults
            lesson1Completed = quizScore >= 4
            stopQuizTimer()
        }
    }

    func restartFromQuiz() {
        phase = .instructions
        currentStep = .prepareSurface
        currentQuestionIndex = 0
        selectedAnswerIndex = nil
        wrongAnswers = 0
        isFlatline = false
        quizAnswered = Array(repeating: nil, count: quizQuestions.count)
        detectedBPM = Int(compressionBPM.rounded())
        stopQuizTimer()
        startSession()
    }

    func recordCompression() {
        let now = Date()
        compressionTimestamps.append(now)
        compressionCount += 1

        if compressionTimestamps.count > 8 {
            compressionTimestamps.removeFirst()
        }

        if compressionTimestamps.count >= 2 {
            let intervals = zip(compressionTimestamps, compressionTimestamps.dropFirst())
                .map { $1.timeIntervalSince($0) }
            let average = intervals.reduce(0, +) / Double(intervals.count)
            compressionBPM = average > 0 ? 60.0 / average : 0
            detectedBPM = Int(compressionBPM.rounded())
        }
    }

    func resetCPRSession() {
        compressionCount = 0
        compressionBPM = 0
        detectedBPM = 0
        compressionTimestamps = []
        handPlacementCorrect = false
    }

    func updateDetectedBPM(_ bpm: Int) {
        detectedBPM = bpm
        compressionBPM = Double(bpm)
    }

    func startSession() {
        guard !sessionRunning else { return }
        sessionRunning = true
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.sessionElapsed += 1
            }
        }
    }

    func stopSession() {
        sessionRunning = false
        sessionTimer?.invalidate()
        sessionTimer = nil
    }

    func resetSession() {
        stopSession()
        sessionElapsed = 0
    }

    private func startQuizTimer() {
        stopQuizTimer()
        quizRunning = true
        quizElapsed = 0
        quizTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.quizElapsed += 1
            }
        }
    }

    private func stopQuizTimer() {
        quizRunning = false
        quizTimer?.invalidate()
        quizTimer = nil
    }

    func startMetronome() {
        guard metronomeEnabled else { return }
        stopMetronome()
        let interval = 60.0 / Double(targetBPM)
        metronomeTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.playBeat()
            }
        }
    }

    func stopMetronome() {
        metronomeTimer?.invalidate()
        metronomeTimer = nil
    }

    func toggleMute() {
        metronomeMuted.toggle()
    }

    func setVolume(_ volume: Float) {
        metronomeVolume = volume
    }

    func toggleHeartbeat() {
        heartbeatPlaying.toggle()
        if heartbeatPlaying {
            AudioServicesHelper.startHeartbeat(bpm: targetBPM)
        } else {
            stopHeartbeat()
        }
    }

    private func stopHeartbeat() {
        heartbeatPlaying = false
        AudioServicesHelper.stopHeartbeat()
    }

    private func playBeat() {
        guard !metronomeMuted, audioEnabled else { return }
        AudioServicesHelper.playTick()
    }

    var rhythmFeedback: String {
        guard compressionCount >= 2 || detectedBPM > 0 else { return "Place hands on chest target and begin" }
        if detectedBPM < 100 { return "Too slow - push faster" }
        if detectedBPM > 120 { return "Too fast - slow down" }
        return "Good rhythm - keep going"
    }

    var rhythmColor: Color {
        guard compressionCount >= 2 || detectedBPM > 0 else { return .white }
        if detectedBPM < 100 { return .orange }
        if detectedBPM > 120 { return .red }
        return .green
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

enum AudioServicesHelper {
    private static var heartbeatTimer: Timer?

    static func playTick() {
        AudioServicesPlaySystemSound(1104)
    }

    static func startHeartbeat(bpm: Int) {
        heartbeatTimer?.invalidate()
        let interval = 60.0 / Double(bpm)
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            AudioServicesPlaySystemSound(1016)
        }
    }

    static func stopHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
    }
}
