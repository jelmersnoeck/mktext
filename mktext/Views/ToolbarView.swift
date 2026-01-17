import SwiftUI

/// Toolbar with formatting buttons and view toggle
struct ToolbarView: View {
    @Binding var isShowingRaw: Bool

    var body: some View {
        HStack(spacing: 4) {
            // Text formatting group
            Group {
                FormatButton(
                    icon: "bold",
                    tooltip: "Bold (Cmd+B)",
                    action: { NotificationCenter.default.post(name: .formatBold, object: nil) }
                )

                FormatButton(
                    icon: "italic",
                    tooltip: "Italic (Cmd+I)",
                    action: { NotificationCenter.default.post(name: .formatItalic, object: nil) }
                )

                FormatButton(
                    icon: "link",
                    tooltip: "Link (Cmd+K)",
                    action: { NotificationCenter.default.post(name: .formatLink, object: nil) }
                )
            }

            Divider()
                .frame(height: 20)
                .padding(.horizontal, 4)

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
                    .frame(width: 28, height: 28)
            }
            .menuStyle(.borderlessButton)
            .frame(width: 36)
            .help("Heading")

            Divider()
                .frame(height: 20)
                .padding(.horizontal, 4)

            // List formatting
            FormatButton(
                icon: "list.bullet",
                tooltip: "Bullet List",
                action: { NotificationCenter.default.post(name: .formatList, object: "unordered") }
            )

            FormatButton(
                icon: "list.number",
                tooltip: "Numbered List",
                action: { NotificationCenter.default.post(name: .formatList, object: "ordered") }
            )

            FormatButton(
                icon: "text.quote",
                tooltip: "Blockquote",
                action: { NotificationCenter.default.post(name: .formatBlockquote, object: nil) }
            )

            Spacer()

            // View toggle
            Button(action: {
                isShowingRaw.toggle()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: isShowingRaw ? "eye.slash" : "eye")
                    Text(isShowingRaw ? "Show Formatted" : "Show Raw")
                        .font(.caption)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isShowingRaw ? Color.orange.opacity(0.2) : Color.clear)
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
            .help("Toggle Raw Markdown (Cmd+Shift+E)")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

/// Individual formatting button
struct FormatButton: View {
    let icon: String
    let tooltip: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .frame(width: 28, height: 28)
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 6)
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
        ToolbarView(isShowingRaw: .constant(false))
            .frame(width: 600)
    }
}
#endif
