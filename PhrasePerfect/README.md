# PhrasePerfect

A lightweight, native macOS menu bar application that functions as an on-demand AI translator/editor. Runs a local LLM via MLX Swift for Italian-to-English translation optimized for developers.

## Features

- **Menu Bar Only**: Lives in the menu bar with no dock icon (LSUIElement)
- **Global Hotkey**: Press `Option + Space` from any app to toggle the translator
- **Local LLM**: Uses MLX Swift to run models locally - no API keys needed
- **First-Run Setup**: Guided wizard to download recommended models from Hugging Face
- **Three Translation Styles**: Professional, Casual/Slack, and Technical/Dev
- **Markdown Output**: Responses are formatted in Markdown with headers and code blocks
- **One-Click Copy**: Easily copy the response to clipboard

## Requirements

- macOS 14.0 (Sonoma) or later
- Apple Silicon Mac (M1/M2/M3)
- Xcode 15+ (required for building Metal shaders)
- ~8GB RAM minimum (16GB+ recommended for larger models)
- ~5-10GB disk space for the model

### First-time Setup

If this is your first time building an MLX Swift app, you may need to download the Metal Toolchain:

```bash
xcodebuild -downloadComponent MetalToolchain
```

## Quick Start

```bash
cd PhrasePerfect
make run
```

This builds the app as a proper `.app` bundle and launches it. On first launch, the app will guide you through downloading a recommended model.

> **Note:** Don't use `swift build` or `swift run` directly - MLX requires Metal shaders that SwiftPM cannot compile. The Makefile uses `xcodebuild` which properly handles Metal compilation. Always use `make run` or `make bundle`.

## Model Setup

### Option 1: Automatic Download (Recommended)

On first launch, PhrasePerfect will offer to download a recommended model automatically. This is the easiest way to get started.

**Recommended models:**
| Model | Size | RAM Required | Quality |
|-------|------|--------------|---------|
| `mlx-community/gemma-3-1b-it-4bit` | ~0.8GB | 8GB | Ultra fast, good for quick translations |
| `mlx-community/gemma-3-4b-it-4bit` | ~2.5GB | 8GB | Good balance of speed and quality |
| `mlx-community/gemma-3-12b-it-4bit` | ~7GB | 16GB | Best quality translations |

### Option 2: Manual Download

**Using huggingface-cli:**
```bash
# Install huggingface-cli if needed
pip install huggingface-hub

# Download a model (example: Gemma 3 4B)
huggingface-cli download mlx-community/gemma-3-4b-it-4bit \
    --local-dir ~/Models/gemma-3-4b-it-4bit

# Or a smaller model for machines with less RAM
huggingface-cli download mlx-community/gemma-3-1b-it-4bit \
    --local-dir ~/Models/gemma-3-1b-it-4bit
```

**Using Python mlx-lm (to convert your own models):**
```bash
pip install mlx-lm

# Convert and quantize a model from Hugging Face
python -m mlx_lm.convert \
    --hf-path google/gemma-3-4b-it \
    --mlx-path ~/Models/gemma-3-4b-it-mlx \
    -q
```

### Option 3: Configure Existing Model

If you already have an MLX-format model:
1. Right-click the menu bar icon → "Settings"
2. In the "Model" tab, click "Browse..."
3. Select your model folder
4. Click "Load Model"

**Required model files:**
```
~/Models/your-model/
├── config.json           # Model configuration
├── model.safetensors     # Or model-00001-of-*.safetensors
├── tokenizer.json        # Tokenizer vocabulary
└── tokenizer_config.json # Tokenizer settings
```

## Usage

1. Press `Option + Space` to open the translator (works from any app)
2. Type or paste Italian text in the input field
3. Press `Cmd + Return` or click "Translate"
4. Review the three translation styles:
   - **Professional**: Formal business English
   - **Casual/Slack**: Friendly, conversational tone
   - **Technical/Dev**: Developer-focused with code terms
5. Click "Copy" to copy your preferred translation

## Building

The build system uses `xcodebuild` instead of `swift build` because MLX Swift requires Metal shader compilation that SwiftPM cannot handle.

```bash
# Build and run
make run

# Just build the .app bundle
make bundle

# Build debug version
make debug

# Install to /Applications
make install

# Clean build
make clean
```

The app bundle is created at `.xcodebuild/DerivedData/Build/Products/Release/PhrasePerfect.app`.

## Architecture

```
PhrasePerfect/
├── Package.swift
└── Sources/PhrasePerfect/
    ├── PhrasePerfectApp.swift    # App entry point & delegate
    ├── Models/
    │   ├── AppState.swift        # Observable app state
    │   ├── MLXActor.swift        # Thread-safe LLM operations
    │   └── ModelDownloader.swift # HuggingFace model download
    ├── Managers/
    │   ├── HotKeyManager.swift   # Carbon global hotkey
    │   └── StatusBarManager.swift # Menu bar icon
    └── Views/
        ├── MainView.swift        # Main translator UI
        ├── MarkdownView.swift    # Markdown rendering
        ├── OnboardingView.swift  # First-run setup wizard
        └── SettingsView.swift    # Model & hotkey config
```

## System Prompt

The app uses this system prompt for translations:

> Act as PhrasePerfect AI, an expert English language assistant for a CTO.
> 1. Translate the Italian input into natural, professional English.
> 2. Provide 3 versions: "Professional", "Casual/Slack", and "Technical/Dev".
> 3. Briefly explain any grammar corrections.
> 4. Format the output clearly in Markdown.

## Troubleshooting

**"Model path not configured"**
- Open Settings and select a valid model directory
- Or let the app download a model on first run

**Model loading fails**
- Ensure you have an MLX-format model (not PyTorch/GGUF)
- Check the model folder contains `config.json` and `.safetensors` files
- Try a smaller model if you're running out of memory

**Hotkey doesn't work**
- Grant Accessibility permissions: System Settings → Privacy & Security → Accessibility
- Restart the app after granting permissions

## License

MIT
