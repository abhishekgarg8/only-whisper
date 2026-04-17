//
//  AudioDevice.swift
//  Typewriter
//
//  Audio input device representation
//

import Foundation
import AVFoundation

struct AudioDevice: Identifiable, Hashable {
    let id: String
    let name: String
    let isDefault: Bool

    static var defaultDevice: AudioDevice {
        AudioDevice(id: "default", name: "Default Microphone", isDefault: true)
    }
}
