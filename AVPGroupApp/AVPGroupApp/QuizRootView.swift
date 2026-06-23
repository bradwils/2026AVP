import SwiftUI

struct QuizRootView: View {

    @Environment(AppModel.self) private var appModel

    var body: some View {
        ZStack {
            backgroundGradient.ignoresSafeArea()

            HStack(alignment: .top, spacing: 0) {
                // LEFT: Session + quiz timer
                VStack(spacing: 16) {
                    SessionTimerWidget()
                    QuizTimerWidget()
                }
                .frame(width: 200)
                .padding(.leading, 24)

                Spacer()

                // CENTRE: Question card
                QuizQuestionCard()
                    .frame(maxWidth: 560)

                Spacer()

                // RIGHT: BPM (flatlines on 3+ wrong) + controls
                QuizBPMWidget()
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

// MARK: - Question card

struct QuizQuestionCard: View {

    @Environment(AppModel.self) private var appModel

    var body: some View {
        VStack(spacing: 0) {
            // Progress
            quizProgressBar
                .padding(.bottom, 20)

            VStack(spacing: 24) {
                // Question number
                Text("Question \(appModel.currentQuestionIndex + 1) of \(appModel.quizQuestions.count)")
                    .font(.caption.uppercaseSmallCaps())
                    .foregroundStyle(.white.opacity(0.5))

                // Wrong answers warning
                if appModel.wrongAnswers > 0 {
                    HStack(spacing: 8) {
                        ForEach(0..<3) { i in
                            Image(systemName: i < appModel.wrongAnswers ? "heart.slash.fill" : "heart.fill")
                                .foregroundStyle(i < appModel.wrongAnswers ? .red.opacity(0.4) : .red)
                                .font(.title3)
                        }
                    }
                }

                // Question text
                if let question = appModel.currentQuestion {
                    Text(question.question)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 8)

                    // Answer options
                    VStack(spacing: 12) {
                        ForEach(0..<question.options.count, id: \.self) { i in
                            AnswerButton(
                                text: question.options[i],
                                index: i,
                                correctIndex: question.correctIndex,
                                selectedIndex: appModel.selectedAnswerIndex
                            ) {
                                appModel.submitAnswer(i)
                            }
                        }
                    }

                    // Explanation (shown after answer)
                    if let selected = appModel.selectedAnswerIndex {
                        VStack(spacing: 12) {
                            Divider().overlay(Color.white.opacity(0.15))

                            HStack(spacing: 8) {
                                Image(systemName: selected == question.correctIndex ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundStyle(selected == question.correctIndex ? .green : .red)
                                    .font(.title3)
                                Text(selected == question.correctIndex ? "Correct!" : "Incorrect")
                                    .font(.headline)
                                    .foregroundStyle(selected == question.correctIndex ? .green : .red)
                            }

                            Text(question.explanation)
                                .font(.callout)
                                .foregroundStyle(.white.opacity(0.75))
                                .multilineTextAlignment(.center)

                            if appModel.isFlatline {
                                Text("❤️ 3 incorrect answers — the patient has flatlined. Keep practising!")
                                    .font(.callout.bold())
                                    .foregroundStyle(.red)
                                    .multilineTextAlignment(.center)
                            }

                            Button {
                                withAnimation { appModel.nextQuestion() }
                            } label: {
                                Label(
                                    appModel.currentQuestionIndex + 1 < appModel.quizQuestions.count
                                        ? "Next Question" : "See Results",
                                    systemImage: "arrow.right.circle.fill"
                                )
                                .font(.title3.bold())
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(appModel.isFlatline ? .red : .blue)
                        }
                        .padding(.top, 4)
                    }
                }
            }
            .padding(36)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
        }
    }

    private var quizProgressBar: some View {
        let total = appModel.quizQuestions.count
        let current = appModel.currentQuestionIndex

        return HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { i in
                let answered = appModel.quizAnswered[i]
                Capsule()
                    .fill(capsuleColor(index: i, answered: answered, current: current))
                    .frame(height: 4)
                    .animation(.easeInOut, value: current)
            }
        }
        .padding(.horizontal, 8)
    }

    private func capsuleColor(index: Int, answered: Bool?, current: Int) -> Color {
        if let correct = answered {
            return correct ? .green : .red
        }
        return index == current ? .white.opacity(0.7) : .white.opacity(0.2)
    }
}

// MARK: - Answer button

struct AnswerButton: View {

    let text: String
    let index: Int
    let correctIndex: Int
    let selectedIndex: Int?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                // Letter badge
                Text(letterLabel)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(badgeColor, in: Circle())

                Text(text)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.leading)

                Spacer()

                if let sel = selectedIndex {
                    if index == correctIndex {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    } else if index == sel {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .background(backgroundColor, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(borderColor, lineWidth: 1.5)
        )
        .disabled(selectedIndex != nil)
        .animation(.easeInOut(duration: 0.2), value: selectedIndex)
    }

    private var letterLabel: String {
        ["A", "B", "C", "D"][safe: index] ?? "\(index + 1)"
    }

    private var badgeColor: Color {
        guard let sel = selectedIndex else { return .white.opacity(0.2) }
        if index == correctIndex { return .green }
        if index == sel { return .red }
        return .white.opacity(0.1)
    }

    private var backgroundColor: Color {
        guard let sel = selectedIndex else { return .white.opacity(0.06) }
        if index == correctIndex { return .green.opacity(0.12) }
        if index == sel { return .red.opacity(0.12) }
        return .white.opacity(0.03)
    }

    private var borderColor: Color {
        guard let sel = selectedIndex else { return .white.opacity(0.1) }
        if index == correctIndex { return .green.opacity(0.6) }
        if index == sel { return .red.opacity(0.6) }
        return .white.opacity(0.06)
    }
}

// MARK: - Quiz timer widget

struct QuizTimerWidget: View {

    @Environment(AppModel.self) private var appModel

    var body: some View {
        VStack(spacing: 12) {
            Text("Quiz Time")
                .font(.caption.uppercaseSmallCaps())
                .foregroundStyle(.white.opacity(0.6))

            Text(appModel.quizTimeString)
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundStyle(.yellow)
                .contentTransition(.numericText())
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Quiz BPM widget (shows flatline animation when isFlatline)

struct QuizBPMWidget: View {

    @Environment(AppModel.self) private var appModel
    @State private var flatlineOffset: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                Text(appModel.isFlatline ? "FLATLINE" : "Compression Rate")
                    .font(.caption.uppercaseSmallCaps())
                    .foregroundStyle(appModel.isFlatline ? .red : .white.opacity(0.6))

                if appModel.isFlatline {
                    // Flatline ECG animation
                    FlatlineView()
                        .frame(height: 50)
                } else {
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("\(appModel.detectedBPM == 0 ? "--" : "\(appModel.detectedBPM)")")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(bpmColor)
                            .contentTransition(.numericText())
                        Text("BPM")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }

                Text("Target: 100–120 BPM")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))

            Spacer().frame(height: 16)

            // Back to instructions button
            Button {
                appModel.restartFromQuiz()
            } label: {
                Label("Back to Practice", systemImage: "arrow.left.circle")
                    .font(.callout)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)

            Spacer().frame(height: 12)

            // Replay video
            Button {
                appModel.replayVideo()
            } label: {
                Label("Replay Video", systemImage: "play.circle")
                    .font(.callout)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.white.opacity(0.5))
        }
    }

    private var bpmColor: Color {
        let bpm = appModel.detectedBPM
        if bpm == 0 { return .white.opacity(0.4) }
        if bpm >= 100 && bpm <= 120 { return .green }
        return .orange
    }
}

// MARK: - Flatline ECG animation

struct FlatlineView: View {

    @State private var animated = false

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.05)) { _ in
            Canvas { context, size in
                let path = flatlinePath(in: size)
                context.stroke(path, with: .color(.red), lineWidth: 2.5)
            }
        }
        .symbolEffect(.pulse)
    }

    private func flatlinePath(in size: CGSize) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: size.height / 2))
        path.addLine(to: CGPoint(x: size.width, y: size.height / 2))
        return path
    }
}

// MARK: - Quiz Results

struct QuizResultsView: View {

    @Environment(AppModel.self) private var appModel

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.07, blue: 0.18),
                         Color(red: 0.08, green: 0.12, blue: 0.28)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 36) {

                // Trophy or sad icon
                Image(systemName: appModel.quizScore >= 4 ? "trophy.fill" : "heart.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(appModel.quizScore >= 4 ? .yellow : .red)
                    .symbolEffect(.bounce)

                Text(appModel.quizScore >= 4 ? "Excellent Work!" : "Keep Practising")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                HStack(spacing: 48) {
                    ScoreStatView(label: "Score", value: "\(appModel.quizScore)/\(appModel.quizQuestions.count)", color: .green)
                    ScoreStatView(label: "Quiz Time", value: appModel.quizTimeString, color: .yellow)
                    ScoreStatView(label: "Session", value: appModel.sessionTimeString, color: .blue)
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 28)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))

                // Per-question breakdown
                VStack(spacing: 8) {
                    ForEach(0..<appModel.quizQuestions.count, id: \.self) { i in
                        let answered = appModel.quizAnswered[i]
                        HStack {
                            Image(systemName: answered == true ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(answered == true ? .green : .red)
                            Text(appModel.quizQuestions[i].question)
                                .font(.callout)
                                .foregroundStyle(.white.opacity(0.75))
                                .lineLimit(1)
                            Spacer()
                        }
                    }
                }
                .padding(24)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
                .frame(maxWidth: 560)

                HStack(spacing: 24) {
                    Button {
                        appModel.startQuiz()
                    } label: {
                        Label("Retry Quiz", systemImage: "arrow.counterclockwise")
                            .font(.title3)
                            .padding(.horizontal, 28)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.bordered)
                    .tint(.white.opacity(0.6))

                    Button {
                        appModel.restartFromQuiz()
                    } label: {
                        Label("Back to Practice", systemImage: "arrow.left.circle.fill")
                            .font(.title3.bold())
                            .padding(.horizontal, 28)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                }
            }
            .padding(60)
        }
    }
}

struct ScoreStatView: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.caption.uppercaseSmallCaps())
                .foregroundStyle(.white.opacity(0.5))
        }
    }
}

// MARK: - Safe array subscript

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
