//
//  OverlayContentView.swift
//  Typewriter
//
//  Overlay panel content with visual feedback
//

import SwiftUI

struct OverlayContentView: View {
    @Binding var state: OverlayState
    @Binding var audioLevel: Float

    var body: some View {
        Group {
            if state != .hidden {
                overlayContent
            }
        }
    }

    @ViewBuilder
    private var overlayContent: some View {
        HStack(spacing: 12) {
            // Left icon/animation
            if state.showSoundBars {
                SoundBarsView(audioLevel: audioLevel)
                    .frame(width: 30, height: 30)
            } else if state.showSpinner {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(0.7)
            } else if state.showCheckmark {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.green)
            } else if state.showErrorIcon {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.red)
            }

            // Text
            if let text = state.displayText {
                Text(text)
                    .font(.system(size: 14, weight: .medium))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .cornerRadius(25)
        .shadow(radius: 10)
        .transition(.scale.combined(with: .opacity))
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: state)
    }
}
