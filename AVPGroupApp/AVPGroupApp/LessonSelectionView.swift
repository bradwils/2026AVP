//
//  LessonSelectionView.swift
//  AVPGroupApp
//

import SwiftUI

struct LessonSelectionView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        VStack(spacing: 28) {
            VStack(spacing: 6) {
                Text("PULSELAB XR")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .tracking(3)
                    .padding(.top, 32)
                Text("Choose Your Lesson")
                    .font(.system(size: 38, weight: .bold))
            }

            VStack(spacing: 14) {
                LessonCard(
                    number: 1,
                    title: "CPR Foundations",
                    description: "Inspect key anatomy, respond to an emergency scenario, practise compressions, and complete a knowledge quiz.",
                    tags: ["Anatomy", "Scenario", "Practice", "Quiz"],
                    duration: "~8 min",
                    isLocked: false,
                    isCompleted: appModel.lesson1Completed
                ) {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        appModel.lessonPhase = .anatomy
                    }
                }

                LessonCard(
                    number: 2,
                    title: "AED Assistance",
                    description: "Learn how to locate and operate an Automated External Defibrillator during a cardiac emergency.",
                    tags: ["AED", "Defibrillation", "Advanced"],
                    duration: "~10 min",
                    isLocked: true,
                    isCompleted: false
                ) {}
            }
            .padding(.horizontal, 36)

            Spacer()
        }
    }
}

struct LessonCard: View {
    let number: Int
    let title: String
    let description: String
    let tags: [String]
    let duration: String
    let isLocked: Bool
    let isCompleted: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 18) {
                // Badge
                ZStack {
                    Circle()
                        .fill(isLocked ? Color.gray.opacity(0.2) : Color.red.opacity(0.15))
                        .frame(width: 60, height: 60)
                    Group {
                        if isLocked {
                            Image(systemName: "lock.fill")
                                .font(.title2)
                                .foregroundStyle(.gray)
                        } else if isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.green)
                        } else {
                            Text("\(number)")
                                .font(.title.weight(.bold))
                                .foregroundStyle(.red)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Lesson \(number): \(title)")
                            .font(.headline)
                            .foregroundStyle(isLocked ? .secondary : .primary)
                        Spacer()
                        if isLocked {
                            Text("Coming Soon")
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(.gray.opacity(0.25), in: Capsule())
                                .foregroundStyle(.secondary)
                        } else {
                            Label(duration, systemImage: "clock")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 6) {
                        ForEach(tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption2.weight(.medium))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    isLocked ? Color.gray.opacity(0.15) : Color.red.opacity(0.12),
                                    in: Capsule()
                                )
                                .foregroundStyle(isLocked ? Color.gray : Color.red)
                        }
                    }
                }

                if !isLocked {
                    Image(systemName: "chevron.right")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .glassBackgroundEffect()
        }
        .buttonStyle(.plain)
        .disabled(isLocked)
        .opacity(isLocked ? 0.55 : 1.0)
    }
}

#Preview(windowStyle: .automatic) {
    LessonSelectionView()
        .environment(AppModel())
}
