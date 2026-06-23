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
            description: "Before you become part of the rescue, scan for hazards. CPR only helps if you can safely stay close enough to deliver continuous compressions.",
            tip: nil),
    CPRStep(number: 2, icon: "hand.tap.fill", color: .orange,
            title: "Check Responsiveness",
            description: "Tap the shoulders and call out clearly. If the person is unresponsive and not breathing normally, the heart may not be moving oxygen-rich blood to the brain.",
            tip: "Do not move the person if a spinal injury is suspected."),
    CPRStep(number: 3, icon: "phone.fill", color: .red,
            title: "Call Emergency Services",
            description: "Call Triple Zero (000) in Australia, or ask a bystander to call and find an AED. CPR buys time by manually circulating blood until advanced help arrives.",
            tip: "Put the call on speaker so you can continue CPR while on the line."),
    CPRStep(number: 4, icon: "person.fill", color: .teal,
            title: "Position the Patient",
            description: "Lay the person flat on a firm surface. A solid surface lets each push drive the sternum downward and compress the heart effectively.",
            tip: nil),
    CPRStep(number: 5, icon: "hand.raised.fill", color: .red,
            title: "Hand Placement",
            description: "Place the heel of one hand on the lower half of the sternum, with the other hand on top. This position directs force through the chest to squeeze the heart between the sternum and spine.",
            tip: "This is the compression target shown in the 3D practice view."),
    CPRStep(number: 6, icon: "arrow.down.circle.fill", color: .red,
            title: "Perform 30 Compressions",
            description: "Push hard and fast, 5 to 6 cm deep at 100-120 per minute. Each downward push sends blood out of the heart; full recoil lets the chest rise so the heart can refill.",
            tip: "Keep arms straight and let the chest fully recoil after every compression."),
    CPRStep(number: 7, icon: "wind", color: .teal,
            title: "Give 2 Rescue Breaths (if trained)",
            description: "Open the airway, pinch the nose, and give 2 breaths of about 1 second each. Watch for chest rise, which shows air is reaching the lungs before compressions resume.",
            tip: "If not trained, continue hands-only CPR without delay."),
    CPRStep(number: 8, icon: "repeat.circle.fill", color: .green,
            title: "Continue the 30:2 Cycle",
            description: "Repeat compressions and breaths with minimal pauses. Consistent rhythm helps maintain blood flow to the brain and vital organs until an AED or emergency team takes over.",
            tip: "Switch rescuers about every 2 minutes to maintain compression quality.")
]

// MARK: - Side-by-Side Layout (Video left, Steps right — shown as a sheet)

struct CPRSideBySideView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            
            HStack {
                Button {
                    dismiss()
                } label: {
                    Label("Back", systemImage: "chevron.left")
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Text("CPR Guide")
                    .font(.headline)
                
                Spacer()
                
                // Giữ layout cân đối vì bên trái có nút Back
                Color.clear
                    .frame(width: 70, height: 1)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            
            Divider()
            
            HStack(spacing: 0) {
                CPRVideoView()
                    .frame(width: 620)
                
                Divider()
                
                CPRStepsView()
                    .frame(width: 380)
            }
        }
        .frame(width: 1000, height: 670)
    }
}

#Preview(windowStyle: .automatic) {
    CPRSideBySideView()
}
