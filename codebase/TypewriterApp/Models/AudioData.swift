//
//  AudioData.swift
//  Typewriter
//
//  Audio recording data container
//

import Foundation

struct AudioData {
    let data: Data
    let duration: TimeInterval
    let format: AudioFormat

    enum AudioFormat: String {
        case m4a = "m4a"
        case wav = "wav"
    }
}
