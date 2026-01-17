import AppKit

/// Theme configuration for markdown styling
struct MarkdownTheme {
    let bodyFont: NSFont
    let monoFont: NSFont
    let textColor: NSColor
    let syntaxColor: NSColor
    let linkColor: NSColor
    let codeBackgroundColor: NSColor
    let blockquoteBorderColor: NSColor
    let blockquoteTextColor: NSColor

    let headingFonts: [Int: NSFont]
    let bodyParagraphStyle: NSParagraphStyle
    let blockquoteParagraphStyle: NSParagraphStyle

    func headingFont(level: Int) -> NSFont {
        headingFonts[level] ?? bodyFont
    }

    static let `default` = MarkdownTheme(
        bodyFont: NSFont.systemFont(ofSize: 16, weight: .regular),
        monoFont: NSFont.monospacedSystemFont(ofSize: 14, weight: .regular),
        textColor: NSColor.textColor,
        syntaxColor: NSColor.tertiaryLabelColor,
        linkColor: NSColor.linkColor,
        codeBackgroundColor: NSColor.quaternaryLabelColor.withAlphaComponent(0.3),
        blockquoteBorderColor: NSColor.separatorColor,
        blockquoteTextColor: NSColor.secondaryLabelColor,
        headingFonts: [
            1: NSFont.systemFont(ofSize: 32, weight: .bold),
            2: NSFont.systemFont(ofSize: 26, weight: .bold),
            3: NSFont.systemFont(ofSize: 22, weight: .semibold),
            4: NSFont.systemFont(ofSize: 18, weight: .semibold),
            5: NSFont.systemFont(ofSize: 16, weight: .medium),
            6: NSFont.systemFont(ofSize: 14, weight: .medium)
        ],
        bodyParagraphStyle: {
            let style = NSMutableParagraphStyle()
            style.lineSpacing = 4
            style.paragraphSpacing = 12
            return style
        }(),
        blockquoteParagraphStyle: {
            let style = NSMutableParagraphStyle()
            style.lineSpacing = 4
            style.paragraphSpacing = 8
            style.headIndent = 20
            style.firstLineHeadIndent = 20
            return style
        }()
    )

    static let minimal = MarkdownTheme(
        bodyFont: NSFont(name: "Georgia", size: 16) ?? NSFont.systemFont(ofSize: 16),
        monoFont: NSFont.monospacedSystemFont(ofSize: 14, weight: .regular),
        textColor: NSColor.textColor,
        syntaxColor: NSColor.tertiaryLabelColor.withAlphaComponent(0.5),
        linkColor: NSColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0),
        codeBackgroundColor: NSColor.quaternaryLabelColor.withAlphaComponent(0.2),
        blockquoteBorderColor: NSColor.separatorColor,
        blockquoteTextColor: NSColor.secondaryLabelColor,
        headingFonts: [
            1: NSFont(name: "Georgia-Bold", size: 28) ?? NSFont.systemFont(ofSize: 28, weight: .bold),
            2: NSFont(name: "Georgia-Bold", size: 24) ?? NSFont.systemFont(ofSize: 24, weight: .bold),
            3: NSFont(name: "Georgia-Bold", size: 20) ?? NSFont.systemFont(ofSize: 20, weight: .semibold),
            4: NSFont(name: "Georgia-Bold", size: 18) ?? NSFont.systemFont(ofSize: 18, weight: .semibold),
            5: NSFont(name: "Georgia-Bold", size: 16) ?? NSFont.systemFont(ofSize: 16, weight: .medium),
            6: NSFont(name: "Georgia-Bold", size: 14) ?? NSFont.systemFont(ofSize: 14, weight: .medium)
        ],
        bodyParagraphStyle: {
            let style = NSMutableParagraphStyle()
            style.lineSpacing = 6
            style.paragraphSpacing = 16
            return style
        }(),
        blockquoteParagraphStyle: {
            let style = NSMutableParagraphStyle()
            style.lineSpacing = 6
            style.paragraphSpacing = 12
            style.headIndent = 24
            style.firstLineHeadIndent = 24
            return style
        }()
    )
}
