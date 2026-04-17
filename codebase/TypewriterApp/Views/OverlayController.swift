//
//  OverlayController.swift
//  Typewriter
//
//  NSPanel-based overlay window controller
//

import AppKit
import SwiftUI
import Combine

@MainActor
class OverlayController: ObservableObject {
    private var panel: NSPanel?
    private var hostingView: NSHostingView<OverlayContentView>?
    @Published var currentState: OverlayState = .hidden
    @Published var audioLevel: Float = 0

    init() {
        setupPanel()
    }

    private func setupPanel() {
        // Create panel
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 50),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary]
        panel.isMovableByWindowBackground = false
        panel.hasShadow = true

        // Create SwiftUI content with bindings
        let contentView = OverlayContentView(
            state: Binding(
                get: { self.currentState },
                set: { self.currentState = $0 }
            ),
            audioLevel: Binding(
                get: { self.audioLevel },
                set: { self.audioLevel = $0 }
            )
        )
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.frame = panel.contentView!.bounds
        hostingView.autoresizingMask = [.width, .height]

        panel.contentView = hostingView

        self.panel = panel
        self.hostingView = hostingView

        // Position at center of screen
        centerPanel()
    }

    func show(state: OverlayState) {
        currentState = state
        panel?.orderFrontRegardless()
        centerPanel()
    }

    func hide() {
        currentState = .hidden
        panel?.orderOut(nil)
    }

    private func centerPanel() {
        guard let panel = panel,
              let screen = NSScreen.main else { return }

        let screenFrame = screen.visibleFrame
        let panelFrame = panel.frame

        let x = screenFrame.midX - panelFrame.width / 2
        let y = screenFrame.midY - panelFrame.height / 2

        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
