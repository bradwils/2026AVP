//
//  SharedComponents.swift
//  AVPGroupApp
//

import SwiftUI

// MARK: - Progress Step Bar

struct ProgressStepBar: View {
    let currentStep: Int  // 1-based
    let totalSteps: Int
    let labels: [String]

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                ForEach(0..<totalSteps, id: \.self) { i in
                    Capsule()
                        .fill(i < currentStep ? Color.red : Color.white.opacity(0.25))
                        .frame(height: 4)
                }
            }
            HStack {
                Text("Step \(currentStep) of \(totalSteps)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(labels[min(currentStep - 1, labels.count - 1)])
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.red)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Multiple Choice Button (Scenario + Quiz)

struct ChoiceButton: View {
    let label: String
    let index: Int
    let selectedIndex: Int?
    let correctIndex: Int?
    let onTap: () -> Void

    private var bgColor: Color {
        guard let correct = correctIndex, let selected = selectedIndex else {
            return index == selectedIndex ? .blue.opacity(0.2) : .clear
        }
        if index == correct { return .green.opacity(0.2) }
        if index == selected { return .red.opacity(0.2) }
        return .clear
    }

    private var borderColor: Color {
        guard let correct = correctIndex, let selected = selectedIndex else {
            return index == selectedIndex ? .blue : .clear
        }
        if index == correct { return .green }
        if index == selected { return .red }
        return .clear
    }

    private let letters = ["A", "B", "C", "D"]

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Text("\(letters[min(index, letters.count - 1)]).")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 22, alignment: .leading)
                Text(label)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(bgColor, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(borderColor, lineWidth: 1.5))
            .glassBackgroundEffect()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Instruction Row

struct InstructionRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
}

// MARK: - Stat Widget (CPR Practice)

struct StatWidget: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color.opacity(0.8))
            Text(value)
                .font(.system(size: 30, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .glassBackgroundEffect()
    }
}
