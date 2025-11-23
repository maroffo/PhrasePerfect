// ABOUTME: Shared application state for PhrasePerfect
// ABOUTME: Observable object containing input/output text and configuration

import Foundation
import SwiftUI

@MainActor
class AppState: ObservableObject {
    @Published var inputText: String = ""
    @Published var outputText: String = ""
    @Published var isGenerating: Bool = false
    @Published var errorMessage: String?
    @Published var shouldFocusInput: Bool = false

    // Settings
    @AppStorage("modelPath") var modelPath: String = ""
    @AppStorage("hotKeyModifiers") var hotKeyModifiers: Int = 0x0800 // Option key
    @AppStorage("hotKeyKeyCode") var hotKeyKeyCode: Int = 49 // Space key
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false

    var needsOnboarding: Bool {
        return !hasCompletedOnboarding || modelPath.isEmpty
    }

    let mlxActor: MLXActor

    init() {
        self.mlxActor = MLXActor()
    }

    func translate() async {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        isGenerating = true
        errorMessage = nil
        outputText = ""

        do {
            let response = try await mlxActor.generate(input: inputText, modelPath: modelPath)
            outputText = response
        } catch {
            errorMessage = error.localizedDescription
        }

        isGenerating = false
    }

    func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(outputText, forType: .string)
    }

    func clearAll() {
        inputText = ""
        outputText = ""
        errorMessage = nil
    }
}
