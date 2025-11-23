// ABOUTME: Menu bar status item manager for PhrasePerfect
// ABOUTME: Creates and manages the NSStatusItem with icon and menu

import AppKit
import SwiftUI

class StatusBarManager {
    private var statusItem: NSStatusItem?
    private let appState: AppState
    private let toggleCallback: () -> Void
    private let settingsCallback: () -> Void

    init(appState: AppState, toggleCallback: @escaping () -> Void, settingsCallback: @escaping () -> Void) {
        self.appState = appState
        self.toggleCallback = toggleCallback
        self.settingsCallback = settingsCallback
        setupStatusItem()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        guard let button = statusItem?.button else { return }

        // Use SF Symbol for the icon
        if let image = NSImage(systemSymbolName: "text.bubble.fill", accessibilityDescription: "PhrasePerfect") {
            image.isTemplate = true
            button.image = image
        } else {
            button.title = "PP"
        }

        button.action = #selector(statusItemClicked)
        button.target = self
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            toggleCallback()
        }
    }

    private func showContextMenu() {
        let menu = NSMenu()

        menu.addItem(NSMenuItem(title: "Open PhrasePerfect", action: #selector(openApp), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))

        for item in menu.items {
            item.target = self
        }

        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }

    @objc private func openApp() {
        toggleCallback()
    }

    @objc private func openSettings() {
        settingsCallback()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
