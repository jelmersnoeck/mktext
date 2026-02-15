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
    let backgroundColor: NSColor

    let headingFonts: [Int: NSFont]
    let headingParagraphStyles: [Int: NSParagraphStyle]
    let bodyParagraphStyle: NSParagraphStyle
    let blockquoteParagraphStyle: NSParagraphStyle
    let listParagraphStyle: NSParagraphStyle

    func headingFont(level: Int) -> NSFont {
        headingFonts[level] ?? bodyFont
    }

    func headingParagraphStyle(level: Int) -> NSParagraphStyle {
        headingParagraphStyles[level] ?? bodyParagraphStyle
    }

    /// Returns the appropriate theme variant based on system appearance
    static func forCurrentAppearance() -> MarkdownTheme {
        if NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
            return .jlmrDevDark
        }
        return .jlmrDev
    }

    // MARK: - Heading Paragraph Styles

    /// Creates heading paragraph styles matching jlmr.dev blog spacing
    private static func blogHeadingParagraphStyles() -> [Int: NSParagraphStyle] {
        var styles: [Int: NSParagraphStyle] = [:]

        // H1 (.post h1): margin-bottom: 0.5rem (8pt)
        let h1Style = NSMutableParagraphStyle()
        h1Style.lineHeightMultiple = 1.6
        h1Style.paragraphSpacing = 8
        styles[1] = h1Style

        // H2 (.post-content h2): margin: 2rem 0 1rem
        let h2Style = NSMutableParagraphStyle()
        h2Style.lineHeightMultiple = 1.6
        h2Style.paragraphSpacingBefore = 32
        h2Style.paragraphSpacing = 16
        styles[2] = h2Style

        // H3 (.post-content h3): margin: 1.5rem 0 0.75rem
        let h3Style = NSMutableParagraphStyle()
        h3Style.lineHeightMultiple = 1.6
        h3Style.paragraphSpacingBefore = 24
        h3Style.paragraphSpacing = 12
        styles[3] = h3Style

        // H4-H6: reasonable defaults
        for level in 4...6 {
            let style = NSMutableParagraphStyle()
            style.lineHeightMultiple = 1.6
            style.paragraphSpacingBefore = 16
            style.paragraphSpacing = 8
            styles[level] = style
        }

        return styles
    }

    // MARK: - jlmr.dev Light Theme

    /// Theme matching jlmr.dev website (light mode)
    static let jlmrDev = MarkdownTheme(
        bodyFont: NSFont.systemFont(ofSize: 16, weight: .regular),
        monoFont: NSFont(name: "SFMono-Regular", size: 14.4) ?? NSFont.monospacedSystemFont(ofSize: 14.4, weight: .regular),
        textColor: NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.2, alpha: 1.0), // #333
        syntaxColor: NSColor(calibratedRed: 0.4, green: 0.4, blue: 0.4, alpha: 1.0), // #666
        linkColor: NSColor(calibratedRed: 0.0, green: 0.4, blue: 0.8, alpha: 1.0), // #0066cc
        codeBackgroundColor: NSColor(calibratedRed: 0.96, green: 0.96, blue: 0.96, alpha: 1.0), // #f5f5f5
        blockquoteBorderColor: NSColor(calibratedRed: 0.867, green: 0.867, blue: 0.867, alpha: 1.0), // #ddd
        blockquoteTextColor: NSColor(calibratedRed: 0.333, green: 0.333, blue: 0.333, alpha: 1.0), // #555
        backgroundColor: NSColor.white,
        headingFonts: [
            1: NSFont.systemFont(ofSize: 32, weight: .bold),   // 2rem, browser default bold (700)
            2: NSFont.systemFont(ofSize: 24, weight: .bold),   // 1.5rem
            3: NSFont.systemFont(ofSize: 20, weight: .bold),   // 1.25rem
            4: NSFont.systemFont(ofSize: 18, weight: .bold),
            5: NSFont.systemFont(ofSize: 16, weight: .bold),
            6: NSFont.systemFont(ofSize: 14, weight: .bold)
        ],
        headingParagraphStyles: blogHeadingParagraphStyles(),
        bodyParagraphStyle: {
            let style = NSMutableParagraphStyle()
            style.lineHeightMultiple = 1.6
            style.paragraphSpacing = 16
            return style
        }(),
        blockquoteParagraphStyle: {
            let style = NSMutableParagraphStyle()
            style.lineHeightMultiple = 1.6
            style.paragraphSpacingBefore = 24   // margin: 1.5rem 0
            style.paragraphSpacing = 24
            style.headIndent = 16               // padding-left: 1rem
            style.firstLineHeadIndent = 16
            return style
        }(),
        listParagraphStyle: {
            let style = NSMutableParagraphStyle()
            style.lineHeightMultiple = 1.6
            style.paragraphSpacing = 8          // li margin-bottom: 0.5rem
            style.headIndent = 32               // padding-left: 2rem (wrapped text)
            style.firstLineHeadIndent = 16      // bullet/number starts here
            return style
        }()
    )

    // MARK: - jlmr.dev Dark Theme

    /// Theme matching jlmr.dev website (dark mode)
    static let jlmrDevDark = MarkdownTheme(
        bodyFont: NSFont.systemFont(ofSize: 16, weight: .regular),
        monoFont: NSFont(name: "SFMono-Regular", size: 14.4) ?? NSFont.monospacedSystemFont(ofSize: 14.4, weight: .regular),
        textColor: NSColor(calibratedRed: 0.878, green: 0.878, blue: 0.878, alpha: 1.0), // #e0e0e0
        syntaxColor: NSColor(calibratedRed: 0.533, green: 0.533, blue: 0.533, alpha: 1.0), // #888
        linkColor: NSColor(calibratedRed: 0.427, green: 0.702, blue: 0.949, alpha: 1.0), // #6db3f2
        codeBackgroundColor: NSColor(calibratedRed: 0.165, green: 0.165, blue: 0.165, alpha: 1.0), // #2a2a2a
        blockquoteBorderColor: NSColor(calibratedRed: 0.267, green: 0.267, blue: 0.267, alpha: 1.0), // #444
        blockquoteTextColor: NSColor(calibratedRed: 0.667, green: 0.667, blue: 0.667, alpha: 1.0), // #aaa
        backgroundColor: NSColor(calibratedRed: 0.102, green: 0.102, blue: 0.102, alpha: 1.0), // #1a1a1a
        headingFonts: [
            1: NSFont.systemFont(ofSize: 32, weight: .bold),
            2: NSFont.systemFont(ofSize: 24, weight: .bold),
            3: NSFont.systemFont(ofSize: 20, weight: .bold),
            4: NSFont.systemFont(ofSize: 18, weight: .bold),
            5: NSFont.systemFont(ofSize: 16, weight: .bold),
            6: NSFont.systemFont(ofSize: 14, weight: .bold)
        ],
        headingParagraphStyles: blogHeadingParagraphStyles(),
        bodyParagraphStyle: {
            let style = NSMutableParagraphStyle()
            style.lineHeightMultiple = 1.6
            style.paragraphSpacing = 16
            return style
        }(),
        blockquoteParagraphStyle: {
            let style = NSMutableParagraphStyle()
            style.lineHeightMultiple = 1.6
            style.paragraphSpacingBefore = 24
            style.paragraphSpacing = 24
            style.headIndent = 16
            style.firstLineHeadIndent = 16
            return style
        }(),
        listParagraphStyle: {
            let style = NSMutableParagraphStyle()
            style.lineHeightMultiple = 1.6
            style.paragraphSpacing = 8
            style.headIndent = 32
            style.firstLineHeadIndent = 16
            return style
        }()
    )

    // MARK: - Legacy Themes

    static let `default` = jlmrDev

    static let minimal = MarkdownTheme(
        bodyFont: NSFont(name: "Georgia", size: 16) ?? NSFont.systemFont(ofSize: 16),
        monoFont: NSFont.monospacedSystemFont(ofSize: 14, weight: .regular),
        textColor: NSColor.textColor,
        syntaxColor: NSColor.tertiaryLabelColor.withAlphaComponent(0.5),
        linkColor: NSColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0),
        codeBackgroundColor: NSColor.quaternaryLabelColor.withAlphaComponent(0.2),
        blockquoteBorderColor: NSColor.separatorColor,
        blockquoteTextColor: NSColor.secondaryLabelColor,
        backgroundColor: NSColor.textBackgroundColor,
        headingFonts: [
            1: NSFont(name: "Georgia-Bold", size: 28) ?? NSFont.systemFont(ofSize: 28, weight: .bold),
            2: NSFont(name: "Georgia-Bold", size: 24) ?? NSFont.systemFont(ofSize: 24, weight: .bold),
            3: NSFont(name: "Georgia-Bold", size: 20) ?? NSFont.systemFont(ofSize: 20, weight: .semibold),
            4: NSFont(name: "Georgia-Bold", size: 18) ?? NSFont.systemFont(ofSize: 18, weight: .semibold),
            5: NSFont(name: "Georgia-Bold", size: 16) ?? NSFont.systemFont(ofSize: 16, weight: .medium),
            6: NSFont(name: "Georgia-Bold", size: 14) ?? NSFont.systemFont(ofSize: 14, weight: .medium)
        ],
        headingParagraphStyles: blogHeadingParagraphStyles(),
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
        }(),
        listParagraphStyle: {
            let style = NSMutableParagraphStyle()
            style.lineSpacing = 6
            style.paragraphSpacing = 8
            style.headIndent = 32
            style.firstLineHeadIndent = 16
            return style
        }()
    )
}
