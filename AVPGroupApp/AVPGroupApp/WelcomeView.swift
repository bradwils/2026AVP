//
//  WelcomeView.swift
//  AVPGroupApp
//

import SwiftUI

// Reserved for future AppModel-driven full flow. Active welcome screen is in ContentView.swift.
struct PLWelcomeView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        VStack(spacing: 36) {
            Spacer()

            // Logo
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(.red.opacity(0.15))
                        .frame(width: 140, height: 140)
                    Image(systemName: "heart.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 62, height: 62)
                        .foregroundStyle(.red)
                        .symbolEffect(.pulse)
                }

                VStack(spacing: 6) {
                    Text("PulseLab XR")
                        .font(.system(size: 52, weight: .bold))
                        .foregroundStyle(.primary)
                    Text("CPR Pre-Lab Training Simulator")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }

            Text("Build confidence before the lab.\nPractise spatial CPR before your first real mannequin session.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 500)

            // Feature highlights
            HStack(spacing: 14) {
                PillBadge(icon: "figure.stand", label: "3D Patient")
                PillBadge(icon: "hand.raised.fill", label: "Hand Tracking")
                PillBadge(icon: "waveform.path.ecg", label: "Live BPM")
                PillBadge(icon: "graduationcap.fill", label: "Guided Quiz")
            }

            Spacer()

            Text("Educational simulation only — not a substitute for accredited CPR training or clinical certification.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 480)

            Button {
                withAnimation(.easeInOut(duration: 0.4)) {
                    appModel.lessonPhase = .lessonSelection
                }
            } label: {
                Label("Begin Training", systemImage: "arrow.right.circle.fill")
                    .font(.title3.weight(.semibold))
                    .padding(.horizontal, 48)
                    .padding(.vertical, 18)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)

            Spacer()
        }
        .padding()
    }
}

struct PillBadge: View {
    let icon: String
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.red)
            Text(label)
                .font(.caption.weight(.medium))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .glassBackgroundEffect()
    }
}

#Preview(windowStyle: .automatic) {
    PLWelcomeView()
        .environment(AppModel())
}
