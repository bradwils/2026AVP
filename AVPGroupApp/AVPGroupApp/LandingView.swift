import SwiftUI

struct LandingView: View {

    @Environment(AppModel.self) private var appModel

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.07, blue: 0.18),
                         Color(red: 0.08, green: 0.12, blue: 0.28)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {

                // Header
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
                    .frame(width: 400)

                // Feature bullets
                VStack(alignment: .leading, spacing: 16) {
                    FeatureBullet(icon: "video.fill",       text: "Watch an instructional CPR video")
                    FeatureBullet(icon: "figure.stand",     text: "Practise on a 3D human torso")
                    FeatureBullet(icon: "waveform.path.ecg",text: "Real-time BPM feedback at 100–120 bpm")
                    FeatureBullet(icon: "music.note",       text: "Audio metronome at the correct rate")
                    FeatureBullet(icon: "checkmark.circle", text: "Test your knowledge with a quiz")
                }
                .padding(.horizontal, 60)

                // CTA
                Button {
                    appModel.startVideo()
                } label: {
                    Label("Watch Intro Video", systemImage: "play.circle.fill")
                        .font(.title2.bold())
                        .padding(.horizontal, 40)
                        .padding(.vertical, 18)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .controlSize(.large)
                .glassBackgroundEffect()
            }
            .padding(60)
        }
        .frame(minWidth: 700, minHeight: 600)
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
