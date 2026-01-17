import XCTest
@testable import mktext

final class MarkdownParserTests: XCTestCase {

    let parser = MarkdownParser()

    func testParseHeading() {
        let text = "# Hello World"
        let elements = parser.parse(text)

        XCTAssertFalse(elements.isEmpty, "Should parse at least one element")

        let headings = elements.filter {
            if case .heading = $0.type { return true }
            return false
        }
        XCTAssertEqual(headings.count, 1, "Should find one heading")

        if case .heading(let level) = headings.first?.type {
            XCTAssertEqual(level, 1, "Should be level 1 heading")
        }
    }

    func testParseBold() {
        let text = "This is **bold** text"
        let elements = parser.parse(text)

        let boldElements = elements.filter {
            if case .bold = $0.type { return true }
            return false
        }
        XCTAssertEqual(boldElements.count, 1, "Should find one bold element")
    }

    func testParseItalic() {
        let text = "This is *italic* text"
        let elements = parser.parse(text)

        let italicElements = elements.filter {
            if case .italic = $0.type { return true }
            return false
        }
        XCTAssertEqual(italicElements.count, 1, "Should find one italic element")
    }

    func testParseLink() {
        let text = "Check out [this link](https://example.com)"
        let elements = parser.parse(text)

        let linkElements = elements.filter {
            if case .link = $0.type { return true }
            return false
        }
        XCTAssertEqual(linkElements.count, 1, "Should find one link element")

        if case .link(let url, _) = linkElements.first?.type {
            XCTAssertEqual(url, "https://example.com", "Should have correct URL")
        }
    }

    func testParseUnorderedList() {
        let text = "- Item one\n- Item two"
        let elements = parser.parse(text)

        let listItems = elements.filter {
            if case .unorderedListItem = $0.type { return true }
            return false
        }
        XCTAssertEqual(listItems.count, 2, "Should find two list items")
    }

    func testParseBlockquote() {
        let text = "> This is a quote"
        let elements = parser.parse(text)

        let blockquotes = elements.filter {
            if case .blockquote = $0.type { return true }
            return false
        }
        XCTAssertEqual(blockquotes.count, 1, "Should find one blockquote")
    }

    func testComplexDocument() {
        let text = """
        # Welcome

        This is **bold** and *italic* text.

        - List item one
        - List item two

        > A blockquote

        [A link](https://example.com)
        """

        let elements = parser.parse(text)
        XCTAssertFalse(elements.isEmpty, "Should parse multiple elements")

        // Should have at least: heading, bold, italic, 2 list items, blockquote, link
        XCTAssertGreaterThanOrEqual(elements.count, 6, "Should have at least 6 elements")
    }
}
