import Foundation
import Markdown

/// Parses markdown text and extracts elements with their positions
class MarkdownParser {
    private var source: String = ""
    private var lineStartOffsets: [Int] = []

    /// Parse markdown text and return all elements with their positions
    func parse(_ text: String) -> [ParsedElement] {
        self.source = text
        self.lineStartOffsets = computeLineOffsets(text)

        let document = Document(parsing: text, options: [])
        var walker = ElementWalker(parser: self)
        walker.visit(document)

        return walker.elements
    }

    /// Compute byte offsets for each line start
    private func computeLineOffsets(_ text: String) -> [Int] {
        var offsets: [Int] = [0]
        var offset = 0
        for char in text {
            offset += 1
            if char == "\n" {
                offsets.append(offset)
            }
        }
        return offsets
    }

    /// Convert swift-markdown SourceLocation to character offset
    func offset(for location: SourceLocation) -> Int {
        guard location.line > 0, location.line <= lineStartOffsets.count else {
            return 0
        }
        let lineStart = lineStartOffsets[location.line - 1]
        return lineStart + location.column - 1
    }

    /// Convert swift-markdown SourceRange to NSRange
    func nsRange(for range: SourceRange) -> NSRange {
        let start = offset(for: range.lowerBound)
        let end = offset(for: range.upperBound)
        return NSRange(location: start, length: max(0, end - start))
    }
}

/// Walker that visits markdown AST and extracts elements
private struct ElementWalker: MarkupWalker {
    let parser: MarkdownParser
    var elements: [ParsedElement] = []
    var currentDepth: Int = 0

    init(parser: MarkdownParser) {
        self.parser = parser
    }

    mutating func visitHeading(_ heading: Heading) -> () {
        guard let sourceRange = heading.range else {
            descendInto(heading)
            return
        }

        let range = parser.nsRange(for: sourceRange)
        let prefixLength = heading.level + 1 // # characters + space
        let syntaxRange = NSRange(location: range.location, length: min(prefixLength, range.length))
        let contentStart = range.location + prefixLength
        let contentLength = max(0, range.length - prefixLength)
        let contentRange = NSRange(location: contentStart, length: contentLength)

        elements.append(ParsedElement(
            type: .heading(level: heading.level),
            range: range,
            syntaxRanges: [syntaxRange],
            contentRange: contentRange,
            depth: currentDepth
        ))

        currentDepth += 1
        descendInto(heading)
        currentDepth -= 1
    }

    mutating func visitStrong(_ strong: Strong) -> () {
        guard let sourceRange = strong.range else {
            descendInto(strong)
            return
        }

        let range = parser.nsRange(for: sourceRange)
        guard range.length >= 4 else {
            descendInto(strong)
            return
        }

        let openSyntax = NSRange(location: range.location, length: 2)
        let closeSyntax = NSRange(location: range.location + range.length - 2, length: 2)
        let contentRange = NSRange(location: range.location + 2, length: range.length - 4)

        elements.append(ParsedElement(
            type: .bold,
            range: range,
            syntaxRanges: [openSyntax, closeSyntax],
            contentRange: contentRange,
            depth: currentDepth
        ))

        currentDepth += 1
        descendInto(strong)
        currentDepth -= 1
    }

    mutating func visitEmphasis(_ emphasis: Emphasis) -> () {
        guard let sourceRange = emphasis.range else {
            descendInto(emphasis)
            return
        }

        let range = parser.nsRange(for: sourceRange)
        guard range.length >= 2 else {
            descendInto(emphasis)
            return
        }

        let openSyntax = NSRange(location: range.location, length: 1)
        let closeSyntax = NSRange(location: range.location + range.length - 1, length: 1)
        let contentRange = NSRange(location: range.location + 1, length: range.length - 2)

        elements.append(ParsedElement(
            type: .italic,
            range: range,
            syntaxRanges: [openSyntax, closeSyntax],
            contentRange: contentRange,
            depth: currentDepth
        ))

        currentDepth += 1
        descendInto(emphasis)
        currentDepth -= 1
    }

    mutating func visitLink(_ link: Link) -> () {
        guard let sourceRange = link.range else {
            descendInto(link)
            return
        }

        let range = parser.nsRange(for: sourceRange)
        let url = link.destination ?? ""
        let title = link.title

        // Link format: [text](url) or [text](url "title")
        // We need to find where the text ends and URL begins
        // The content is between [ and ]
        let openBracket = NSRange(location: range.location, length: 1)

        // Find the ] position by looking at child text
        var textLength = 0
        for child in link.children {
            if let childRange = child.range {
                let childNSRange = parser.nsRange(for: childRange)
                textLength = childNSRange.location + childNSRange.length - range.location - 1
            }
        }

        let closeBracket = NSRange(location: range.location + 1 + textLength, length: 1)
        let urlPartStart = closeBracket.location + closeBracket.length
        let urlPartLength = range.length - (urlPartStart - range.location)
        let urlPart = NSRange(location: urlPartStart, length: urlPartLength)

        let contentRange = NSRange(location: range.location + 1, length: textLength)

        elements.append(ParsedElement(
            type: .link(url: url, title: title),
            range: range,
            syntaxRanges: [openBracket, closeBracket, urlPart],
            contentRange: contentRange,
            depth: currentDepth
        ))

        currentDepth += 1
        descendInto(link)
        currentDepth -= 1
    }

    mutating func visitListItem(_ listItem: ListItem) -> () {
        guard let sourceRange = listItem.range else {
            descendInto(listItem)
            return
        }

        let range = parser.nsRange(for: sourceRange)

        // Determine if ordered or unordered based on parent
        let isOrdered = listItem.parent is OrderedList

        // List item prefix is typically "- " or "* " for unordered, "1. " for ordered
        let prefixLength: Int
        if isOrdered {
            // Ordered list: "1. " or "10. " etc.
            prefixLength = 3 // Approximate
        } else {
            // Unordered: "- " or "* "
            prefixLength = 2
        }

        let syntaxRange = NSRange(location: range.location, length: min(prefixLength, range.length))
        let contentRange = NSRange(
            location: range.location + prefixLength,
            length: max(0, range.length - prefixLength)
        )

        let elementType: MarkdownElementType
        if isOrdered {
            // Try to get the number
            let number = Int((listItem.parent as? OrderedList)?.startIndex ?? 1)
            elementType = .orderedListItem(number: number)
        } else {
            elementType = .unorderedListItem
        }

        elements.append(ParsedElement(
            type: elementType,
            range: range,
            syntaxRanges: [syntaxRange],
            contentRange: contentRange,
            depth: currentDepth
        ))

        currentDepth += 1
        descendInto(listItem)
        currentDepth -= 1
    }

    mutating func visitBlockQuote(_ blockQuote: BlockQuote) -> () {
        guard let sourceRange = blockQuote.range else {
            descendInto(blockQuote)
            return
        }

        let range = parser.nsRange(for: sourceRange)

        // Blockquote prefix "> "
        let prefixLength = 2
        let syntaxRange = NSRange(location: range.location, length: min(prefixLength, range.length))
        let contentRange = NSRange(
            location: range.location + prefixLength,
            length: max(0, range.length - prefixLength)
        )

        // Count nesting level
        var level = 1
        var parent = blockQuote.parent
        while parent != nil {
            if parent is BlockQuote {
                level += 1
            }
            parent = parent?.parent
        }

        elements.append(ParsedElement(
            type: .blockquote(level: level),
            range: range,
            syntaxRanges: [syntaxRange],
            contentRange: contentRange,
            depth: currentDepth
        ))

        currentDepth += 1
        descendInto(blockQuote)
        currentDepth -= 1
    }

    mutating func visitInlineCode(_ inlineCode: InlineCode) -> () {
        guard let sourceRange = inlineCode.range else {
            return
        }

        let range = parser.nsRange(for: sourceRange)
        guard range.length >= 2 else { return }

        let openSyntax = NSRange(location: range.location, length: 1)
        let closeSyntax = NSRange(location: range.location + range.length - 1, length: 1)
        let contentRange = NSRange(location: range.location + 1, length: range.length - 2)

        elements.append(ParsedElement(
            type: .inlineCode,
            range: range,
            syntaxRanges: [openSyntax, closeSyntax],
            contentRange: contentRange,
            depth: currentDepth
        ))
    }

    mutating func defaultVisit(_ markup: any Markup) -> () {
        descendInto(markup)
    }
}
