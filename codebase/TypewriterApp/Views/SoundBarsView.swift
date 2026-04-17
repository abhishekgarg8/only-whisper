//
//  SoundBarsView.swift
//  Typewriter
//
//  Animated sound bars visualizer driven by real audio levels
//

import SwiftUI

struct SoundBarsView: View {
    /// Real-time audio level from 0.0 (silence) to 1.0 (peak). Drives bar heights.
    var audioLevel: Float = 0

    @State private var barHeights: [CGFloat] = [0.3, 0.6, 0.4, 0.7, 0.5]
    private let barCount = 5
    // 30fps refresh
    private let timer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.blue)
                    .frame(width: 4)
                    .frame(height: barHeights[index] * 30)
                    .animation(.easeInOut(duration: 0.1), value: barHeights[index])
            }
        }
        .onReceive(timer) { _ in
            animateBars()
        }
    }

    private func animateBars() {
        let level = CGFloat(audioLevel)
        withAnimation {
            for i in 0..<barCount {
                let randomFactor = CGFloat.random(in: 0.5...1.5)
                // When audio is detected use real level; otherwise idle-animate softly
                let driven = level > 0.05
                    ? min(level * randomFactor, 1.0)
                    : CGFloat.random(in: 0.15...0.4)
                barHeights[i] = max(driven, 0.1)
            }
        }
    }
}
