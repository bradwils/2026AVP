//
//  BeepPlayer.swift
//  AVPGroupApp
//
//  Created by brad wils on 23/6/26.
//

import AVFoundation

/// Plays a short synthesized beep tone, used to signal the end of a CPR cycle.
@MainActor
final class BeepPlayer {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let buffer: AVAudioPCMBuffer

    init(frequency: Double = 880, duration: TimeInterval = 0.3, sampleRate: Double = 44_100) {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        let channel = buffer.floatChannelData![0]
        for frame in 0..<Int(frameCount) {
            let value = sin(2.0 * .pi * frequency * Double(frame) / sampleRate)
            channel[frame] = Float(value) * 0.3
        }
        self.buffer = buffer

        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
    }

    func play() {
        do {
            if !engine.isRunning {
                try engine.start()
            }
            player.scheduleBuffer(buffer, at: nil)
            player.play()
        } catch {
            print("BeepPlayer failed to start audio engine: \(error)")
        }
    }
}
