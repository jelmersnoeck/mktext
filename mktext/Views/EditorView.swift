import SwiftUI

/// Main editor view containing toolbar, text editor, and status bar
struct EditorView: View {
    @Binding var document: MarkdownDocument
    @State private var isShowingRawMarkdown = false
    @State private var cursorPosition: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            ToolbarView(isShowingRaw: $isShowingRawMarkdown)

            Divider()

            // Editor
            WYSIWYGTextView(
                text: $document.text,
                isShowingRawMarkdown: $isShowingRawMarkdown,
                onCursorPositionChange: { position in
                    cursorPosition = position
                }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            // Status bar
            StatusBarView(
                wordCount: document.text.wordCount,
                lineCount: document.text.lineCount,
                cursorPosition: cursorPosition,
                isRawMode: isShowingRawMarkdown
            )
        }
        .background(Color(NSColor.textBackgroundColor))
        .frame(minWidth: 500, minHeight: 400)
    }
}

/// Status bar showing document statistics
struct StatusBarView: View {
    let wordCount: Int
    let lineCount: Int
    let cursorPosition: Int
    let isRawMode: Bool

    var body: some View {
        HStack {
            Text("\(wordCount) words")
                .font(.caption)
                .foregroundColor(.secondary)

            Divider()
                .frame(height: 12)

            Text("\(lineCount) lines")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            if isRawMode {
                Text("Raw Markdown")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(4)
            }

            Text("Position: \(cursorPosition)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - Preview
#if DEBUG
struct EditorView_Previews: PreviewProvider {
    static var previews: some View {
        EditorView(document: .constant(MarkdownDocument()))
    }
}
#endif
