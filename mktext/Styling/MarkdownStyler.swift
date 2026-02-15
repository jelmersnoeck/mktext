import AppKit

/// Applies visual styling to markdown elements in an NSTextStorage
class MarkdownStyler {
    private let theme: MarkdownTheme

    // Tiny font used to effectively hide syntax characters (takes no space)
    private let hiddenFont = NSFont.systemFont(ofSize: 0.01)

    var defaultAttributes: [NSAttributedString.Key: Any] {
        [
            .font: theme.bodyFont,
            .foregroundColor: theme.textColor,
            .paragraphStyle: theme.bodyParagraphStyle
        ]
    }

    var rawModeAttributes: [NSAttributedString.Key: Any] {
        [
            .font: theme.monoFont,
            .foregroundColor: theme.textColor,
            .paragraphStyle: theme.bodyParagraphStyle
        ]
    }

    init(theme: MarkdownTheme = .default) {
        self.theme = theme
    }

    /// Apply styling to a text storage based on parsed elements
    func applyStyles(
        to textStorage: NSTextStorage,
        elements: [ParsedElement],
        cursorPosition: Int,
        showRawMarkdown: Bool
    ) {
        let text = textStorage.string
        guard !text.isEmpty else { return }

        textStorage.beginEditing()

        // Reset to default or raw mode style
        let fullRange = NSRange(location: 0, length: text.count)
        if showRawMarkdown {
            textStorage.setAttributes(rawModeAttributes, range: fullRange)
            // In raw mode, show syntax with highlight color
            for element in elements {
                for syntaxRange in element.syntaxRanges {
                    guard isValidRange(syntaxRange, in: text) else { continue }
                    textStorage.addAttribute(.foregroundColor, value: theme.syntaxColor, range: syntaxRange)
                }
            }
        } else {
            textStorage.setAttributes(defaultAttributes, range: fullRange)

            // Sort elements by depth (innermost first) to handle nesting correctly
            let sortedElements = elements.sorted { $0.depth > $1.depth }

            for element in sortedElements {
                let cursorInElement = NSLocationInRange(cursorPosition, element.range)
                applyStyle(
                    to: textStorage,
                    element: element,
                    revealSyntax: cursorInElement,
                    textLength: text.count
                )
            }
        }

        textStorage.endEditing()
    }

    /// Apply styling for a single element
    private func applyStyle(
        to textStorage: NSTextStorage,
        element: ParsedElement,
        revealSyntax: Bool,
        textLength: Int
    ) {
        switch element.type {
        case .heading(let level):
            applyHeadingStyle(textStorage, element, level: level, reveal: revealSyntax, textLength: textLength)

        case .bold:
            applyBoldStyle(textStorage, element, reveal: revealSyntax, textLength: textLength)

        case .italic:
            applyItalicStyle(textStorage, element, reveal: revealSyntax, textLength: textLength)

        case .boldItalic:
            applyBoldItalicStyle(textStorage, element, reveal: revealSyntax, textLength: textLength)

        case .link(let url, _):
            applyLinkStyle(textStorage, element, url: url, reveal: revealSyntax, textLength: textLength)

        case .orderedListItem, .unorderedListItem:
            applyListStyle(textStorage, element, reveal: revealSyntax, textLength: textLength)

        case .blockquote:
            applyBlockquoteStyle(textStorage, element, reveal: revealSyntax, textLength: textLength)

        case .inlineCode:
            applyInlineCodeStyle(textStorage, element, reveal: revealSyntax, textLength: textLength)

        case .paragraph, .text, .lineBreak:
            break
        }
    }

    // MARK: - Syntax Hiding

    /// Hide syntax characters by making them effectively invisible and zero-width
    private func hideSyntax(_ storage: NSTextStorage, range: NSRange, textLength: Int) {
        guard isValidRange(range, in: textLength) else { return }

        // Use tiny font to collapse the characters (takes no horizontal space)
        storage.addAttribute(.font, value: hiddenFont, range: range)
        // Make invisible
        storage.addAttribute(.foregroundColor, value: NSColor.clear, range: range)
        // Remove any baseline offset that might cause visual issues
        storage.addAttribute(.baselineOffset, value: 0, range: range)
    }

    /// Show syntax characters with the syntax color
    private func showSyntax(_ storage: NSTextStorage, range: NSRange, font: NSFont, textLength: Int) {
        guard isValidRange(range, in: textLength) else { return }

        storage.addAttribute(.font, value: font, range: range)
        storage.addAttribute(.foregroundColor, value: theme.syntaxColor, range: range)
    }

    // MARK: - Individual Style Applications

    private func applyHeadingStyle(
        _ storage: NSTextStorage,
        _ element: ParsedElement,
        level: Int,
        reveal: Bool,
        textLength: Int
    ) {
        guard isValidRange(element.contentRange, in: textLength) else { return }

        let font = theme.headingFont(level: level)
        let paragraphStyle = theme.headingParagraphStyle(level: level)

        // Apply heading font and paragraph style to the entire range
        if reveal {
            storage.addAttribute(.font, value: font, range: element.range)
        } else {
            storage.addAttribute(.font, value: font, range: element.contentRange)
        }
        storage.addAttribute(.paragraphStyle, value: paragraphStyle, range: element.range)

        // Handle syntax visibility (# characters)
        for syntaxRange in element.syntaxRanges {
            if reveal {
                showSyntax(storage, range: syntaxRange, font: font, textLength: textLength)
            } else {
                hideSyntax(storage, range: syntaxRange, textLength: textLength)
            }
        }
    }

    private func applyBoldStyle(
        _ storage: NSTextStorage,
        _ element: ParsedElement,
        reveal: Bool,
        textLength: Int
    ) {
        guard isValidRange(element.contentRange, in: textLength) else { return }

        // Use semibold (weight 600) to match blog's strong { font-weight: 600 }
        let currentFont = storage.attribute(.font, at: element.contentRange.location, effectiveRange: nil) as? NSFont ?? theme.bodyFont
        let boldFont = NSFont.systemFont(ofSize: currentFont.pointSize, weight: .semibold)
        storage.addAttribute(.font, value: boldFont, range: element.contentRange)

        // Handle ** syntax visibility
        for syntaxRange in element.syntaxRanges {
            if reveal {
                showSyntax(storage, range: syntaxRange, font: currentFont, textLength: textLength)
            } else {
                hideSyntax(storage, range: syntaxRange, textLength: textLength)
            }
        }
    }

    private func applyItalicStyle(
        _ storage: NSTextStorage,
        _ element: ParsedElement,
        reveal: Bool,
        textLength: Int
    ) {
        guard isValidRange(element.contentRange, in: textLength) else { return }

        let currentFont = storage.attribute(.font, at: element.contentRange.location, effectiveRange: nil) as? NSFont ?? theme.bodyFont
        let italicFont = NSFontManager.shared.convert(currentFont, toHaveTrait: .italicFontMask)
        storage.addAttribute(.font, value: italicFont, range: element.contentRange)

        for syntaxRange in element.syntaxRanges {
            if reveal {
                showSyntax(storage, range: syntaxRange, font: currentFont, textLength: textLength)
            } else {
                hideSyntax(storage, range: syntaxRange, textLength: textLength)
            }
        }
    }

    private func applyBoldItalicStyle(
        _ storage: NSTextStorage,
        _ element: ParsedElement,
        reveal: Bool,
        textLength: Int
    ) {
        guard isValidRange(element.contentRange, in: textLength) else { return }

        // Use semibold + italic to match blog's strong { font-weight: 600 }
        let currentFont = storage.attribute(.font, at: element.contentRange.location, effectiveRange: nil) as? NSFont ?? theme.bodyFont
        let semiboldFont = NSFont.systemFont(ofSize: currentFont.pointSize, weight: .semibold)
        let boldItalicFont = NSFontManager.shared.convert(semiboldFont, toHaveTrait: .italicFontMask)
        storage.addAttribute(.font, value: boldItalicFont, range: element.contentRange)

        for syntaxRange in element.syntaxRanges {
            if reveal {
                showSyntax(storage, range: syntaxRange, font: currentFont, textLength: textLength)
            } else {
                hideSyntax(storage, range: syntaxRange, textLength: textLength)
            }
        }
    }

    private func applyLinkStyle(
        _ storage: NSTextStorage,
        _ element: ParsedElement,
        url: String,
        reveal: Bool,
        textLength: Int
    ) {
        guard isValidRange(element.contentRange, in: textLength) else { return }

        // Style the link text
        storage.addAttribute(.foregroundColor, value: theme.linkColor, range: element.contentRange)
        storage.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: element.contentRange)

        if let linkURL = URL(string: url) {
            storage.addAttribute(.link, value: linkURL, range: element.contentRange)
        }

        // Handle [ ] ( ) and URL visibility
        let currentFont = storage.attribute(.font, at: element.contentRange.location, effectiveRange: nil) as? NSFont ?? theme.bodyFont
        for syntaxRange in element.syntaxRanges {
            if reveal {
                showSyntax(storage, range: syntaxRange, font: currentFont, textLength: textLength)
            } else {
                hideSyntax(storage, range: syntaxRange, textLength: textLength)
            }
        }
    }

    private func applyListStyle(
        _ storage: NSTextStorage,
        _ element: ParsedElement,
        reveal: Bool,
        textLength: Int
    ) {
        guard isValidRange(element.range, in: textLength) else { return }

        // Apply list paragraph style (indentation and spacing)
        storage.addAttribute(.paragraphStyle, value: theme.listParagraphStyle, range: element.range)

        // Keep list markers visible but styled
        let currentFont = storage.attribute(.font, at: element.range.location, effectiveRange: nil) as? NSFont ?? theme.bodyFont

        for syntaxRange in element.syntaxRanges {
            guard isValidRange(syntaxRange, in: textLength) else { continue }

            if reveal {
                // Show the original markdown syntax
                showSyntax(storage, range: syntaxRange, font: currentFont, textLength: textLength)
            } else {
                // Style the bullet/number subtly
                storage.addAttribute(.foregroundColor, value: theme.syntaxColor.withAlphaComponent(0.6), range: syntaxRange)
            }
        }
    }

    private func applyBlockquoteStyle(
        _ storage: NSTextStorage,
        _ element: ParsedElement,
        reveal: Bool,
        textLength: Int
    ) {
        guard isValidRange(element.range, in: textLength) else { return }

        // Apply blockquote paragraph style
        storage.addAttribute(.paragraphStyle, value: theme.blockquoteParagraphStyle, range: element.range)

        if isValidRange(element.contentRange, in: textLength) {
            storage.addAttribute(.foregroundColor, value: theme.blockquoteTextColor, range: element.contentRange)
        }

        // Handle > syntax visibility
        let currentFont = storage.attribute(.font, at: element.range.location, effectiveRange: nil) as? NSFont ?? theme.bodyFont
        for syntaxRange in element.syntaxRanges {
            if reveal {
                showSyntax(storage, range: syntaxRange, font: currentFont, textLength: textLength)
            } else {
                hideSyntax(storage, range: syntaxRange, textLength: textLength)
            }
        }
    }

    private func applyInlineCodeStyle(
        _ storage: NSTextStorage,
        _ element: ParsedElement,
        reveal: Bool,
        textLength: Int
    ) {
        guard isValidRange(element.contentRange, in: textLength) else { return }

        // Apply monospace font and background
        storage.addAttribute(.font, value: theme.monoFont, range: element.contentRange)
        storage.addAttribute(.backgroundColor, value: theme.codeBackgroundColor, range: element.contentRange)

        // Handle ` syntax visibility
        for syntaxRange in element.syntaxRanges {
            if reveal {
                showSyntax(storage, range: syntaxRange, font: theme.monoFont, textLength: textLength)
            } else {
                hideSyntax(storage, range: syntaxRange, textLength: textLength)
            }
        }
    }

    // MARK: - Helpers

    private func isValidRange(_ range: NSRange, in textLength: Int) -> Bool {
        return range.location >= 0 &&
               range.length >= 0 &&
               range.location + range.length <= textLength
    }

    private func isValidRange(_ range: NSRange, in text: String) -> Bool {
        return isValidRange(range, in: text.count)
    }
}
