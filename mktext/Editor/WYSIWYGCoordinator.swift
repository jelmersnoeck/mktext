import AppKit
import Combine

/// Coordinator that manages the NSTextView delegate and WYSIWYG styling
class WYSIWYGCoordinator: NSObject, NSTextViewDelegate {
    var parent: WYSIWYGTextView
    weak var textView: NSTextView?

    private let parser = MarkdownParser()
    private var styler: MarkdownStyler
    var theme: MarkdownTheme {
        didSet {
            styler = MarkdownStyler(theme: theme)
        }
    }

    let commentStore: CommentStore

    private var currentCursorPosition: Int = 0
    var showRawMarkdown: Bool = false
    var isInternalUpdate: Bool = false

    private var notificationObservers: [NSObjectProtocol] = []
    private var stylingWorkItem: DispatchWorkItem?

    /// Tracks the pending edit for comment range remapping
    private var pendingEdit: (range: NSRange, newLength: Int)?

    init(_ parent: WYSIWYGTextView, theme: MarkdownTheme, commentStore: CommentStore) {
        self.parent = parent
        self.theme = theme
        self.styler = MarkdownStyler(theme: theme)
        self.commentStore = commentStore
        super.init()
        setupNotificationObservers()
        setupCommentStoreCallbacks()
    }

    deinit {
        notificationObservers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    private func setupCommentStoreCallbacks() {
        commentStore.onScrollToRange = { [weak self] range in
            guard let textView = self?.textView else { return }
            textView.scrollRangeToVisible(range)
            textView.showFindIndicator(for: range)
        }
    }

    // MARK: - Notification Observers

    private func setupNotificationObservers() {
        let boldObserver = NotificationCenter.default.addObserver(
            forName: .formatBold, object: nil, queue: .main
        ) { [weak self] _ in
            self?.applyFormatting(.bold)
        }

        let italicObserver = NotificationCenter.default.addObserver(
            forName: .formatItalic, object: nil, queue: .main
        ) { [weak self] _ in
            self?.applyFormatting(.italic)
        }

        let linkObserver = NotificationCenter.default.addObserver(
            forName: .formatLink, object: nil, queue: .main
        ) { [weak self] _ in
            self?.applyFormatting(.link)
        }

        let headingObserver = NotificationCenter.default.addObserver(
            forName: .formatHeading, object: nil, queue: .main
        ) { [weak self] notification in
            if let level = notification.object as? Int {
                self?.applyFormatting(.heading(level: level))
            }
        }

        let toggleObserver = NotificationCenter.default.addObserver(
            forName: .toggleRawMarkdown, object: nil, queue: .main
        ) { [weak self] _ in
            self?.parent.isShowingRawMarkdown.toggle()
        }

        let listObserver = NotificationCenter.default.addObserver(
            forName: .formatList, object: nil, queue: .main
        ) { [weak self] notification in
            if let listType = notification.object as? String {
                if listType == "ordered" {
                    self?.applyFormatting(.orderedList)
                } else {
                    self?.applyFormatting(.unorderedList)
                }
            }
        }

        let blockquoteObserver = NotificationCenter.default.addObserver(
            forName: .formatBlockquote, object: nil, queue: .main
        ) { [weak self] _ in
            self?.applyFormatting(.blockquote)
        }

        let addCommentObserver = NotificationCenter.default.addObserver(
            forName: .addComment, object: nil, queue: .main
        ) { [weak self] _ in
            self?.beginAddComment()
        }

        let toggleCommentsObserver = NotificationCenter.default.addObserver(
            forName: .toggleCommentsSidebar, object: nil, queue: .main
        ) { [weak self] _ in
            self?.commentStore.showSidebar.toggle()
        }

        notificationObservers = [
            boldObserver, italicObserver, linkObserver, headingObserver,
            toggleObserver, listObserver, blockquoteObserver,
            addCommentObserver, toggleCommentsObserver
        ]
    }

    // MARK: - NSTextViewDelegate

    func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
        // Capture edit info for range remapping in textDidChange
        pendingEdit = (range: affectedCharRange, newLength: replacementString?.count ?? 0)
        return true
    }

    func textDidChange(_ notification: Notification) {
        guard let textView = notification.object as? NSTextView else { return }

        // Remap comment ranges based on the edit
        if let edit = pendingEdit {
            commentStore.remapRanges(
                editLocation: edit.range.location,
                oldLength: edit.range.length,
                newLength: edit.newLength
            )
            pendingEdit = nil
        }

        // Update parent binding
        isInternalUpdate = true
        parent.text = textView.string
        isInternalUpdate = false

        // Debounce styling updates for performance
        scheduleStylingUpdate()
    }

    func textViewDidChangeSelection(_ notification: Notification) {
        guard let textView = notification.object as? NSTextView else { return }

        let newPosition = textView.selectedRange().location
        if newPosition != currentCursorPosition {
            currentCursorPosition = newPosition
            parent.onCursorPositionChange?(newPosition)

            // Re-apply styling to show/hide syntax at new cursor position
            scheduleStylingUpdate()
        }
    }

    func textView(_ textView: NSTextView, clickedOnLink link: Any, at charIndex: Int) -> Bool {
        // Handle link clicks - Cmd+click opens link
        if NSEvent.modifierFlags.contains(.command) {
            if let url = link as? URL {
                NSWorkspace.shared.open(url)
                return true
            } else if let urlString = link as? String, let url = URL(string: urlString) {
                NSWorkspace.shared.open(url)
                return true
            }
        }
        // Return false to allow normal editing
        return false
    }

    // MARK: - Styling

    private func scheduleStylingUpdate() {
        stylingWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.applyWYSIWYGStyling()
        }
        stylingWorkItem = workItem
        // Small delay for debouncing during rapid typing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: workItem)
    }

    func applyWYSIWYGStyling() {
        guard let textView = textView,
              let textStorage = textView.textStorage else { return }

        let text = textView.string
        guard !text.isEmpty else { return }

        // Save selection
        let savedSelection = textView.selectedRanges

        // Parse markdown
        let elements = parser.parse(text)

        // Apply markdown styling
        styler.applyStyles(
            to: textStorage,
            elements: elements,
            cursorPosition: currentCursorPosition,
            showRawMarkdown: showRawMarkdown
        )

        // Apply comment highlights on top
        styler.applyCommentHighlights(
            to: textStorage,
            comments: commentStore.comments,
            selectedCommentID: commentStore.selectedCommentID
        )

        // Restore selection
        textView.selectedRanges = savedSelection
    }

    // MARK: - Comments

    private func beginAddComment() {
        guard let textView = textView else { return }
        let range = textView.selectedRange()
        guard range.length > 0 else { return }

        let anchorText = (textView.string as NSString).substring(with: range)
        commentStore.pendingRange = range
        commentStore.pendingAnchorText = anchorText
        commentStore.isAddingComment = true
        commentStore.showSidebar = true
    }

    // MARK: - Formatting Actions

    func applyFormatting(_ type: FormattingType) {
        guard let textView = textView else { return }

        let selectedRange = textView.selectedRange()
        let selectedText = (textView.string as NSString).substring(with: selectedRange)

        let (replacement, cursorAdjustment) = formattingReplacement(for: type, selectedText: selectedText)

        // Insert the formatted text
        if textView.shouldChangeText(in: selectedRange, replacementString: replacement) {
            textView.replaceCharacters(in: selectedRange, with: replacement)
            textView.didChangeText()

            // Adjust cursor position
            let newCursorPosition = selectedRange.location + cursorAdjustment
            textView.setSelectedRange(NSRange(location: newCursorPosition, length: 0))
        }
    }

    private func formattingReplacement(for type: FormattingType, selectedText: String) -> (String, Int) {
        switch type {
        case .bold:
            let replacement = "**\(selectedText)**"
            let cursorOffset = selectedText.isEmpty ? 2 : replacement.count
            return (replacement, cursorOffset)

        case .italic:
            let replacement = "*\(selectedText)*"
            let cursorOffset = selectedText.isEmpty ? 1 : replacement.count
            return (replacement, cursorOffset)

        case .link:
            let replacement = "[\(selectedText)](url)"
            let cursorOffset: Int
            if selectedText.isEmpty {
                cursorOffset = 1 // Position after [
            } else {
                cursorOffset = selectedText.count + 3 // Position after ](
            }
            return (replacement, cursorOffset)

        case .heading(let level):
            let prefix = String(repeating: "#", count: level) + " "
            let replacement = prefix + selectedText
            return (replacement, replacement.count)

        case .orderedList:
            let replacement = "1. \(selectedText)"
            return (replacement, replacement.count)

        case .unorderedList:
            let replacement = "- \(selectedText)"
            return (replacement, replacement.count)

        case .blockquote:
            let replacement = "> \(selectedText)"
            return (replacement, replacement.count)

        case .inlineCode:
            let replacement = "`\(selectedText)`"
            let cursorOffset = selectedText.isEmpty ? 1 : replacement.count
            return (replacement, cursorOffset)
        }
    }
}
