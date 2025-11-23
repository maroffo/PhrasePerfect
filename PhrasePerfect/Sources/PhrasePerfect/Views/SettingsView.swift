// ABOUTME: Settings view for configuring model path and hotkey
// ABOUTME: Persists configuration using AppStorage/UserDefaults

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var isSelectingFolder = false
    @State private var modelStatus: ModelStatus = .notLoaded

    enum ModelStatus: Equatable {
        case notLoaded
        case loading
        case loaded
        case error(String)
    }

    var body: some View {
        TabView {
            modelSettingsTab
                .tabItem {
                    Label("Model", systemImage: "cpu")
                }

            hotkeySettingsTab
                .tabItem {
                    Label("Hotkey", systemImage: "keyboard")
                }

            aboutTab
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 450, height: 300)
        .padding()
    }

    private var modelSettingsTab: some View {
        Form {
            Section {
                HStack {
                    TextField("Model Path", text: $appState.modelPath)
                        .textFieldStyle(.roundedBorder)

                    Button("Browse...") {
                        selectModelFolder()
                    }
                }

                HStack {
                    statusIndicator
                    Spacer()
                    Button("Load Model") {
                        loadModel()
                    }
                    .disabled(appState.modelPath.isEmpty || modelStatus == .loading)
                }
            } header: {
                Text("MLX Model Configuration")
            } footer: {
                Text("Select the folder containing your MLX-format Gemma 3 model files (config.json, weights, tokenizer).")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    @ViewBuilder
    private var statusIndicator: some View {
        HStack(spacing: 6) {
            switch modelStatus {
            case .notLoaded:
                Circle()
                    .fill(Color.gray)
                    .frame(width: 8, height: 8)
                Text("Not loaded")
                    .foregroundColor(.secondary)
            case .loading:
                ProgressView()
                    .scaleEffect(0.6)
                Text("Loading...")
                    .foregroundColor(.secondary)
            case .loaded:
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                Text("Model loaded")
                    .foregroundColor(.green)
            case .error(let message):
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                Text(message)
                    .foregroundColor(.red)
                    .lineLimit(1)
            }
        }
        .font(.caption)
    }

    private var hotkeySettingsTab: some View {
        Form {
            Section {
                HStack {
                    Text("Current Hotkey:")
                    Spacer()
                    Text("Option + Space")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(6)
                        .font(.system(.body, design: .monospaced))
                }

                Text("Hotkey customization coming in a future update.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Text("Global Hotkey")
            }
        }
        .formStyle(.grouped)
    }

    private var aboutTab: some View {
        VStack(spacing: 16) {
            Image(systemName: "text.bubble.fill")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)

            Text("PhrasePerfect")
                .font(.title)
                .fontWeight(.bold)

            Text("Version 1.0.0")
                .foregroundColor(.secondary)

            Divider()

            Text("AI-powered Italian to English translator for developers.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            Spacer()

            Text("Powered by MLX Swift")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }

    private func selectModelFolder() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = false
        panel.message = "Select the folder containing your MLX model files"

        if panel.runModal() == .OK, let url = panel.url {
            appState.modelPath = url.path
        }
    }

    private func loadModel() {
        modelStatus = .loading

        Task {
            do {
                try await appState.mlxActor.loadModel(from: appState.modelPath)
                await MainActor.run {
                    modelStatus = .loaded
                }
            } catch {
                await MainActor.run {
                    modelStatus = .error(error.localizedDescription)
                }
            }
        }
    }
}
