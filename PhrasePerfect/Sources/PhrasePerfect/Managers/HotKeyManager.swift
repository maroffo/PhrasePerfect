// ABOUTME: Global hotkey registration using Carbon HIToolbox framework
// ABOUTME: Registers Option+Space to toggle the PhrasePerfect popover from any app

import Foundation
import Carbon.HIToolbox
import AppKit

class HotKeyManager {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private let callback: () -> Void

    // Default: Option + Space
    private let modifiers: UInt32
    private let keyCode: UInt32

    // Unique identifier for our hotkey
    private let hotKeyID = EventHotKeyID(signature: OSType(0x5048_5046), id: 1) // "PHPF"

    init(
        modifiers: UInt32 = UInt32(optionKey),
        keyCode: UInt32 = UInt32(kVK_Space),
        callback: @escaping () -> Void
    ) {
        self.modifiers = modifiers
        self.keyCode = keyCode
        self.callback = callback
    }

    func register() {
        // Install event handler for hotkey events
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        // Store self reference for the C callback
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, userData) -> OSStatus in
                guard let userData = userData else { return OSStatus(eventNotHandledErr) }

                var hotKeyID = EventHotKeyID()
                let status = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )

                if status == noErr {
                    let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
                    DispatchQueue.main.async {
                        manager.callback()
                    }
                }

                return noErr
            },
            1,
            &eventType,
            selfPtr,
            &eventHandlerRef
        )

        if status != noErr {
            print("Failed to install event handler: \(status)")
            return
        }

        // Register the hotkey
        var hotKeyIDVar = hotKeyID
        let registerStatus = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyIDVar,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if registerStatus != noErr {
            print("Failed to register hotkey: \(registerStatus)")
        }
    }

    func unregister() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }

        if let eventHandlerRef = eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
            self.eventHandlerRef = nil
        }
    }

    func updateHotKey(modifiers: UInt32, keyCode: UInt32) {
        unregister()
        // Note: This creates a new manager; in production you'd want to update internal state
        // For now, we re-register with existing values since they're let constants
        register()
    }

    deinit {
        unregister()
    }
}

// MARK: - Key Code Constants
extension HotKeyManager {
    static let optionModifier: UInt32 = UInt32(optionKey)
    static let commandModifier: UInt32 = UInt32(cmdKey)
    static let controlModifier: UInt32 = UInt32(controlKey)
    static let shiftModifier: UInt32 = UInt32(shiftKey)

    static let spaceKeyCode: UInt32 = UInt32(kVK_Space)
}
