import SwiftUI

/// Minimal toolbar with formatting buttons - subtle design to not distract from content
struct ToolbarView: View {
    @Binding var isShowingRaw: Bool
    @Environment(\.colorScheme) private var colorScheme

    private var theme: MarkdownTheme {
        colorScheme == .dark ? .jlmrDevDark : .jlmrDev
    }

    var body: some View {
        HStack(spacing: 2) {
            // Text formatting group
            Group {
                FormatButton(
                    icon: "bold",
                    tooltip: "Bold (Cmd+B)",
                    theme: theme,
                    action: { NotificationCenter.default.post(name: .formatBold, object: nil) }
                )

                FormatButton(
                    icon: "italic",
                    tooltip: "Italic (Cmd+I)",
                    theme: theme,
                    action: { NotificationCenter.default.post(name: .formatItalic, object: nil) }
                )

                FormatButton(
                    icon: "link",
                    tooltip: "Link (Cmd+K)",
                    theme: theme,
                    action: { NotificationCenter.default.post(name: .formatLink, object: nil) }
                )
            }

            Rectangle()
                .fill(Color(theme.syntaxColor).opacity(0.2))
                .frame(width: 1, height: 16)
                .padding(.horizontal, 6)

            // Heading menu
            Menu {
                ForEach(1...6, id: \.self) { level in
                    Button("Heading \(level)") {
                        NotificationCenter.default.post(name: .formatHeading, object: level)
                    }
                    .keyboardShortcut(KeyEquivalent(Character("\(level)")), modifiers: .command)
                }
            } label: {
                Image(systemName: "textformat.size")
                    .font(.system(size: 13))
                    .foregroundColor(Color(theme.syntaxColor))
                    .frame(width: 24, height: 24)
            }
            .menuStyle(.borderlessButton)
            .frame(width: 28)
            .help("Heading")

            Rectangle()
                .fill(Color(theme.syntaxColor).opacity(0.2))
                .frame(width: 1, height: 16)
                .padding(.horizontal, 6)

            // List formatting
            FormatButton(
                icon: "list.bullet",
                tooltip: "Bullet List",
                theme: theme,
                action: { NotificationCenter.default.post(name: .formatList, object: "unordered") }
            )

            FormatButton(
                icon: "list.number",
                tooltip: "Numbered List",
                theme: theme,
                action: { NotificationCenter.default.post(name: .formatList, object: "ordered") }
            )

            FormatButton(
                icon: "text.quote",
                tooltip: "Blockquote",
                theme: theme,
                action: { NotificationCenter.default.post(name: .formatBlockquote, object: nil) }
            )

            Spacer()

            // View toggle - minimal style
            Button(action: {
                isShowingRaw.toggle()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: isShowingRaw ? "eye.slash" : "eye")
                        .font(.system(size: 12))
                    Text(isShowingRaw ? "Raw" : "Preview")
                        .font(.system(size: 12))
                }
                .foregroundColor(Color(isShowingRaw ? theme.linkColor : theme.syntaxColor))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(isShowingRaw ? theme.linkColor : theme.syntaxColor).opacity(0.1))
                )
            }
            .buttonStyle(.plain)
            .help("Toggle Raw Markdown (Cmd+Shift+E)")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(theme.backgroundColor))
        .overlay(
            Rectangle()
                .fill(Color(theme.syntaxColor).opacity(0.15))
                .frame(height: 1),
            alignment: .bottom
        )
    }
}

/// Individual formatting button with minimal styling
struct FormatButton: View {
    let icon: String
    let tooltip: String
    let theme: MarkdownTheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(Color(theme.syntaxColor))
                .frame(width: 24, height: 24)
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.clear)
        )
        .contentShape(Rectangle())
        .help(tooltip)
    }
}

// MARK: - Additional Notification Names
extension Notification.Name {
    static let formatList = Notification.Name("formatList")
    static let formatBlockquote = Notification.Name("formatBlockquote")
}

// MARK: - Preview
#if DEBUG
struct ToolbarView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ToolbarView(isShowingRaw: .constant(false))
                .frame(width: 600)
                .preferredColorScheme(.light)

            ToolbarView(isShowingRaw: .constant(true))
                .frame(width: 600)
                .preferredColorScheme(.dark)
        }
    }
}
#endif
