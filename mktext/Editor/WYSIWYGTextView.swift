import SwiftUI
import AppKit

/// SwiftUI wrapper for NSTextView that provides WYSIWYG markdown editing
struct WYSIWYGTextView: NSViewRepresentable {
    @Binding var text: String
    @Binding var isShowingRawMarkdown: Bool
    var theme: MarkdownTheme

    var onCursorPositionChange: ((Int) -> Void)?

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let textView = NSTextView()

        // Configure scroll view - transparent to show parent background
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        scrollView.backgroundColor = .clear

        // Configure text view with theme colors
        textView.isRichText = true
        textView.allowsUndo = true
        textView.isEditable = true
        textView.isSelectable = true
        textView.usesFindBar = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isAutomaticLinkDetectionEnabled = false
        textView.smartInsertDeleteEnabled = false

        textView.font = theme.bodyFont
        textView.textColor = theme.textColor
        textView.drawsBackground = false
        textView.backgroundColor = .clear
        textView.insertionPointColor = theme.textColor

        textView.autoresizingMask = [.width]
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false

        // Set up text container - minimal padding for clean look
        textView.textContainer?.containerSize = NSSize(
            width: scrollView.contentSize.width,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.lineFragmentPadding = 0

        // Set delegate
        textView.delegate = context.coordinator

        scrollView.documentView = textView

        // Store reference in coordinator
        context.coordinator.textView = textView
        context.coordinator.theme = theme

        // Initial text setup
        textView.string = text
        context.coordinator.applyWYSIWYGStyling()

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }

        // Update theme if changed (e.g., dark mode switch)
        let themeChanged = context.coordinator.theme.backgroundColor != theme.backgroundColor
        if themeChanged {
            context.coordinator.theme = theme
            textView.textColor = theme.textColor
            textView.insertionPointColor = theme.textColor
        }

        // Avoid update loops - only update if text actually changed from outside
        if textView.string != text && !context.coordinator.isInternalUpdate {
            let selectedRanges = textView.selectedRanges
            textView.string = text
            textView.selectedRanges = selectedRanges
            context.coordinator.applyWYSIWYGStyling()
        }

        // Update styling mode if changed
        if context.coordinator.showRawMarkdown != isShowingRawMarkdown || themeChanged {
            context.coordinator.showRawMarkdown = isShowingRawMarkdown
            context.coordinator.applyWYSIWYGStyling()
        }
    }

    func makeCoordinator() -> WYSIWYGCoordinator {
        WYSIWYGCoordinator(self, theme: theme)
    }
}

// MARK: - Preview
#if DEBUG
struct WYSIWYGTextView_Previews: PreviewProvider {
    static var previews: some View {
        WYSIWYGTextView(
            text: .constant("# Hello\n\nThis is **bold** and *italic* text."),
            isShowingRawMarkdown: .constant(false),
            theme: .jlmrDev
        )
        .frame(width: 600, height: 400)
    }
}
#endif
