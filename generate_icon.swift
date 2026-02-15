#!/usr/bin/swift

import AppKit
import Foundation

// Icon sizes needed for macOS app icon
let sizes = [16, 32, 64, 128, 256, 512, 1024]

func createIcon(size: Int) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))

    image.lockFocus()

    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    let cornerRadius = CGFloat(size) * 0.22 // macOS icon corner radius

    // Background - deep blue gradient
    let backgroundPath = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)

    // Gradient background
    let gradient = NSGradient(colors: [
        NSColor(red: 0.15, green: 0.25, blue: 0.45, alpha: 1.0),  // Dark blue
        NSColor(red: 0.25, green: 0.40, blue: 0.65, alpha: 1.0)   // Lighter blue
    ])!
    gradient.draw(in: backgroundPath, angle: -45)

    // Draw "M" for markdown - stylized
    let fontSize = CGFloat(size) * 0.5
    let font = NSFont.systemFont(ofSize: fontSize, weight: .bold)

    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = .center

    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor.white,
        .paragraphStyle: paragraphStyle
    ]

    let text = "M"
    let textSize = text.size(withAttributes: attributes)
    let textRect = NSRect(
        x: (CGFloat(size) - textSize.width) / 2,
        y: (CGFloat(size) - textSize.height) / 2 + CGFloat(size) * 0.02,
        width: textSize.width,
        height: textSize.height
    )
    text.draw(in: textRect, withAttributes: attributes)

    // Draw a small down arrow or markdown indicator below
    let arrowSize = CGFloat(size) * 0.12
    let arrowY = CGFloat(size) * 0.22
    let arrowPath = NSBezierPath()
    let centerX = CGFloat(size) / 2

    arrowPath.move(to: NSPoint(x: centerX - arrowSize, y: arrowY + arrowSize * 0.6))
    arrowPath.line(to: NSPoint(x: centerX, y: arrowY))
    arrowPath.line(to: NSPoint(x: centerX + arrowSize, y: arrowY + arrowSize * 0.6))

    NSColor.white.withAlphaComponent(0.8).setStroke()
    arrowPath.lineWidth = CGFloat(size) * 0.025
    arrowPath.lineCapStyle = .round
    arrowPath.stroke()

    image.unlockFocus()

    return image
}

func saveImage(_ image: NSImage, to path: String) {
    guard let tiffData = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let pngData = bitmap.representation(using: .png, properties: [:]) else {
        print("Failed to create PNG data")
        return
    }

    do {
        try pngData.write(to: URL(fileURLWithPath: path))
        print("Saved: \(path)")
    } catch {
        print("Failed to save \(path): \(error)")
    }
}

// Create iconset directory in current working directory
let currentDirectory = FileManager.default.currentDirectoryPath
let iconsetPath = "\(currentDirectory)/AppIcon.iconset"
let fileManager = FileManager.default

// Remove existing iconset if present
if fileManager.fileExists(atPath: iconsetPath) {
    try? fileManager.removeItem(atPath: iconsetPath)
}

do {
    try fileManager.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)
} catch {
    print("Error creating iconset directory: \(error)")
    exit(1)
}

// Generate icons at different sizes
for size in sizes {
    let image = createIcon(size: size)

    // Standard resolution
    if size <= 512 {
        saveImage(image, to: "\(iconsetPath)/icon_\(size)x\(size).png")
    }

    // @2x resolution (retina)
    if size >= 32 {
        let halfSize = size / 2
        if halfSize >= 16 {
            saveImage(image, to: "\(iconsetPath)/icon_\(halfSize)x\(halfSize)@2x.png")
        }
    }
}

// Also save the 1024 version
let largeIcon = createIcon(size: 1024)
saveImage(largeIcon, to: "\(iconsetPath)/icon_512x512@2x.png")

print("\nIconset created at: \(iconsetPath)")
print("Run: iconutil -c icns AppIcon.iconset -o AppIcon.icns")
