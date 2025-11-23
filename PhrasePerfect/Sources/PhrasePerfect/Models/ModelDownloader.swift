// ABOUTME: Downloads MLX models from HuggingFace Hub
// ABOUTME: Provides progress tracking and file management for model downloads

import Foundation

struct RecommendedModel: Identifiable, Hashable {
    let id: String
    let name: String
    let repoId: String
    let sizeDescription: String
    let sizeBytes: Int64  // Approximate size for progress calculation
    let ramRequired: String
    let description: String

    static let models: [RecommendedModel] = [
        RecommendedModel(
            id: "gemma-2-2b",
            name: "Gemma 2 2B (Recommended)",
            repoId: "mlx-community/gemma-2-2b-it-4bit",
            sizeDescription: "~1.5 GB",
            sizeBytes: 1_600_000_000,
            ramRequired: "8 GB",
            description: "Fast and lightweight. Great for quick translations."
        ),
        RecommendedModel(
            id: "llama-3.2-3b",
            name: "Llama 3.2 3B",
            repoId: "mlx-community/Llama-3.2-3B-Instruct-4bit",
            sizeDescription: "~2 GB",
            sizeBytes: 2_000_000_000,
            ramRequired: "8 GB",
            description: "Good balance of speed and quality."
        ),
        RecommendedModel(
            id: "gemma-2-9b",
            name: "Gemma 2 9B (Best Quality)",
            repoId: "mlx-community/gemma-2-9b-it-4bit",
            sizeDescription: "~5 GB",
            sizeBytes: 5_000_000_000,
            ramRequired: "16 GB",
            description: "Higher quality translations. Requires more RAM."
        ),
    ]
}

struct FileInfo {
    let name: String
    let size: Int64
}

@MainActor
class ModelDownloader: ObservableObject {
    @Published var isDownloading = false
    @Published var progress: Double = 0
    @Published var currentFileName = ""
    @Published var bytesDownloaded: Int64 = 0
    @Published var totalBytes: Int64 = 0
    @Published var statusMessage = ""
    @Published var error: String?
    @Published var downloadedPath: String?

    private var downloadTask: Process?
    private var urlSessionTask: URLSessionDownloadTask?

    static let modelsDirectory: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let modelsDir = appSupport.appendingPathComponent("PhrasePerfect/Models", isDirectory: true)
        try? FileManager.default.createDirectory(at: modelsDir, withIntermediateDirectories: true)
        return modelsDir
    }()

    var formattedProgress: String {
        let downloaded = ByteCountFormatter.string(fromByteCount: bytesDownloaded, countStyle: .file)
        let total = ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
        return "\(downloaded) / \(total)"
    }

    func downloadModel(_ model: RecommendedModel) async {
        isDownloading = true
        progress = 0
        bytesDownloaded = 0
        totalBytes = model.sizeBytes
        error = nil
        statusMessage = "Preparing download..."

        let destinationPath = Self.modelsDirectory.appendingPathComponent(model.id)

        // Check if already downloaded
        if FileManager.default.fileExists(atPath: destinationPath.appendingPathComponent("config.json").path) {
            statusMessage = "Model already downloaded!"
            progress = 1.0
            downloadedPath = destinationPath.path
            isDownloading = false
            return
        }

        // Try huggingface-cli first, fall back to manual download
        if await downloadWithHuggingFaceCLI(model: model, destination: destinationPath) {
            return
        }

        // Fallback: direct API download with byte tracking
        await downloadWithAPI(model: model, destination: destinationPath)
    }

    private func downloadWithHuggingFaceCLI(model: RecommendedModel, destination: URL) async -> Bool {
        statusMessage = "Checking for huggingface-cli..."

        // Check if huggingface-cli is available
        let whichProcess = Process()
        whichProcess.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        whichProcess.arguments = ["huggingface-cli"]
        whichProcess.standardOutput = FileHandle.nullDevice
        whichProcess.standardError = FileHandle.nullDevice

        do {
            try whichProcess.run()
            whichProcess.waitUntilExit()

            if whichProcess.terminationStatus != 0 {
                statusMessage = "huggingface-cli not found, using direct download..."
                return false
            }
        } catch {
            return false
        }

        statusMessage = "Downloading with huggingface-cli..."

        return await withCheckedContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = [
                "huggingface-cli", "download",
                model.repoId,
                "--local-dir", destination.path,
                "--local-dir-use-symlinks", "False"
            ]

            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe

            // Read output for progress updates
            pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
                let data = handle.availableData
                if let output = String(data: data, encoding: .utf8), !output.isEmpty {
                    Task { @MainActor in
                        // Parse progress from huggingface-cli output (looks for XX% pattern)
                        // HF CLI outputs progress like: "Downloading model.safetensors: 45%|..."
                        if let percentMatch = output.range(of: #"(\d+)%"#, options: .regularExpression) {
                            let matched = String(output[percentMatch])
                            let percentStr = matched.replacingOccurrences(of: "%", with: "")
                            if let percent = Double(percentStr) {
                                self?.progress = percent / 100.0
                                self?.bytesDownloaded = Int64(Double(model.sizeBytes) * percent / 100.0)
                            }
                        }

                        // Extract filename being downloaded
                        if let fileMatch = output.range(of: #"Downloading ([^:]+):"#, options: .regularExpression) {
                            let matched = String(output[fileMatch])
                            let filename = matched
                                .replacingOccurrences(of: "Downloading ", with: "")
                                .replacingOccurrences(of: ":", with: "")
                            self?.currentFileName = filename
                            self?.statusMessage = "Downloading \(filename)..."
                        }
                    }
                }
            }

            process.terminationHandler = { [weak self] proc in
                pipe.fileHandleForReading.readabilityHandler = nil

                Task { @MainActor in
                    if proc.terminationStatus == 0 {
                        self?.progress = 1.0
                        self?.bytesDownloaded = model.sizeBytes
                        self?.statusMessage = "Download complete!"
                        self?.downloadedPath = destination.path
                        self?.isDownloading = false
                        continuation.resume(returning: true)
                    } else {
                        continuation.resume(returning: false)
                    }
                }
            }

            do {
                try process.run()
                self.downloadTask = process
            } catch {
                continuation.resume(returning: false)
            }
        }
    }

    private func downloadWithAPI(model: RecommendedModel, destination: URL) async {
        statusMessage = "Fetching file list from HuggingFace..."

        // Get list of files with sizes from HuggingFace API
        let apiURL = URL(string: "https://huggingface.co/api/models/\(model.repoId)")!

        do {
            let (data, _) = try await URLSession.shared.data(from: apiURL)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let siblings = json["siblings"] as? [[String: Any]] else {
                error = "Failed to parse model info from HuggingFace"
                isDownloading = false
                return
            }

            // Get files with their sizes
            var files: [FileInfo] = []
            for sibling in siblings {
                guard let name = sibling["rfilename"] as? String else { continue }
                let size = (sibling["size"] as? Int64) ?? 0

                // Only download essential files
                if name.hasSuffix(".json") || name.hasSuffix(".safetensors") || name == "tokenizer.model" {
                    files.append(FileInfo(name: name, size: size))
                }
            }

            // Calculate total size
            totalBytes = files.reduce(0) { $0 + $1.size }
            if totalBytes == 0 {
                totalBytes = model.sizeBytes // Fallback to estimate
            }
            bytesDownloaded = 0

            try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)

            // Download each file with byte-level progress
            for file in files {
                currentFileName = file.name
                statusMessage = "Downloading \(file.name)..."

                let fileURL = URL(string: "https://huggingface.co/\(model.repoId)/resolve/main/\(file.name)")!
                let destinationFile = destination.appendingPathComponent(file.name)

                // Create subdirectories if needed
                let parentDir = destinationFile.deletingLastPathComponent()
                try FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true)

                // Download with progress tracking
                try await downloadFile(from: fileURL, to: destinationFile, fileSize: file.size)
            }

            progress = 1.0
            statusMessage = "Download complete!"
            downloadedPath = destination.path
            isDownloading = false

        } catch {
            self.error = "Download failed: \(error.localizedDescription)"
            isDownloading = false
        }
    }

    private func downloadFile(from url: URL, to destination: URL, fileSize: Int64) async throws {
        let startBytes = bytesDownloaded

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let config = URLSessionConfiguration.default
            let delegate = DownloadProgressDelegate(
                onProgress: { [weak self] written, _ in
                    Task { @MainActor in
                        guard let self = self else { return }
                        self.bytesDownloaded = startBytes + written
                        self.progress = Double(self.bytesDownloaded) / Double(self.totalBytes)
                    }
                },
                onComplete: { tempURL, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    guard let tempURL = tempURL else {
                        continuation.resume(throwing: URLError(.badServerResponse))
                        return
                    }
                    do {
                        if FileManager.default.fileExists(atPath: destination.path) {
                            try FileManager.default.removeItem(at: destination)
                        }
                        try FileManager.default.moveItem(at: tempURL, to: destination)
                        continuation.resume()
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            )

            let session = URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
            let task = session.downloadTask(with: url)
            task.resume()
        }
    }

    func cancelDownload() {
        downloadTask?.terminate()
        downloadTask = nil
        urlSessionTask?.cancel()
        urlSessionTask = nil
        isDownloading = false
        statusMessage = "Download cancelled"
    }
}

// Download delegate for tracking progress
class DownloadProgressDelegate: NSObject, URLSessionDownloadDelegate {
    let onProgress: (Int64, Int64) -> Void
    let onComplete: (URL?, Error?) -> Void

    init(onProgress: @escaping (Int64, Int64) -> Void, onComplete: @escaping (URL?, Error?) -> Void) {
        self.onProgress = onProgress
        self.onComplete = onComplete
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        onComplete(location, nil)
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        onProgress(totalBytesWritten, totalBytesExpectedToWrite)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            onComplete(nil, error)
        }
    }
}
