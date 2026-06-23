//
//  ContentView.swift
//  AVPGroupApp
//
//  Created by brad wils on 23/6/26.
//

import SwiftUI
import AVKit

struct ContentView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace

    var body: some View {
        Group {
            switch appModel.phase {
            case .landing:
                LandingView()
            case .watchingVideo:
                VideoIntroView()
            case .instructions:
                InstructionsRootView()
            case .quiz:
                QuizRootView()
            case .quizResults:
                QuizResultsView()
            }
        }
        .animation(.easeInOut(duration: 0.35), value: appModel.phase)
        .onChange(of: appModel.phase) { _, phase in
            Task { @MainActor in
                switch phase {
                case .instructions, .quiz, .quizResults:
                    guard appModel.immersiveSpaceState == .closed else { return }
                    appModel.immersiveSpaceState = .inTransition
                    switch await openImmersiveSpace(id: appModel.immersiveSpaceID) {
                    case .opened:
                        break
                    case .userCancelled, .error:
                        fallthrough
                    @unknown default:
                        appModel.immersiveSpaceState = .closed
                    }
                case .landing, .watchingVideo:
                    guard appModel.immersiveSpaceState == .open else { return }
                    appModel.immersiveSpaceState = .inTransition
                    await dismissImmersiveSpace()
                }
            }
        }
    }
}

struct LandingView: View {
    @Environment(AppModel.self) private var appModel
    @State private var showGuide = false

    var body: some View {
        ZStack {
            trainerBackground.ignoresSafeArea()

            VStack(spacing: 34) {
                VStack(spacing: 12) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.red)
                        .symbolEffect(.pulse)

                    Text("CPR Trainer")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Spatial First Aid for Apple Vision Pro")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.7))
                }

                Divider()
                    .overlay(Color.white.opacity(0.2))
                    .frame(width: 420)

                VStack(alignment: .leading, spacing: 16) {
                    FeatureBullet(icon: "play.rectangle.fill", text: "Watch the bundled CPR guide video")
                    FeatureBullet(icon: "figure.stand", text: "Practise on a spatial torso target")
                    FeatureBullet(icon: "waveform.path.ecg", text: "Track compression rate at 100-120 BPM")
                    FeatureBullet(icon: "speaker.wave.2.fill", text: "Use a metronome and heartbeat audio guide")
                    FeatureBullet(icon: "checkmark.circle", text: "Complete a CPR knowledge quiz")
                }
                .padding(.horizontal, 60)

                HStack(spacing: 18) {
                    Button {
                        showGuide = true
                    } label: {
                        Label("Open Guide", systemImage: "book.pages.fill")
                            .font(.title3.weight(.semibold))
                            .padding(.horizontal, 30)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.bordered)
                    .tint(.white.opacity(0.7))

                    Button {
                        appModel.startVideo()
                    } label: {
                        Label("Watch Intro Video", systemImage: "play.circle.fill")
                            .font(.title3.weight(.semibold))
                            .padding(.horizontal, 36)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
            }
            .padding(60)
        }
        .frame(minWidth: 700, minHeight: 600)
        .sheet(isPresented: $showGuide) {
            CPRSideBySideView()
        }
    }
}

struct FeatureBullet: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.red)
                .frame(width: 28)
            Text(text)
                .font(.body)
                .foregroundStyle(.white.opacity(0.85))
        }
    }
}

struct VideoIntroView: View {
    @Environment(AppModel.self) private var appModel
    @State private var player = AVPlayer(url: Bundle.main.url(forResource: "CPR_Guide", withExtension: "mp4") ?? URL(fileURLWithPath: "/dev/null"))
    @State private var showCompletion = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if showCompletion {
                completionView
            } else {
                VStack(spacing: 0) {
                    VideoPlayer(player: player)
                        .ignoresSafeArea()

                    HStack {
                        Button {
                            showCompletion = true
                            appModel.videoDidFinish = true
                            player.pause()
                        } label: {
                            Label("Mark Complete", systemImage: "checkmark.circle.fill")
                        }
                        .buttonStyle(.bordered)
                        .tint(.green)

                        Spacer()

                        Button {
                            player.pause()
                            appModel.skipVideo()
                        } label: {
                            Label("Skip Video", systemImage: "forward.end.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    }
                    .padding(24)
                    .background(.regularMaterial)
                }
                .onAppear { player.play() }
            }
        }
    }

    private var completionView: some View {
        ZStack {
            trainerBackground.ignoresSafeArea()

            VStack(spacing: 30) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.green)

                Text("Video Complete")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)

                Text("Ready to practise CPR in the immersive scene?")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.7))

                HStack(spacing: 20) {
                    Button {
                        showCompletion = false
                        appModel.replayVideo()
                        player.seek(to: .zero)
                        player.play()
                    } label: {
                        Label("Replay Video", systemImage: "arrow.counterclockwise")
                            .font(.title3)
                            .padding(.horizontal, 28)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.bordered)
                    .tint(.white.opacity(0.65))

                    Button {
                        player.pause()
                        appModel.videoFinished()
                    } label: {
                        Label("Start Practice", systemImage: "arrow.right.circle.fill")
                            .font(.title3.bold())
                            .padding(.horizontal, 28)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
            }
            .padding(60)
        }
    }
}

var trainerBackground: LinearGradient {
    LinearGradient(
        colors: [Color(red: 0.05, green: 0.07, blue: 0.18),
                 Color(red: 0.08, green: 0.12, blue: 0.28)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

#Preview(windowStyle: .plain) {
    ContentView()
        .environment(AppModel())
}
