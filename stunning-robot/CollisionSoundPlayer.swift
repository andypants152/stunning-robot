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
        setupPlayer()
    }

    func play() {
        guard let player else { return }

        player.currentTime = 0
        player.play()
    }

    private func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? audioSession.setActive(true)
    }

    private func setupPlayer() {
        let soundData = makeCollisionSoundData()
        self.soundData = soundData

        player = try? AVAudioPlayer(data: soundData)
        player?.volume = 1.0
        player?.prepareToPlay()
    }

    private func makeCollisionSoundData() -> Data {
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

        for sampleIndex in 0..<sampleCount {
            let t = Double(sampleIndex) / Double(sampleRate)
            let amplitude = exp(-t * 14.0) * 0.9
            let freq = 700.0 + sin(t * 70.0) * 260.0
            let sample = Int16((amplitude * sin(2.0 * Double.pi * freq * t)) * Double(Int16.max))
            data.appendInt16(sample)
        }

        return data
    }
}

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
