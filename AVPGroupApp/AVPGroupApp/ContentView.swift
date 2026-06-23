//
//  ContentView.swift
//  AVPGroupApp
//
//  Created by brad wils on 23/6/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        WelcomeView()
    }
}

struct WelcomeView: View {
    @State private var showGuide = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(.red.opacity(0.15))
                    .frame(width: 120, height: 120)
                Image(systemName: "heart.text.clipboard.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
                    .foregroundStyle(.red)
            }

            // Title
            VStack(spacing: 8) {
                Text("CPR Simulator")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(.primary)

                Text("Pre-Lab Training for Healthcare")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }

            // Description
            Text("Practice life-saving CPR techniques in an immersive environment before entering the real clinical setting.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 480)
                .padding(.horizontal)

            // Feature highlights
            HStack(spacing: 24) {
                Button {
                    showGuide = true
                } label: {
                    FeatureCard(icon: "lungs.fill", color: .blue, title: "Guided Steps", description: "Step-by-step CPR guidance")
                }
                .buttonStyle(.plain)
                .hoverEffect()

                FeatureCard(icon: "waveform.path.ecg", color: .green, title: "Real Feedback", description: "Monitor compression rate")
                FeatureCard(icon: "graduationcap.fill", color: .orange, title: "Training Mode", description: "Safe pre-lab practice")
            }
            .padding(.horizontal)

            Spacer()

            Button {
            } label: {
                Label("Get Started", systemImage: "arrow.right.circle.fill")
                    .font(.title3.weight(.semibold))
                    .padding(.horizontal, 40)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)

            Spacer()
        }
        .padding()
        .sheet(isPresented: $showGuide) {
            CPRSideBySideView()
        }
    }
}

struct FeatureCard: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
                .foregroundStyle(color)

            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)

            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(width: 140)
        .padding()
        .glassBackgroundEffect()
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}
