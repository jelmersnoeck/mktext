import Foundation
import AppKit
import Combine

class CommentStore: ObservableObject {
    @Published var comments: [Comment] = []
    @Published var selectedCommentID: UUID?
    @Published var isAddingComment: Bool = false
    @Published var showSidebar: Bool = false

    // Pending comment state (set by coordinator when user triggers "add comment")
    @Published var pendingRange: NSRange = NSRange(location: 0, length: 0)
    @Published var pendingAnchorText: String = ""

    private(set) var fileURL: URL?

    /// Called by coordinator when it wants to scroll editor to a comment
    var onScrollToRange: ((NSRange) -> Void)?

    var sidecarURL: URL? {
        fileURL.map { $0.appendingPathExtension("mktext") }
    }

    var activeComments: [Comment] {
        comments.filter { !$0.resolved }.sorted { $0.rangeLocation < $1.rangeLocation }
    }

    var resolvedComments: [Comment] {
        comments.filter { $0.resolved }.sorted { $0.createdAt > $1.createdAt }
    }

    var activeCount: Int {
        comments.filter { !$0.resolved }.count
    }

    // MARK: - Persistence

    func load(for url: URL?) {
        self.fileURL = url
        guard let sidecarURL = sidecarURL else { return }
        guard FileManager.default.fileExists(atPath: sidecarURL.path) else { return }

        do {
            let data = try Data(contentsOf: sidecarURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            comments = try decoder.decode([Comment].self, from: data)
        } catch {
            print("Failed to load comments: \(error)")
        }
    }

    func save() {
        guard let sidecarURL = sidecarURL else { return }

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(comments)
            try data.write(to: sidecarURL, options: .atomic)
        } catch {
            print("Failed to save comments: \(error)")
        }
    }

    // MARK: - Actions

    func addComment(range: NSRange, anchorText: String, text: String) {
        let comment = Comment(range: range, anchorText: anchorText, text: text)
        comments.append(comment)
        selectedCommentID = comment.id
        isAddingComment = false
        save()
    }

    func resolveComment(id: UUID) {
        guard let index = comments.firstIndex(where: { $0.id == id }) else { return }
        comments[index].resolved = true
        if selectedCommentID == id { selectedCommentID = nil }
        save()
    }

    func unresolveComment(id: UUID) {
        guard let index = comments.firstIndex(where: { $0.id == id }) else { return }
        comments[index].resolved = false
        save()
    }

    func deleteComment(id: UUID) {
        comments.removeAll { $0.id == id }
        if selectedCommentID == id { selectedCommentID = nil }
        save()
    }

    func selectAndScroll(to comment: Comment) {
        selectedCommentID = comment.id
        if !comment.isOrphaned {
            onScrollToRange?(comment.range)
        }
    }

    func cancelAdding() {
        isAddingComment = false
        pendingAnchorText = ""
        pendingRange = NSRange(location: 0, length: 0)
    }

    // MARK: - Range Remapping

    /// Remap all comment ranges after a text edit.
    /// Called from coordinator's shouldChangeTextIn delegate method.
    func remapRanges(editLocation: Int, oldLength: Int, newLength: Int) {
        let delta = newLength - oldLength
        guard delta != 0 else { return }
        let editEnd = editLocation + oldLength

        for i in comments.indices where !comments[i].resolved {
            let cStart = comments[i].rangeLocation
            let cEnd = cStart + comments[i].rangeLength

            if cEnd <= editLocation {
                // Comment entirely before edit — no change
                continue
            } else if cStart >= editEnd {
                // Comment entirely after edit — shift
                comments[i].rangeLocation += delta
            } else if cStart <= editLocation && cEnd >= editEnd {
                // Edit is inside the comment — expand/shrink
                comments[i].rangeLength += delta
            } else if cStart >= editLocation && cEnd <= editEnd {
                // Edit encompasses entire comment — orphan it
                comments[i].rangeLocation = editLocation
                comments[i].rangeLength = 0
            } else if cStart < editLocation {
                // Edit overlaps end of comment
                comments[i].rangeLength = editLocation - cStart
            } else {
                // Edit overlaps start of comment
                let remaining = cEnd - editEnd
                comments[i].rangeLocation = editLocation + newLength
                comments[i].rangeLength = max(0, remaining)
            }

            // Safety clamp
            if comments[i].rangeLength < 0 {
                comments[i].rangeLength = 0
            }
        }
    }

    /// Re-anchor comments by searching for anchorText near the stored range.
    /// Called on load when the .md may have been edited externally.
    func reanchorIfNeeded(documentText: String) {
        let nsText = documentText as NSString
        guard nsText.length > 0 else { return }

        for i in comments.indices {
            let range = comments[i].range

            // Check if current range still matches anchor text
            if range.location + range.length <= nsText.length {
                let currentText = nsText.substring(with: range)
                if currentText == comments[i].anchorText {
                    continue
                }
            }

            // Search nearby for anchor text
            let searchRadius = 500
            let searchStart = max(0, range.location - searchRadius)
            let searchEnd = min(nsText.length, range.location + range.length + searchRadius)
            let searchRange = NSRange(location: searchStart, length: searchEnd - searchStart)

            let foundRange = nsText.range(of: comments[i].anchorText, options: [], range: searchRange)
            if foundRange.location != NSNotFound {
                comments[i].rangeLocation = foundRange.location
                comments[i].rangeLength = foundRange.length
            }
        }
    }
}
