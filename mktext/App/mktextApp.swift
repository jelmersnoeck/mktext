import SwiftUI

@main
struct mktextApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: MarkdownDocument()) { file in
            EditorView(document: file.$document, fileURL: file.fileURL)
        }
        .commands {
            CommandGroup(replacing: .textFormatting) {
                Button("Bold") {
                    NotificationCenter.default.post(name: .formatBold, object: nil)
                }
                .keyboardShortcut("b", modifiers: .command)

                Button("Italic") {
                    NotificationCenter.default.post(name: .formatItalic, object: nil)
                }
                .keyboardShortcut("i", modifiers: .command)

                Button("Link") {
                    NotificationCenter.default.post(name: .formatLink, object: nil)
                }
                .keyboardShortcut("k", modifiers: .command)

                Divider()

                Menu("Heading") {
                    ForEach(1...6, id: \.self) { level in
                        Button("Heading \(level)") {
                            NotificationCenter.default.post(
                                name: .formatHeading,
                                object: level
                            )
                        }
                        .keyboardShortcut(KeyEquivalent(Character("\(level)")), modifiers: .command)
                    }
                }

                Divider()

                Button("Add Comment") {
                    NotificationCenter.default.post(name: .addComment, object: nil)
                }
                .keyboardShortcut("m", modifiers: [.command, .option])

                Button("Toggle Comments") {
                    NotificationCenter.default.post(name: .toggleCommentsSidebar, object: nil)
                }
                .keyboardShortcut("m", modifiers: [.command, .shift])
            }

            CommandGroup(after: .textEditing) {
                Button("Toggle Raw Markdown") {
                    NotificationCenter.default.post(name: .toggleRawMarkdown, object: nil)
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])
            }
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let formatBold = Notification.Name("formatBold")
    static let formatItalic = Notification.Name("formatItalic")
    static let formatLink = Notification.Name("formatLink")
    static let formatHeading = Notification.Name("formatHeading")
    static let toggleRawMarkdown = Notification.Name("toggleRawMarkdown")
    static let addComment = Notification.Name("addComment")
    static let toggleCommentsSidebar = Notification.Name("toggleCommentsSidebar")
}
