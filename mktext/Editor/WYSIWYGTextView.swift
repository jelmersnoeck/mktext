import SwiftUI
import AppKit

/// SwiftUI wrapper for NSTextView that provides WYSIWYG markdown editing
struct WYSIWYGTextView: NSViewRepresentable {
    @Binding var text: String
    @Binding var isShowingRawMarkdown: Bool

    var onCursorPositionChange: ((Int) -> Void)?

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let textView = NSTextView()

        // Configure scroll view
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = true
        scrollView.backgroundColor = NSColor.textBackgroundColor

        // Configure text view
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

        textView.font = NSFont.systemFont(ofSize: 16)
        textView.textColor = NSColor.textColor
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.insertionPointColor = NSColor.textColor

        textView.autoresizingMask = [.width]
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false

        // Set up text container
        textView.textContainer?.containerSize = NSSize(
            width: scrollView.contentSize.width,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.lineFragmentPadding = 40

        // Set delegate
        textView.delegate = context.coordinator

        scrollView.documentView = textView

        // Store reference in coordinator
        context.coordinator.textView = textView

        // Initial text setup
        textView.string = text
        context.coordinator.applyWYSIWYGStyling()

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }

        // Avoid update loops - only update if text actually changed from outside
        if textView.string != text && !context.coordinator.isInternalUpdate {
            let selectedRanges = textView.selectedRanges
            textView.string = text
            textView.selectedRanges = selectedRanges
            context.coordinator.applyWYSIWYGStyling()
        }

        // Update styling mode if changed
        if context.coordinator.showRawMarkdown != isShowingRawMarkdown {
            context.coordinator.showRawMarkdown = isShowingRawMarkdown
            context.coordinator.applyWYSIWYGStyling()
        }
    }

    func makeCoordinator() -> WYSIWYGCoordinator {
        WYSIWYGCoordinator(self)
    }
}

// MARK: - Preview
#if DEBUG
struct WYSIWYGTextView_Previews: PreviewProvider {
    static var previews: some View {
        WYSIWYGTextView(
            text: .constant("# Hello\n\nThis is **bold** and *italic* text."),
            isShowingRawMarkdown: .constant(false)
        )
        .frame(width: 600, height: 400)
    }
}
#endif
