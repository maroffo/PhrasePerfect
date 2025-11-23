// ABOUTME: Actor for thread-safe MLX model loading and text generation
// ABOUTME: Runs LLM inference off main thread to prevent UI freezing

import Foundation
import MLX
import MLXLLM
import MLXLMCommon

actor MLXActor {
    private var modelContainer: ModelContainer?
    private var isLoading = false

    enum MLXError: LocalizedError {
        case modelNotLoaded
        case modelPathNotSet
        case loadingFailed(String)
        case generationFailed(String)

        var errorDescription: String? {
            switch self {
            case .modelNotLoaded:
                return "Model not loaded. Please check Settings and select a valid model path."
            case .modelPathNotSet:
                return "Model path not configured. Please set the model path in Settings."
            case .loadingFailed(let message):
                return "Failed to load model: \(message)"
            case .generationFailed(let message):
                return "Generation failed: \(message)"
            }
        }
    }

    private let systemPrompt = """
    Act as PhrasePerfect AI, an expert English language assistant for a CTO.
    1. Translate the Italian input into natural, professional English.
    2. Provide 3 versions: "Professional", "Casual/Slack", and "Technical/Dev".
    3. Briefly explain any grammar corrections.
    4. Format the output clearly in Markdown (use headers for the versions, code blocks for technical terms).
    """

    func loadModelIfNeeded() async {
        // Don't load without a path
    }

    func loadModel(from path: String) async throws {
        guard !path.isEmpty else {
            throw MLXError.modelPathNotSet
        }

        guard !isLoading else { return }
        isLoading = true

        defer { isLoading = false }

        let configuration = ModelConfiguration(directory: URL(fileURLWithPath: path))

        modelContainer = try await LLMModelFactory.shared.loadContainer(
            configuration: configuration
        ) { progress in
            // Progress callback - could be used for UI updates
            print("Loading model: \(progress.fractionCompleted * 100)%")
        }
    }

    func generate(input: String, modelPath: String) async throws -> String {
        // Load model if not already loaded
        if modelContainer == nil {
            try await loadModel(from: modelPath)
        }

        guard let container = modelContainer else {
            throw MLXError.modelNotLoaded
        }

        let prompt = buildPrompt(userInput: input)

        let result = try await container.perform { context in
            let input = try await context.processor.prepare(input: .init(prompt: prompt))
            return try MLXLMCommon.generate(
                input: input,
                parameters: .init(temperature: 0.7),
                context: context
            ) { (tokens: [Int]) -> GenerateDisposition in
                // Continue generating
                return .more
            }
        }

        return result.output
    }

    private func buildPrompt(userInput: String) -> String {
        return """
        <start_of_turn>system
        \(systemPrompt)
        <end_of_turn>
        <start_of_turn>user
        \(userInput)
        <end_of_turn>
        <start_of_turn>model
        """
    }

    func isModelLoaded() -> Bool {
        return modelContainer != nil
    }

    func unloadModel() {
        modelContainer = nil
    }
}
