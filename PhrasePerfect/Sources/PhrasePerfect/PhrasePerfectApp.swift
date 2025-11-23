// ABOUTME: Main entry point for PhrasePerfect menu bar application
// ABOUTME: Configures the app as a menu bar utility with no dock icon

import SwiftUI
import AppKit

@main
struct PhrasePerfectApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Empty scene - we manage all windows manually
        Settings {
            EmptyView()
        }
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarManager: StatusBarManager!
    var hotKeyManager: HotKeyManager!
    let appState = AppState()
    var popoverWindow: NSPanel?
    var onboardingWindow: NSWindow?
    var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon (backup in case Info.plist doesn't work)
        NSApp.setActivationPolicy(.accessory)

        // Initialize status bar with both toggle and settings callbacks
        statusBarManager = StatusBarManager(
            appState: appState,
            toggleCallback: { [weak self] in
                self?.togglePopover()
            },
            settingsCallback: { [weak self] in
                self?.showSettings()
            }
        )

        // Initialize global hotkey (Option + Space)
        hotKeyManager = HotKeyManager { [weak self] in
            self?.togglePopover()
        }
        hotKeyManager.register()

        // Show onboarding on first run or if model not configured
        if appState.needsOnboarding {
            showOnboarding()
        } else {
            // Start loading the model asynchronously
            Task {
                await appState.mlxActor.loadModelIfNeeded()
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotKeyManager.unregister()
    }

    // MARK: - Settings

    private func showSettings() {
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let settingsView = SettingsView()
            .environmentObject(appState)

        let hostingView = NSHostingView(rootView: settingsView)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 350),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        window.contentView = hostingView
        window.title = "PhrasePerfect Settings"
        window.center()
        window.isReleasedWhenClosed = false

        settingsWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Onboarding

    private func showOnboarding() {
        if onboardingWindow != nil {
            onboardingWindow?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let onboardingView = OnboardingView { [weak self] in
            self?.completeOnboarding()
        }
        .environmentObject(appState)

        let hostingView = NSHostingView(rootView: onboardingView)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 550, height: 480),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window.contentView = hostingView
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.center()
        window.isReleasedWhenClosed = false

        onboardingWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func completeOnboarding() {
        appState.hasCompletedOnboarding = true
        onboardingWindow?.close()
        onboardingWindow = nil

        // Load the model now that it's configured
        Task {
            try? await appState.mlxActor.loadModel(from: appState.modelPath)
        }
    }

    // MARK: - Main Popover

    private func togglePopover() {
        // If onboarding is showing, don't toggle main window
        if let window = onboardingWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            return
        }

        // If model not configured, show onboarding instead
        if appState.needsOnboarding {
            showOnboarding()
            return
        }

        if let window = popoverWindow, window.isVisible {
            hidePopover()
        } else {
            showPopover()
        }
    }

    private func showPopover() {
        if popoverWindow == nil {
            createPopoverWindow()
        }

        guard let window = popoverWindow else { return }

        // Position near status bar item or center of screen
        if let screenFrame = NSScreen.main?.visibleFrame {
            let windowSize = window.frame.size
            let x = (screenFrame.width - windowSize.width) / 2 + screenFrame.origin.x
            let y = screenFrame.origin.y + screenFrame.height - windowSize.height - 100
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        // Focus the input field
        appState.shouldFocusInput = true
    }

    private func hidePopover() {
        popoverWindow?.orderOut(nil)
    }

    private func createPopoverWindow() {
        let contentView = MainView()
            .environmentObject(appState)

        let hostingView = NSHostingView(rootView: contentView)
        hostingView.frame = NSRect(x: 0, y: 0, width: 600, height: 500)

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
            styleMask: [.titled, .closable, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        panel.contentView = hostingView
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.isMovableByWindowBackground = true
        panel.backgroundColor = NSColor.windowBackgroundColor
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // Close on escape or click outside
        panel.isReleasedWhenClosed = false

        popoverWindow = panel
    }
}
