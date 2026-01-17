import Foundation

/// Represents a parsed markdown element with its position in the source text
struct ParsedElement {
    let type: MarkdownElementType
    let range: NSRange              // Full range including syntax
    let syntaxRanges: [NSRange]     // Ranges of syntax characters (**, _, #, etc.)
    let contentRange: NSRange       // Range of actual content (without syntax)
    let depth: Int                  // Nesting depth for proper ordering

    init(type: MarkdownElementType, range: NSRange, syntaxRanges: [NSRange], contentRange: NSRange, depth: Int = 0) {
        self.type = type
        self.range = range
        self.syntaxRanges = syntaxRanges
        self.contentRange = contentRange
        self.depth = depth
    }
}

/// Types of markdown elements supported
enum MarkdownElementType: Equatable {
    case heading(level: Int)
    case bold
    case italic
    case boldItalic
    case link(url: String, title: String?)
    case orderedListItem(number: Int)
    case unorderedListItem
    case blockquote(level: Int)
    case inlineCode
    case paragraph
    case text
    case lineBreak

    var description: String {
        switch self {
        case .heading(let level): return "Heading \(level)"
        case .bold: return "Bold"
        case .italic: return "Italic"
        case .boldItalic: return "Bold Italic"
        case .link(let url, _): return "Link to \(url)"
        case .orderedListItem(let num): return "Ordered List Item \(num)"
        case .unorderedListItem: return "Unordered List Item"
        case .blockquote(let level): return "Blockquote level \(level)"
        case .inlineCode: return "Inline Code"
        case .paragraph: return "Paragraph"
        case .text: return "Text"
        case .lineBreak: return "Line Break"
        }
    }
}

/// Formatting types for toolbar/keyboard actions
enum FormattingType {
    case bold
    case italic
    case link
    case heading(level: Int)
    case orderedList
    case unorderedList
    case blockquote
    case inlineCode
}
