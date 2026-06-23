//
//  ImmersiveView.swift
//  AVPGroupApp
//
//  Created by brad wils on 23/6/26.
//

import SwiftUI
import RealityKit
import RealityKitContent
import ARKit
import AVFoundation

struct ImmersiveView: View {
    @Environment(AppModel.self) private var appModel

    @State private var rootEntity = Entity()
    @State private var torsoEntity = Entity()
    @State private var heartEntity = Entity()
    @State private var leftHandIndicator = Entity()
    @State private var rightHandIndicator = Entity()

    @State private var arSession = ARKitSession()
    @State private var handTracking = HandTrackingProvider()
    @State private var compressionTimes: [Date] = []
    @State private var isCompressing = false

    @State private var audioEngine = AVAudioEngine()
    @State private var metronomeNode = AVAudioPlayerNode()
    @State private var metronomeBuffer: AVAudioPCMBuffer?
    @State private var metronomeScheduled = false

    var body: some View {
        RealityView { content in
            if let immersiveContentEntity = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
                rootEntity.addChild(immersiveContentEntity)
            }

            content.add(rootEntity)
            buildTorso()
            buildHandIndicators()
            setupSpatialAudio()
        } update: { _ in
            updateHeartMaterial()

            if appModel.phase == .instructions && appModel.currentStep == .compressions {
                scheduleMetronomeIfNeeded()
            }
        }
        .task { await startHandTracking() }
        .task { await processHandUpdates() }
    }

    private func buildTorso() {
        let torsoMesh = MeshResource.generateBox(width: 0.35, height: 0.55, depth: 0.18, cornerRadius: 0.06)
        var torsoMaterial = PhysicallyBasedMaterial()
        torsoMaterial.baseColor = .init(tint: UIColor(white: 0.85, alpha: 0.25))
        torsoMaterial.roughness = .init(floatLiteral: 0.8)
        torsoMaterial.blending = .transparent(opacity: .init(floatLiteral: 0.3))

        torsoEntity = ModelEntity(mesh: torsoMesh, materials: [torsoMaterial])
        torsoEntity.position = SIMD3(0, -0.5, -1.5)
        torsoEntity.orientation = simd_quatf(angle: .pi / 2, axis: SIMD3<Float>(1, 0, 0))
        rootEntity.addChild(torsoEntity)

        let headMesh = MeshResource.generateSphere(radius: 0.12)
        var headMaterial = PhysicallyBasedMaterial()
        headMaterial.baseColor = .init(tint: UIColor(white: 0.85, alpha: 0.25))
        headMaterial.blending = .transparent(opacity: .init(floatLiteral: 0.3))
        let headEntity = ModelEntity(mesh: headMesh, materials: [headMaterial])
        headEntity.position = SIMD3<Float>(0, 0.38, 0)
        torsoEntity.addChild(headEntity)

        let heartMesh = MeshResource.generateSphere(radius: 0.06)
        var heartMaterial = PhysicallyBasedMaterial()
        heartMaterial.baseColor = .init(tint: .red)
        heartMaterial.emissiveColor = .init(color: .red)
        heartMaterial.emissiveIntensity = 3.0
        heartEntity = ModelEntity(mesh: heartMesh, materials: [heartMaterial])
        heartEntity.position = SIMD3<Float>(0, 0.05, 0.1)
        torsoEntity.addChild(heartEntity)

        let guideMesh = MeshResource.generateCylinder(height: 0.005, radius: 0.07)
        let guideMaterial = UnlitMaterial(color: UIColor.systemRed.withAlphaComponent(0.4))
        let guideEntity = ModelEntity(mesh: guideMesh, materials: [guideMaterial])
        guideEntity.position = SIMD3<Float>(0, 0.06, 0.1)
        torsoEntity.addChild(guideEntity)

        buildArms()
    }

    private func buildArms() {
        let armMesh = MeshResource.generateBox(width: 0.08, height: 0.40, depth: 0.07, cornerRadius: 0.04)
        var armMaterial = PhysicallyBasedMaterial()
        armMaterial.baseColor = .init(tint: UIColor(white: 0.85, alpha: 0.2))
        armMaterial.blending = .transparent(opacity: .init(floatLiteral: 0.2))

        let leftArm = ModelEntity(mesh: armMesh, materials: [armMaterial])
        leftArm.position = SIMD3<Float>(-0.22, 0, 0)
        torsoEntity.addChild(leftArm)

        let rightArm = ModelEntity(mesh: armMesh, materials: [armMaterial])
        rightArm.position = SIMD3<Float>(0.22, 0, 0)
        torsoEntity.addChild(rightArm)
    }

    private func buildHandIndicators() {
        let handMesh = MeshResource.generateSphere(radius: 0.025)

        var leftMaterial = PhysicallyBasedMaterial()
        leftMaterial.baseColor = .init(tint: .systemBlue)
        leftMaterial.emissiveColor = .init(color: .blue)
        leftMaterial.emissiveIntensity = 2.0
        leftHandIndicator = ModelEntity(mesh: handMesh, materials: [leftMaterial])
        leftHandIndicator.isEnabled = false
        rootEntity.addChild(leftHandIndicator)

        var rightMaterial = PhysicallyBasedMaterial()
        rightMaterial.baseColor = .init(tint: .systemGreen)
        rightMaterial.emissiveColor = .init(color: .green)
        rightMaterial.emissiveIntensity = 2.0
        rightHandIndicator = ModelEntity(mesh: handMesh, materials: [rightMaterial])
        rightHandIndicator.isEnabled = false
        rootEntity.addChild(rightHandIndicator)
    }

    private func startHandTracking() async {
        guard HandTrackingProvider.isSupported else {
            await simulateBPMForPreview()
            return
        }

        do {
            try await arSession.run([handTracking])
        } catch {
            print("Hand tracking failed: \(error)")
        }
    }

    private func processHandUpdates() async {
        guard HandTrackingProvider.isSupported else { return }

        for await update in handTracking.anchorUpdates {
            let anchor = update.anchor
            guard anchor.isTracked, let handSkeleton = anchor.handSkeleton else { continue }
            guard let wrist = handSkeleton.joint(.wrist) else { continue }

            let transform = anchor.originFromAnchorTransform * wrist.anchorFromJointTransform
            let position = SIMD3<Float>(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)

            await MainActor.run {
                if anchor.chirality == .left {
                    leftHandIndicator.position = position
                    leftHandIndicator.isEnabled = true
                } else {
                    rightHandIndicator.position = position
                    rightHandIndicator.isEnabled = true
                    detectCompression(handY: position.y)
                }
            }
        }
    }

    @MainActor
    private func detectCompression(handY: Float) {
        let sternumY: Float = torsoEntity.position.y + 0.05
        let depth = sternumY - handY
        let compressionThreshold: Float = 0.04

        if depth > compressionThreshold && !isCompressing {
            isCompressing = true
        } else if depth < 0.01 && isCompressing {
            isCompressing = false
            compressionTimes.append(Date())
            appModel.recordCompression()
            computeBPM()
        }
    }

    @MainActor
    private func computeBPM() {
        let cutoff = Date().addingTimeInterval(-10)
        compressionTimes = compressionTimes.filter { $0 > cutoff }
        guard compressionTimes.count >= 2 else { return }

        let intervals = zip(compressionTimes, compressionTimes.dropFirst()).map { $1.timeIntervalSince($0) }
        let averageInterval = intervals.reduce(0, +) / Double(intervals.count)
        let bpm = Int((60.0 / averageInterval).rounded())
        appModel.updateDetectedBPM(bpm)
    }

    private func simulateBPMForPreview() async {
        try? await Task.sleep(for: .seconds(2))
        var simulatedBPM = 96

        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(1))
            simulatedBPM = min(simulatedBPM + 2, 112)
            await MainActor.run { appModel.updateDetectedBPM(simulatedBPM) }
        }
    }

    @MainActor
    private func updateHeartMaterial() {
        guard let model = heartEntity as? ModelEntity else { return }
        let bpm = appModel.detectedBPM
        var material = PhysicallyBasedMaterial()

        if appModel.isFlatline {
            material.baseColor = .init(tint: .gray)
            material.emissiveColor = .init(color: .gray)
            material.emissiveIntensity = 0.5
        } else if bpm >= 100 && bpm <= 120 {
            material.baseColor = .init(tint: .green)
            material.emissiveColor = .init(color: .green)
            material.emissiveIntensity = 4.0
        } else {
            material.baseColor = .init(tint: .red)
            material.emissiveColor = .init(color: .red)
            material.emissiveIntensity = 3.0
        }

        model.model?.materials = [material]
    }

    private func setupSpatialAudio() {
        audioEngine.attach(metronomeNode)
        audioEngine.connect(metronomeNode, to: audioEngine.mainMixerNode, format: nil)

        do {
            try audioEngine.start()
        } catch {
            print("Audio engine start error: \(error)")
        }

        metronomeBuffer = makeTick(sampleRate: 44_100)
    }

    private func scheduleMetronomeIfNeeded() {
        guard !metronomeScheduled, !appModel.metronomeMuted, let buffer = metronomeBuffer else { return }
        metronomeScheduled = true

        let interval = 60.0 / Double(appModel.targetBPM)

        func scheduleNext() {
            guard !Task.isCancelled else { return }
            metronomeNode.scheduleBuffer(buffer, at: nil, options: []) {
                DispatchQueue.main.asyncAfter(deadline: .now() + max(interval - 0.05, 0.05)) {
                    if !appModel.metronomeMuted {
                        scheduleNext()
                    } else {
                        metronomeScheduled = false
                    }
                }
            }

            if !metronomeNode.isPlaying {
                metronomeNode.play()
            }
        }

        scheduleNext()
    }

    private func makeTick(sampleRate: Double) -> AVAudioPCMBuffer? {
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else { return nil }
        let frameCount = AVAudioFrameCount(2048)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }

        buffer.frameLength = frameCount
        guard let data = buffer.floatChannelData?[0] else { return nil }

        for index in 0..<Int(frameCount) {
            let time = Double(index) / sampleRate
            let envelope = exp(-time * 80)
            data[index] = Float(sin(2 * .pi * 1000 * time) * envelope * Double(appModel.metronomeVolume))
        }

        return buffer
    }
}

#Preview(immersionStyle: .full) {
    ImmersiveView()
        .environment(AppModel())
}
