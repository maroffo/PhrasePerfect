// swift-tools-version: 5.9
// ABOUTME: Swift Package manifest for PhrasePerfect menu bar app
// ABOUTME: Defines dependencies on mlx-swift and mlx-swift-lm for LLM inference

import PackageDescription

let package = Package(
    name: "PhrasePerfect",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "PhrasePerfect", targets: ["PhrasePerfect"])
    ],
    dependencies: [
        .package(url: "https://github.com/ml-explore/mlx-swift", from: "0.18.0"),
        .package(url: "https://github.com/ml-explore/mlx-swift-lm", branch: "main"),
    ],
    targets: [
        .executableTarget(
            name: "PhrasePerfect",
            dependencies: [
                .product(name: "MLX", package: "mlx-swift"),
                .product(name: "MLXLLM", package: "mlx-swift-lm"),
                .product(name: "MLXLMCommon", package: "mlx-swift-lm"),
            ],
            exclude: ["Resources/Info.plist"]
        ),
    ]
)
