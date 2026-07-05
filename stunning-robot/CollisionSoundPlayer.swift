//
//  CollisionSoundPlayer.swift
//  stunning-robot
//
//  Created by Andy Meyer on 7/4/26.
//
import AVFoundation
import Foundation

final class CollisionSoundPlayer {
    private var player: AVAudioPlayer?
    private var soundData: Data?

    init() {
        setupAudioSession()
    }

    func play(for type: TargetType = .green) {
        // Activate session only when playing, not on init, to respect system audio routing
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
        
        let data = makeSoundData(for: type)
        self.soundData = data
        
        // Keep the player alive for the duration of playback.
        player = try? AVAudioPlayer(data: data)
        player?.volume = 1.0
        player?.prepareToPlay()
        player?.play()
    }

    private func setupAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
    }

    private func makeSoundData(for type: TargetType) -> Data {
        let sampleRate = 44_100
        let duration = 0.18
        let sampleCount = Int(Double(sampleRate) * duration)
        let channelCount = 1
        let bitsPerSample = 16
        let bytesPerSample = bitsPerSample / 8
        let dataSize = sampleCount * channelCount * bytesPerSample

        var data = Data()
        data.appendString("RIFF")
        data.appendUInt32(UInt32(36 + dataSize))
        data.appendString("WAVE")
        data.appendString("fmt ")
        data.appendUInt32(16)
        data.appendUInt16(1)
        data.appendUInt16(UInt16(channelCount))
        data.appendUInt32(UInt32(sampleRate))
        data.appendUInt32(UInt32(sampleRate * channelCount * bytesPerSample))
        data.appendUInt16(UInt16(channelCount * bytesPerSample))
        data.appendUInt16(UInt16(bitsPerSample))
        data.appendString("data")
        data.appendUInt32(UInt32(dataSize))

        let (baseFreq, modRate, modDepth, decayRate) = audioParams(for: type)

        for sampleIndex in 0..<sampleCount {
            let t = Double(sampleIndex) / Double(sampleRate)
            let amplitude = exp(-t * decayRate) * 0.9
            let freq = baseFreq + sin(t * modRate) * modDepth
            let sample = Int16((amplitude * sin(2.0 * Double.pi * freq * t)) * Double(Int16.max))
            data.appendInt16(sample)
        }

        return data
    }

    private func audioParams(for type: TargetType) -> (baseFreq: Double, modRate: Double, modDepth: Double, decayRate: Double) {
        switch type {
        case .green:  return (700.0, 70.0, 260.0, 14.0)
        case .blue:   return (880.0, 90.0, 180.0, 12.0)
        case .red:    return (320.0, 40.0, 120.0, 18.0)
        case .purple: return (1200.0, 110.0, 350.0, 10.0)
        case .yellow: return (550.0, 60.0, 200.0, 16.0)
        }
    }
}

// Keep your existing Data extensions exactly as-is
private extension Data {
    mutating func appendString(_ string: String) {
        append(contentsOf: string.utf8)
    }

    mutating func appendUInt16(_ value: UInt16) {
        var littleEndianValue = value.littleEndian
        append(Data(bytes: &littleEndianValue, count: MemoryLayout<UInt16>.size))
    }

    mutating func appendUInt32(_ value: UInt32) {
        var littleEndianValue = value.littleEndian
        append(Data(bytes: &littleEndianValue, count: MemoryLayout<UInt32>.size))
    }

    mutating func appendInt16(_ value: Int16) {
        var littleEndianValue = value.littleEndian
        append(Data(bytes: &littleEndianValue, count: MemoryLayout<Int16>.size))
    }
}
