// ABOUTME: First-run onboarding wizard for PhrasePerfect
// ABOUTME: Guides user through model selection and download from HuggingFace

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var downloader = ModelDownloader()
    @State private var selectedModel: RecommendedModel?
    @State private var currentStep: OnboardingStep = .welcome
    let onComplete: () -> Void

    enum OnboardingStep {
        case welcome
        case selectModel
        case downloading
        case complete
        case manual
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header (compact for some steps)
            if currentStep != .downloading {
                headerView
                    .padding(.bottom, 16)
            }

            // Content
            Group {
                switch currentStep {
                case .welcome:
                    welcomeStep
                case .selectModel:
                    selectModelStep
                case .downloading:
                    downloadingStep
                case .complete:
                    completeStep
                case .manual:
                    manualStep
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Footer
            footerView
                .padding(.top, 16)
        }
        .padding(24)
        .frame(width: 550, height: 480)
        .background(Color(NSColor.windowBackgroundColor))
    }

    private var headerView: some View {
        VStack(spacing: 8) {
            Image(systemName: "text.bubble.fill")
                .font(.system(size: 40))
                .foregroundColor(.accentColor)

            Text("PhrasePerfect")
                .font(.title2)
                .fontWeight(.bold)
        }
    }

    private var welcomeStep: some View {
        VStack(spacing: 16) {
            Text("AI-powered Italian to English translator")
                .font(.headline)
                .foregroundColor(.secondary)

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                FeatureRow(
                    icon: "globe",
                    title: "Local & Private",
                    description: "Runs entirely on your Mac. No API keys needed."
                )

                FeatureRow(
                    icon: "bolt.fill",
                    title: "Fast Translations",
                    description: "Professional, casual, and technical versions."
                )

                FeatureRow(
                    icon: "keyboard",
                    title: "Always Available",
                    description: "Press Option + Space from any app."
                )
            }
            .padding(.horizontal)

            Spacer()

            Text("Download a language model to get started (~1.5-5 GB)")
                .font(.callout)
                .foregroundColor(.secondary)
        }
    }

    private var selectModelStep: some View {
        VStack(spacing: 12) {
            Text("Choose a Model")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Select based on your Mac's RAM")
                .font(.caption)
                .foregroundColor(.secondary)

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(RecommendedModel.models) { model in
                        ModelCard(
                            model: model,
                            isSelected: selectedModel?.id == model.id,
                            onSelect: { selectedModel = model }
                        )
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }

    private var downloadingStep: some View {
        VStack(spacing: 20) {
            // Compact header for download step
            VStack(spacing: 8) {
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 36))
                    .foregroundColor(.accentColor)

                if let model = selectedModel {
                    Text("Downloading \(model.name)")
                        .font(.headline)
                }
            }

            VStack(spacing: 12) {
                ProgressView(value: downloader.progress)
                    .progressViewStyle(.linear)

                // Show detailed progress info
                VStack(spacing: 4) {
                    if !downloader.currentFileName.isEmpty {
                        Text(downloader.currentFileName)
                            .font(.caption)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }

                    HStack {
                        Text(downloader.formattedProgress)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                        Spacer()
                        Text("\(Int(downloader.progress * 100))%")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.accentColor)
                            .monospacedDigit()
                    }
                }
            }
            .padding(.horizontal, 30)

            if let error = downloader.error {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(6)
                    .padding(.horizontal, 30)
            }

            Spacer()

            Text("This may take a few minutes...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .onAppear {
            guard let model = selectedModel else { return }
            Task {
                await downloader.downloadModel(model)
                if let path = downloader.downloadedPath {
                    appState.modelPath = path
                    currentStep = .complete
                }
            }
        }
    }

    private var completeStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.green)

            Text("Ready to Go!")
                .font(.title2)
                .fontWeight(.bold)

            Divider()
                .padding(.vertical, 8)

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "keyboard")
                        .foregroundColor(.accentColor)
                        .frame(width: 20)
                    Text("Press **Option + Space** to translate")
                        .font(.callout)
                }

                HStack(spacing: 8) {
                    Image(systemName: "cursorarrow.click.2")
                        .foregroundColor(.accentColor)
                        .frame(width: 20)
                    Text("Right-click menu bar icon for settings")
                        .font(.callout)
                }
            }
            .padding(.horizontal, 20)

            Spacer()
        }
    }

    private var manualStep: some View {
        VStack(spacing: 12) {
            Text("Manual Setup")
                .font(.title3)
                .fontWeight(.semibold)

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("**Option 1:** Terminal download")
                        .font(.subheadline)

                    Text("pip install huggingface-hub\nhuggingface-cli download mlx-community/gemma-2-2b-it-4bit --local-dir ~/Models/gemma")
                        .font(.system(.caption2, design: .monospaced))
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(6)

                    Divider()

                    Text("**Option 2:** Browse for model folder")
                        .font(.subheadline)

                    Button("Select Model Folder...") {
                        selectModelFolder()
                    }
                    .buttonStyle(.bordered)

                    if !appState.modelPath.isEmpty {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Model selected")
                                .font(.caption)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var footerView: some View {
        HStack {
            switch currentStep {
            case .welcome:
                Button("Manual setup") {
                    currentStep = .manual
                }
                .buttonStyle(.borderless)
                .font(.caption)

                Spacer()

                Button("Get Started") {
                    currentStep = .selectModel
                }
                .buttonStyle(.borderedProminent)

            case .selectModel:
                Button("Back") {
                    currentStep = .welcome
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Download") {
                    guard selectedModel != nil else { return }
                    currentStep = .downloading
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedModel == nil)

            case .downloading:
                Spacer()

                Button("Cancel") {
                    downloader.cancelDownload()
                    currentStep = .selectModel
                }
                .buttonStyle(.bordered)

            case .complete:
                Spacer()

                Button("Start Translating") {
                    onComplete()
                }
                .buttonStyle(.borderedProminent)

            case .manual:
                Button("Back") {
                    currentStep = .welcome
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Done") {
                    if !appState.modelPath.isEmpty {
                        onComplete()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(appState.modelPath.isEmpty)
            }
        }
    }

    private func selectModelFolder() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.message = "Select MLX model folder (must contain config.json)"

        if panel.runModal() == .OK, let url = panel.url {
            let configPath = url.appendingPathComponent("config.json")
            if FileManager.default.fileExists(atPath: configPath.path) {
                appState.modelPath = url.path
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.accentColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct ModelCard: View {
    let model: RecommendedModel
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(model.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    Text(model.description)
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    HStack(spacing: 12) {
                        Label(model.sizeDescription, systemImage: "arrow.down.circle")
                        Label(model.ramRequired + " RAM", systemImage: "memorychip")
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                        .font(.title3)
                }
            }
            .padding(10)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
