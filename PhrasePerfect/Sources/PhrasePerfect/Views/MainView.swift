// ABOUTME: Main floating panel view for PhrasePerfect
// ABOUTME: Contains input text area, translate button, and markdown output display

import SwiftUI

struct MainView: View {
    @EnvironmentObject var appState: AppState
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()

            // Content
            VStack(spacing: 16) {
                inputSection
                actionButtons
                outputSection
            }
            .padding()
        }
        .frame(width: 600, height: 500)
        .background(Color(NSColor.windowBackgroundColor))
        .onChange(of: appState.shouldFocusInput) { _, shouldFocus in
            if shouldFocus {
                isInputFocused = true
                appState.shouldFocusInput = false
            }
        }
    }

    private var headerView: some View {
        HStack {
            Image(systemName: "text.bubble.fill")
                .foregroundColor(.accentColor)
            Text("PhrasePerfect")
                .font(.headline)
            Spacer()
            Text("Option + Space")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(4)
        }
        .padding()
    }

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Italian Text", systemImage: "keyboard")
                .font(.subheadline)
                .foregroundColor(.secondary)

            TextEditor(text: $appState.inputText)
                .font(.body)
                .frame(height: 100)
                .padding(8)
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )
                .focused($isInputFocused)
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button(action: {
                Task {
                    await appState.translate()
                }
            }) {
                HStack {
                    if appState.isGenerating {
                        ProgressView()
                            .scaleEffect(0.7)
                            .frame(width: 16, height: 16)
                    } else {
                        Image(systemName: "arrow.right.circle.fill")
                    }
                    Text(appState.isGenerating ? "Translating..." : "Translate")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(appState.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || appState.isGenerating)
            .keyboardShortcut(.return, modifiers: .command)

            Button(action: appState.clearAll) {
                Image(systemName: "trash")
            }
            .buttonStyle(.bordered)
            .disabled(appState.isGenerating)
        }
    }

    private var outputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("English Translation", systemImage: "doc.text")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                if !appState.outputText.isEmpty {
                    Button(action: appState.copyToClipboard) {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.on.doc")
                            Text("Copy")
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if let error = appState.errorMessage {
                        errorView(error)
                    } else if appState.outputText.isEmpty && !appState.isGenerating {
                        placeholderView
                    } else {
                        MarkdownView(text: appState.outputText)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: .infinity)
            .padding(12)
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
            )
        }
    }

    private func errorView(_ error: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            Text(error)
                .foregroundColor(.red)
        }
        .padding()
    }

    private var placeholderView: some View {
        Text("Enter Italian text above and click Translate")
            .foregroundColor(.secondary)
            .italic()
    }
}
