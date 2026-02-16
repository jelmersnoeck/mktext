import SwiftUI

struct CommentsSidebarView: View {
    @ObservedObject var commentStore: CommentStore
    let theme: MarkdownTheme
    @State private var newCommentText: String = ""
    @State private var showResolved: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Comments")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(theme.textColor))
                Spacer()
                Button(action: { commentStore.showSidebar = false }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11))
                        .foregroundColor(Color(theme.syntaxColor))
                }
                .buttonStyle(.plain)
                .help("Close comments")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            Rectangle()
                .fill(Color(theme.syntaxColor).opacity(0.2))
                .frame(height: 1)

            ScrollView {
                LazyVStack(spacing: 8) {
                    // Add comment card
                    if commentStore.isAddingComment {
                        AddCommentCard(
                            anchorText: commentStore.pendingAnchorText,
                            newCommentText: $newCommentText,
                            theme: theme,
                            onAdd: {
                                guard !newCommentText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                                commentStore.addComment(
                                    range: commentStore.pendingRange,
                                    anchorText: commentStore.pendingAnchorText,
                                    text: newCommentText
                                )
                                newCommentText = ""
                            },
                            onCancel: {
                                commentStore.cancelAdding()
                                newCommentText = ""
                            }
                        )
                    }

                    // Active comments
                    ForEach(commentStore.activeComments) { comment in
                        CommentCard(
                            comment: comment,
                            isSelected: comment.id == commentStore.selectedCommentID,
                            theme: theme,
                            onSelect: { commentStore.selectAndScroll(to: comment) },
                            onResolve: { commentStore.resolveComment(id: comment.id) },
                            onDelete: { commentStore.deleteComment(id: comment.id) }
                        )
                    }

                    // Resolved section
                    if !commentStore.resolvedComments.isEmpty {
                        VStack(spacing: 0) {
                            Button(action: { withAnimation { showResolved.toggle() } }) {
                                HStack {
                                    Image(systemName: showResolved ? "chevron.down" : "chevron.right")
                                        .font(.system(size: 10))
                                    Text("Resolved (\(commentStore.resolvedComments.count))")
                                        .font(.system(size: 12))
                                    Spacer()
                                }
                                .foregroundColor(Color(theme.syntaxColor))
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)

                            if showResolved {
                                ForEach(commentStore.resolvedComments) { comment in
                                    ResolvedCommentCard(
                                        comment: comment,
                                        theme: theme,
                                        onReopen: { commentStore.unresolveComment(id: comment.id) },
                                        onDelete: { commentStore.deleteComment(id: comment.id) }
                                    )
                                }
                            }
                        }
                    }

                    if !commentStore.isAddingComment && commentStore.activeComments.isEmpty && commentStore.resolvedComments.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "text.bubble")
                                .font(.system(size: 24))
                                .foregroundColor(Color(theme.syntaxColor).opacity(0.4))
                            Text("No comments yet")
                                .font(.system(size: 12))
                                .foregroundColor(Color(theme.syntaxColor))
                            Text("Select text and press\nCmd+Option+M")
                                .font(.system(size: 11))
                                .foregroundColor(Color(theme.syntaxColor).opacity(0.6))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 40)
                    }
                }
                .padding(8)
            }
        }
        .background(Color(theme.backgroundColor))
        .overlay(
            Rectangle()
                .fill(Color(theme.syntaxColor).opacity(0.2))
                .frame(width: 1),
            alignment: .leading
        )
    }
}

// MARK: - Add Comment Card

struct AddCommentCard: View {
    let anchorText: String
    @Binding var newCommentText: String
    let theme: MarkdownTheme
    let onAdd: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Anchor text preview
            Text(anchorText.prefix(80) + (anchorText.count > 80 ? "..." : ""))
                .font(.system(size: 11))
                .foregroundColor(Color(theme.syntaxColor))
                .lineLimit(2)

            // Text input
            TextField("Add a comment...", text: $newCommentText, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundColor(Color(theme.textColor))
                .lineLimit(1...5)
                .onSubmit { onAdd() }

            // Action buttons
            HStack {
                Spacer()
                Button("Cancel", action: onCancel)
                    .buttonStyle(.plain)
                    .font(.system(size: 12))
                    .foregroundColor(Color(theme.syntaxColor))

                Button("Comment", action: onAdd)
                    .buttonStyle(.plain)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(theme.linkColor))
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(theme.codeBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(theme.linkColor).opacity(0.5), lineWidth: 1)
        )
    }
}

// MARK: - Comment Card

struct CommentCard: View {
    let comment: Comment
    let isSelected: Bool
    let theme: MarkdownTheme
    let onSelect: () -> Void
    let onResolve: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Anchor text
            if !comment.isOrphaned {
                Text(comment.anchorText.prefix(60) + (comment.anchorText.count > 60 ? "..." : ""))
                    .font(.system(size: 11))
                    .foregroundColor(Color(theme.syntaxColor))
                    .lineLimit(1)
            } else {
                Text("(deleted text)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(theme.syntaxColor).opacity(0.5))
                    .italic()
            }

            // Comment text
            Text(comment.text)
                .font(.system(size: 13))
                .foregroundColor(Color(theme.textColor))
                .fixedSize(horizontal: false, vertical: true)

            // Footer
            HStack {
                Text(comment.relativeTimestamp)
                    .font(.system(size: 11))
                    .foregroundColor(Color(theme.syntaxColor))

                Spacer()

                Button(action: onResolve) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11))
                        .foregroundColor(Color(theme.syntaxColor))
                }
                .buttonStyle(.plain)
                .help("Resolve")

                Button(action: onDelete) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11))
                        .foregroundColor(Color(theme.syntaxColor))
                }
                .buttonStyle(.plain)
                .help("Delete")
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color(theme.commentHighlightColor).opacity(0.3) : Color(theme.codeBackgroundColor))
        )
        .contentShape(Rectangle())
        .onTapGesture { onSelect() }
    }
}

// MARK: - Resolved Comment Card

struct ResolvedCommentCard: View {
    let comment: Comment
    let theme: MarkdownTheme
    let onReopen: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(comment.text)
                .font(.system(size: 12))
                .foregroundColor(Color(theme.syntaxColor))
                .strikethrough()
                .lineLimit(2)

            HStack {
                Text(comment.relativeTimestamp)
                    .font(.system(size: 10))
                    .foregroundColor(Color(theme.syntaxColor).opacity(0.6))

                Spacer()

                Button(action: onReopen) {
                    Text("Reopen")
                        .font(.system(size: 10))
                        .foregroundColor(Color(theme.linkColor))
                }
                .buttonStyle(.plain)

                Button(action: onDelete) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10))
                        .foregroundColor(Color(theme.syntaxColor).opacity(0.5))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(theme.codeBackgroundColor).opacity(0.5))
        )
    }
}
