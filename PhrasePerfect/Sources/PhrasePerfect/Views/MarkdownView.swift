// ABOUTME: Markdown rendering view using AttributedString
// ABOUTME: Displays formatted text with headers, code blocks, lists, and bold

import SwiftUI

struct MarkdownView: View {
    let text: String

    var body: some View {
        if text.isEmpty {
            Text("")
        } else if let attributedString = try? AttributedString(markdown: text, options: markdownOptions) {
            Text(attributedString)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            // Fallback to plain text if markdown parsing fails
            Text(text)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var markdownOptions: AttributedString.MarkdownParsingOptions {
        var options = AttributedString.MarkdownParsingOptions()
        options.interpretedSyntax = .inlineOnlyPreservingWhitespace
        return options
    }
}

// Alternative markdown view with custom styling for better code block support
struct RichMarkdownView: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(parseBlocks(), id: \.id) { block in
                blockView(for: block)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func parseBlocks() -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        var currentText = ""
        var inCodeBlock = false
        var codeLanguage = ""

        for line in text.components(separatedBy: "\n") {
            if line.hasPrefix("```") {
                if inCodeBlock {
                    // End code block
                    blocks.append(.code(currentText, language: codeLanguage))
                    currentText = ""
                    inCodeBlock = false
                    codeLanguage = ""
                } else {
                    // Start code block
                    if !currentText.isEmpty {
                        blocks.append(.text(currentText))
                        currentText = ""
                    }
                    inCodeBlock = true
                    codeLanguage = String(line.dropFirst(3))
                }
            } else if inCodeBlock {
                currentText += (currentText.isEmpty ? "" : "\n") + line
            } else if line.hasPrefix("# ") {
                if !currentText.isEmpty {
                    blocks.append(.text(currentText))
                    currentText = ""
                }
                blocks.append(.header(String(line.dropFirst(2)), level: 1))
            } else if line.hasPrefix("## ") {
                if !currentText.isEmpty {
                    blocks.append(.text(currentText))
                    currentText = ""
                }
                blocks.append(.header(String(line.dropFirst(3)), level: 2))
            } else if line.hasPrefix("### ") {
                if !currentText.isEmpty {
                    blocks.append(.text(currentText))
                    currentText = ""
                }
                blocks.append(.header(String(line.dropFirst(4)), level: 3))
            } else {
                currentText += (currentText.isEmpty ? "" : "\n") + line
            }
        }

        if !currentText.isEmpty {
            if inCodeBlock {
                blocks.append(.code(currentText, language: codeLanguage))
            } else {
                blocks.append(.text(currentText))
            }
        }

        return blocks
    }

    @ViewBuilder
    private func blockView(for block: MarkdownBlock) -> some View {
        switch block {
        case .text(let content):
            if let attributedString = try? AttributedString(markdown: content) {
                Text(attributedString)
                    .textSelection(.enabled)
            } else {
                Text(content)
                    .textSelection(.enabled)
            }

        case .header(let content, let level):
            Text(content)
                .font(level == 1 ? .title2 : level == 2 ? .title3 : .headline)
                .fontWeight(.bold)
                .padding(.top, level == 1 ? 8 : 4)

        case .code(let content, _):
            Text(content)
                .font(.system(.body, design: .monospaced))
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
                .textSelection(.enabled)
        }
    }
}

enum MarkdownBlock: Identifiable {
    case text(String)
    case header(String, level: Int)
    case code(String, language: String)

    var id: String {
        switch self {
        case .text(let s): return "text-\(s.hashValue)"
        case .header(let s, let l): return "header-\(l)-\(s.hashValue)"
        case .code(let s, _): return "code-\(s.hashValue)"
        }
    }
}
