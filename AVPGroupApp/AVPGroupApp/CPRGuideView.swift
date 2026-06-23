//
//  CPRGuideView.swift
//  AVPGroupApp
//

import SwiftUI
import AVKit

// MARK: - Video Window

struct CPRVideoView: View {

    @State private var player: AVPlayer? = {
        guard let url = Bundle.main.url(forResource: "CPR_Guide", withExtension: "mp4") else { return nil }
        return AVPlayer(url: url)
    }()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CPR Instructional Video")
                        .font(.title2.weight(.bold))
                    Text("Adult Basic Life Support")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "play.rectangle.fill")
                    .font(.title)
                    .foregroundStyle(.red)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 14)

            Divider().padding(.horizontal, 24)

            if let player {
                VideoPlayer(player: player)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(24)
            } else {
                VideoPlaceholder()
                    .padding(24)
            }

            Spacer()
        }
    }
}

// MARK: - Steps Window

struct CPRStepsView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Step-by-Step Script")
                        .font(.title2.weight(.bold))
                    Text("Follow along while watching")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "list.number")
                    .font(.title)
                    .foregroundStyle(.red)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 14)

            Divider().padding(.horizontal, 24)

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(cprSteps) { step in
                        CPRStepCard(step: step)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
    }
}

// MARK: - Video Placeholder

struct VideoPlaceholder: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(LinearGradient(
                    colors: [Color.red.opacity(0.25), Color.black.opacity(0.4)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
            VStack(spacing: 12) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.white.opacity(0.8))
                Text("CPR Instructional Video")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("Add CPR_Guide.mp4 to the project bundle")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 280)
    }
}

// MARK: - Step Card

struct CPRStepCard: View {
    let step: CPRStep

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(step.color.opacity(0.2))
                    .frame(width: 40, height: 40)
                Text("\(step.number)")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(step.color)
            }

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Image(systemName: step.icon)
                        .font(.subheadline)
                        .foregroundStyle(step.color)
                    Text(step.title)
                        .font(.headline)
                }
                Text(step.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if let tip = step.tip {
                    Label(tip, systemImage: "lightbulb.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .padding(.top, 2)
                }
            }

            Spacer()
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .glassBackgroundEffect()
    }
}

// MARK: - Data

struct CPRStep: Identifiable {
    let id = UUID()
    let number: Int
    let icon: String
    let color: Color
    let title: String
    let description: String
    let tip: String?
}

let cprSteps: [CPRStep] = [
    CPRStep(number: 1, icon: "eye.fill", color: .blue,
            title: "Ensure Scene Safety",
            description: "Check that the environment is safe for both you and the patient. Look for hazards such as traffic, electricity, or unstable structures.",
            tip: nil),
    CPRStep(number: 2, icon: "hand.tap.fill", color: .orange,
            title: "Check Responsiveness",
            description: "Tap the person's shoulders firmly and shout 'Are you okay?' If no response, act immediately.",
            tip: "Do not move the person if a spinal injury is suspected."),
    CPRStep(number: 3, icon: "phone.fill", color: .red,
            title: "Call Emergency Services",
            description: "Call Triple Zero (000) in Australia, or ask a bystander to call while you begin CPR. Ask someone to locate an AED.",
            tip: "Put the call on speaker so you can continue CPR while on the line."),
    CPRStep(number: 4, icon: "person.fill", color: .teal,
            title: "Position the Patient",
            description: "Lay the person flat on their back on a firm, flat surface. Kneel beside their chest.",
            tip: nil),
    CPRStep(number: 5, icon: "hand.raised.fill", color: .red,
            title: "Hand Placement",
            description: "Place the heel of one hand on the lower half of the sternum. Place your other hand on top and interlace your fingers. Keep fingers off the ribs.",
            tip: "This is the compression target shown in the 3D practice view."),
    CPRStep(number: 6, icon: "arrow.down.circle.fill", color: .red,
            title: "Perform 30 Compressions",
            description: "Push down hard and fast — 5 to 6 cm deep at 100–120 per minute. Release fully between each compression. Keep arms straight.",
            tip: "'Stayin' Alive' by Bee Gees is ~100 BPM — a useful rhythm guide."),
    CPRStep(number: 7, icon: "wind", color: .teal,
            title: "Give 2 Rescue Breaths (if trained)",
            description: "Tilt the head back, lift the chin, pinch the nose and give 2 breaths of about 1 second each. Watch for the chest to rise.",
            tip: "If not trained, hands-only CPR is still highly effective."),
    CPRStep(number: 8, icon: "repeat.circle.fill", color: .green,
            title: "Continue the 30:2 Cycle",
            description: "Repeat 30 compressions and 2 breaths without stopping until the AED arrives, EMS takes over, or the patient recovers.",
            tip: "Switch with another bystander every 2 minutes to maintain quality.")
]

// MARK: - Side-by-Side Layout (Video left, Steps right — shown as a sheet)

struct CPRSideBySideView: View {
    var body: some View {
        HStack(spacing: 0) {
            CPRVideoView()
                .frame(width: 620)
            Divider()
            CPRStepsView()
                .frame(width: 380)
        }
        .frame(height: 620)
    }
}

#Preview(windowStyle: .automatic) {
    CPRSideBySideView()
}
