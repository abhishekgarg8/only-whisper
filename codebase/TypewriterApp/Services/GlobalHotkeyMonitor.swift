//
//  GlobalHotkeyMonitor.swift
//  Typewriter
//
//  System-wide hotkey detection with Push to Talk and Hands-free modes
//

import Foundation
import CoreGraphics
import Carbon

class GlobalHotkeyMonitor {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    // Callbacks for different hotkey events
    var onPushToTalkPressed: (() -> Void)?
    var onPushToTalkReleased: (() -> Void)?
    var onHandsFreePressed: (() -> Void)?

    // Legacy callback
    var onHotkeyPressed: (() -> Void)?

    // Registered hotkeys
    private var pushToTalkHotkeys: [HotkeyConfiguration] = []
    private var handsFreeHotkeys: [HotkeyConfiguration] = []

    // Track which push-to-talk key is being held
    private var activePushToTalkKey: HotkeyConfiguration?

    init() {
        print("🎹 [HotkeyMonitor] Initializing...")
        // Delay setup to ensure we're on the main run loop
        DispatchQueue.main.async {
            self.setupEventTap()
        }
    }

    deinit {
        unregister()
    }

    // MARK: - Public Methods

    func register(pushToTalk: [HotkeyConfiguration], handsFree: [HotkeyConfiguration]) {
        self.pushToTalkHotkeys = pushToTalk.filter { $0.keyCode != 0 }
        self.handsFreeHotkeys = handsFree.filter { $0.keyCode != 0 }

        print("🎹 [HotkeyMonitor] Registered hotkeys:")
        print("   Push-to-talk: \(pushToTalkHotkeys.map { "keyCode=\($0.keyCode), mods=\($0.modifiers)" })")
        print("   Hands-free: \(handsFreeHotkeys.map { "keyCode=\($0.keyCode), mods=\($0.modifiers)" })")
    }

    // Legacy support
    func register(hotkey: HotkeyConfiguration) {
        handsFreeHotkeys = [hotkey]
        print("🎹 [HotkeyMonitor] Registered legacy hotkey: keyCode=\(hotkey.keyCode), mods=\(hotkey.modifiers)")
    }

    func unregister() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap)
            eventTap = nil
        }

        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
            runLoopSource = nil
        }
        print("🎹 [HotkeyMonitor] Unregistered")
    }

    // MARK: - Private Setup

    private func setupEventTap() {
        // Listen for key down, key up, and flags changed (for modifier keys)
        let eventMask = (1 << CGEventType.keyDown.rawValue) |
                       (1 << CGEventType.keyUp.rawValue) |
                       (1 << CGEventType.flagsChanged.rawValue)

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { proxy, type, event, refcon in
                guard let refcon = refcon else { return Unmanaged.passUnretained(event) }

                let monitor = Unmanaged<GlobalHotkeyMonitor>.fromOpaque(refcon).takeUnretainedValue()
                return monitor.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            print("❌ [HotkeyMonitor] Failed to create event tap - accessibility permission may be required")
            return
        }

        eventTap = tap

        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        self.runLoopSource = runLoopSource

        // Use main run loop explicitly
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        print("✅ [HotkeyMonitor] Event tap created and enabled")
    }

    private func handleEvent(
        proxy: CGEventTapProxy,
        type: CGEventType,
        event: CGEvent
    ) -> Unmanaged<CGEvent> {
        let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
        let modifiers = extractModifiers(from: event.flags)

        switch type {
        case .keyDown:
            // Check hands-free hotkeys (toggle mode)
            if let matched = matchingHotkey(keyCode: keyCode, modifiers: modifiers, in: handsFreeHotkeys) {
                print("🎹 [HotkeyMonitor] Hands-free key DOWN detected: \(matched.displayString)")
                DispatchQueue.main.async {
                    self.onHandsFreePressed?()
                    self.onHotkeyPressed?() // Legacy support
                }
                return Unmanaged.passUnretained(event)
            }

            // Check push-to-talk hotkeys (hold mode)
            if let hotkey = matchingHotkey(keyCode: keyCode, modifiers: modifiers, in: pushToTalkHotkeys) {
                if activePushToTalkKey == nil {
                    print("🎹 [HotkeyMonitor] Push-to-talk key DOWN detected: \(hotkey.displayString)")
                    activePushToTalkKey = hotkey
                    DispatchQueue.main.async {
                        self.onPushToTalkPressed?()
                    }
                }
                return Unmanaged.passUnretained(event)
            }

        case .keyUp:
            // Check if releasing push-to-talk key
            if let active = activePushToTalkKey,
               keyCode == active.keyCode {
                print("🎹 [HotkeyMonitor] Push-to-talk key UP detected: \(active.displayString)")
                activePushToTalkKey = nil
                DispatchQueue.main.async {
                    self.onPushToTalkReleased?()
                }
                return Unmanaged.passUnretained(event)
            }

        case .flagsChanged:
            // Handle modifier-only hotkeys (like just pressing Option or Control)
            let isKeyDown = isModifierKeyPressed(keyCode: keyCode, flags: event.flags)

            if isKeyDown {
                // Check hands-free with modifier-only keys
                if matchingModifierOnlyHotkey(keyCode: keyCode, in: handsFreeHotkeys) != nil {
                    print("🎹 [HotkeyMonitor] Hands-free modifier DOWN: keyCode=\(keyCode)")
                    DispatchQueue.main.async {
                        self.onHandsFreePressed?()
                        self.onHotkeyPressed?()
                    }
                    return Unmanaged.passUnretained(event)
                }

                // Check push-to-talk with modifier-only keys
                if let hotkey = matchingModifierOnlyHotkey(keyCode: keyCode, in: pushToTalkHotkeys) {
                    if activePushToTalkKey == nil {
                        print("🎹 [HotkeyMonitor] Push-to-talk modifier DOWN: keyCode=\(keyCode)")
                        activePushToTalkKey = hotkey
                        DispatchQueue.main.async {
                            self.onPushToTalkPressed?()
                        }
                    }
                    return Unmanaged.passUnretained(event)
                }
            } else {
                // Modifier key released
                if let active = activePushToTalkKey,
                   keyCode == active.keyCode {
                    print("🎹 [HotkeyMonitor] Push-to-talk modifier UP: keyCode=\(keyCode)")
                    activePushToTalkKey = nil
                    DispatchQueue.main.async {
                        self.onPushToTalkReleased?()
                    }
                    return Unmanaged.passUnretained(event)
                }
            }

        default:
            break
        }

        return Unmanaged.passUnretained(event)
    }

    // MARK: - Helper Methods

    private func extractModifiers(from flags: CGEventFlags) -> UInt32 {
        var modifiers: UInt32 = 0
        if flags.contains(.maskCommand) { modifiers |= 256 }
        if flags.contains(.maskShift) { modifiers |= 512 }
        if flags.contains(.maskAlternate) { modifiers |= 2048 }
        if flags.contains(.maskControl) { modifiers |= 4096 }
        return modifiers
    }

    private func matchingHotkey(keyCode: UInt16, modifiers: UInt32, in hotkeys: [HotkeyConfiguration]) -> HotkeyConfiguration? {
        return hotkeys.first { hotkey in
            hotkey.keyCode == keyCode && hotkey.modifiers == modifiers
        }
    }

    private func matchingModifierOnlyHotkey(keyCode: UInt16, in hotkeys: [HotkeyConfiguration]) -> HotkeyConfiguration? {
        // For modifier-only hotkeys, just match the keyCode (modifier key itself)
        return hotkeys.first { hotkey in
            hotkey.keyCode == keyCode && isModifierKeyCode(keyCode)
        }
    }

    private func isModifierKeyCode(_ keyCode: UInt16) -> Bool {
        // Modifier key codes: 54-63
        return keyCode >= 54 && keyCode <= 63
    }

    private func isModifierKeyPressed(keyCode: UInt16, flags: CGEventFlags) -> Bool {
        // Check if the specific modifier key is currently pressed
        switch keyCode {
        case 55: return flags.contains(.maskCommand)      // Left Command
        case 54: return flags.contains(.maskCommand)      // Right Command
        case 56: return flags.contains(.maskShift)        // Left Shift
        case 60: return flags.contains(.maskShift)        // Right Shift
        case 58: return flags.contains(.maskAlternate)    // Left Option
        case 61: return flags.contains(.maskAlternate)    // Right Option
        case 59: return flags.contains(.maskControl)      // Left Control
        case 62: return flags.contains(.maskControl)      // Right Control
        case 63: return flags.contains(.maskSecondaryFn)  // Fn
        default: return false
        }
    }
}
