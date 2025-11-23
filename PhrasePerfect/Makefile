# ABOUTME: Makefile for building PhrasePerfect as a proper macOS app bundle
# ABOUTME: Uses xcodebuild because SwiftPM cannot compile Metal shaders (required by MLX)

.PHONY: build run clean install

APP_NAME = PhrasePerfect
XCODE_BUILD_DIR = .xcodebuild
DERIVED_DATA = $(XCODE_BUILD_DIR)/DerivedData
APP_BUNDLE = $(DERIVED_DATA)/Build/Products/Release/$(APP_NAME).app

# Build using xcodebuild directly from Package.swift (Xcode 11+)
# This properly compiles Metal shaders that SwiftPM cannot handle
build:
	@echo "Building with xcodebuild (this compiles Metal shaders)..."
	@mkdir -p "$(DERIVED_DATA)"
	xcodebuild -scheme $(APP_NAME) \
		-configuration Release \
		-derivedDataPath "$(DERIVED_DATA)" \
		-destination 'platform=macOS' \
		build
	@echo "Build complete!"

# Create app bundle with Info.plist and Metal libraries
bundle: build
	@echo "Creating app bundle..."
	@mkdir -p "$(APP_BUNDLE)/Contents/MacOS"
	@mkdir -p "$(APP_BUNDLE)/Contents/Resources"

	# Copy executable
	@cp "$(DERIVED_DATA)/Build/Products/Release/$(APP_NAME)" "$(APP_BUNDLE)/Contents/MacOS/"

	# Copy MLX Metal bundle (contains metallib required for GPU operations)
	@cp -R "$(DERIVED_DATA)/Build/Products/Release/mlx-swift_Cmlx.bundle" "$(APP_BUNDLE)/Contents/Resources/" 2>/dev/null || true

	# Copy swift-transformers Hub bundle
	@cp -R "$(DERIVED_DATA)/Build/Products/Release/swift-transformers_Hub.bundle" "$(APP_BUNDLE)/Contents/Resources/" 2>/dev/null || true

	# Create Info.plist
	@/usr/libexec/PlistBuddy -c "Clear dict" "$(APP_BUNDLE)/Contents/Info.plist" 2>/dev/null || true
	@/usr/libexec/PlistBuddy \
		-c "Add :CFBundleExecutable string $(APP_NAME)" \
		-c "Add :CFBundleIdentifier string com.phraseperfect.app" \
		-c "Add :CFBundleName string $(APP_NAME)" \
		-c "Add :CFBundlePackageType string APPL" \
		-c "Add :CFBundleShortVersionString string 1.0" \
		-c "Add :CFBundleVersion string 1" \
		-c "Add :LSMinimumSystemVersion string 14.0" \
		-c "Add :LSUIElement bool true" \
		"$(APP_BUNDLE)/Contents/Info.plist"

	@echo "App bundle created at: $(APP_BUNDLE)"

# Run the app bundle
run: bundle
	@echo "Launching $(APP_NAME)..."
	@open "$(APP_BUNDLE)"

# Debug build with xcodebuild
debug:
	@echo "Building debug with xcodebuild..."
	@mkdir -p "$(DERIVED_DATA)"
	xcodebuild -scheme $(APP_NAME) \
		-configuration Debug \
		-derivedDataPath "$(DERIVED_DATA)" \
		-destination 'platform=macOS' \
		build
	@open "$(DERIVED_DATA)/Build/Products/Debug/$(APP_NAME).app"

# Install to /Applications
install: bundle
	@echo "Installing to /Applications..."
	@rm -rf "/Applications/$(APP_NAME).app"
	@cp -R "$(APP_BUNDLE)" "/Applications/"
	@echo "Installed to /Applications/$(APP_NAME).app"

# Clean build artifacts
clean:
	swift package clean 2>/dev/null || true
	rm -rf .build
	rm -rf $(XCODE_BUILD_DIR)

# Help
help:
	@echo "PhrasePerfect Build Commands:"
	@echo ""
	@echo "  make build    - Build release version with xcodebuild"
	@echo "  make bundle   - Create .app bundle (required for MLX)"
	@echo "  make run      - Build and run the app"
	@echo "  make debug    - Build and run debug version"
	@echo "  make install  - Install to /Applications"
	@echo "  make clean    - Clean build artifacts"
	@echo ""
	@echo "Note: This uses xcodebuild because SwiftPM cannot compile"
	@echo "      Metal shaders required by MLX Swift."
	@echo "      'swift run' will fail with metallib errors."
