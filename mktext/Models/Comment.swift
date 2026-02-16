import Foundation

struct Comment: Codable, Identifiable {
    let id: UUID
    var anchorText: String
    var text: String
    let createdAt: Date
    var resolved: Bool

    // NSRange isn't Codable — store components directly
    var rangeLocation: Int
    var rangeLength: Int

    var range: NSRange {
        get { NSRange(location: rangeLocation, length: rangeLength) }
        set {
            rangeLocation = newValue.location
            rangeLength = newValue.length
        }
    }

    var isOrphaned: Bool { rangeLength <= 0 }

    var relativeTimestamp: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }

    init(
        id: UUID = UUID(),
        range: NSRange,
        anchorText: String,
        text: String,
        createdAt: Date = Date(),
        resolved: Bool = false
    ) {
        self.id = id
        self.rangeLocation = range.location
        self.rangeLength = range.length
        self.anchorText = anchorText
        self.text = text
        self.createdAt = createdAt
        self.resolved = resolved
    }

    enum CodingKeys: String, CodingKey {
        case id, anchorText, text, createdAt, resolved, rangeLocation, rangeLength
    }
}
