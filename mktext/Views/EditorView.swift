import SwiftUI

/// Main editor view mimicking jlmr.dev website layout
struct EditorView: View {
    @Binding var document: MarkdownDocument
    var fileURL: URL?
    @State private var isShowingRawMarkdown = false
    @State private var cursorPosition: Int = 0
    @StateObject private var commentStore = CommentStore()
    @Environment(\.colorScheme) private var colorScheme

    private var theme: MarkdownTheme {
        colorScheme == .dark ? .jlmrDevDark : .jlmrDev
    }

    var body: some View {
        HStack(spacing: 0) {
            // Main editor area
            VStack(spacing: 0) {
                // Minimal toolbar (hidden by default for clean look)
                ToolbarView(isShowingRaw: $isShowingRawMarkdown)
                    .opacity(0.8)

                // Website-style container
                GeometryReader { geometry in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            // Website Header
                            WebsiteHeaderView(theme: theme)

                            // Main content area - centered with max-width
                            VStack(alignment: .leading, spacing: 0) {
                                WYSIWYGTextView(
                                    text: $document.text,
                                    isShowingRawMarkdown: $isShowingRawMarkdown,
                                    theme: theme,
                                    commentStore: commentStore,
                                    onCursorPositionChange: { position in
                                        cursorPosition = position
                                    }
                                )
                                .frame(minHeight: max(400, geometry.size.height - 200))
                            }
                            .frame(maxWidth: 700, alignment: .leading)
                            .frame(maxWidth: .infinity)

                            // Website Footer
                            WebsiteFooterView(theme: theme)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 32)
                    }
                }
                .background(Color(theme.backgroundColor))

                // Subtle status bar
                StatusBarView(
                    wordCount: document.text.wordCount,
                    lineCount: document.text.lineCount,
                    cursorPosition: cursorPosition,
                    isRawMode: isShowingRawMarkdown,
                    commentCount: commentStore.activeComments.count,
                    showCommentsSidebar: $commentStore.showSidebar,
                    theme: theme
                )
            }

            // Comments sidebar
            if commentStore.showSidebar {
                CommentsSidebarView(commentStore: commentStore, theme: theme)
                    .frame(width: 260)
                    .transition(.move(edge: .trailing))
            }
        }
        .background(Color(theme.backgroundColor))
        .frame(minWidth: 600, minHeight: 500)
        .onAppear {
            commentStore.load(for: fileURL)
        }
        .onChange(of: fileURL) { newURL in
            commentStore.load(for: newURL)
        }
    }
}

/// Website header mimicking jlmr.dev
struct WebsiteHeaderView: View {
    let theme: MarkdownTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Jelmer Snoeck")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(Color(theme.textColor))
        }
        .frame(maxWidth: 700, alignment: .leading)
        .frame(maxWidth: .infinity)
        .padding(.bottom, 48)
    }
}

/// Website footer mimicking jlmr.dev
struct WebsiteFooterView: View {
    let theme: MarkdownTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle()
                .fill(Color(theme.syntaxColor).opacity(0.3))
                .frame(height: 1)
                .padding(.top, 64)
                .padding(.bottom, 16)

            Text("Jelmer Snoeck")
                .font(.system(size: 14))
                .foregroundColor(Color(theme.syntaxColor))
        }
        .frame(maxWidth: 700, alignment: .leading)
        .frame(maxWidth: .infinity)
    }
}

/// Status bar showing document statistics
struct StatusBarView: View {
    let wordCount: Int
    let lineCount: Int
    let cursorPosition: Int
    let isRawMode: Bool
    let commentCount: Int
    @Binding var showCommentsSidebar: Bool
    let theme: MarkdownTheme

    var body: some View {
        HStack {
            Text("\(wordCount) words")
                .font(.system(size: 12))
                .foregroundColor(Color(theme.syntaxColor))

            Text("·")
                .foregroundColor(Color(theme.syntaxColor).opacity(0.5))

            Text("\(lineCount) lines")
                .font(.system(size: 12))
                .foregroundColor(Color(theme.syntaxColor))

            Spacer()

            if isRawMode {
                Text("Raw Markdown")
                    .font(.system(size: 12))
                    .foregroundColor(Color(theme.linkColor))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(theme.linkColor).opacity(0.1))
                    .cornerRadius(4)
            }

            // Comments toggle
            Button(action: { showCommentsSidebar.toggle() }) {
                HStack(spacing: 4) {
                    Image(systemName: "text.bubble")
                        .font(.system(size: 11))
                    if commentCount > 0 {
                        Text("\(commentCount)")
                            .font(.system(size: 11))
                    }
                }
                .foregroundColor(
                    showCommentsSidebar
                        ? Color(theme.linkColor)
                        : Color(theme.syntaxColor)
                )
            }
            .buttonStyle(.plain)
            .help("Toggle comments sidebar")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(theme.backgroundColor))
        .overlay(
            Rectangle()
                .fill(Color(theme.syntaxColor).opacity(0.2))
                .frame(height: 1),
            alignment: .top
        )
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
