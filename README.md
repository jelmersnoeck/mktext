# mktext

A native macOS markdown editor with Typora-style WYSIWYG editing. Write in markdown and see it transform in real-time — no split panes, no preview modes, just clean writing.

![macOS](https://img.shields.io/badge/macOS-13.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

- **True WYSIWYG Editing** — Markdown syntax disappears as you type, showing only formatted text
- **Single Pane Experience** — No distracting split views or preview panels
- **Syntax Reveal** — Move your cursor into formatted text to see and edit the markdown
- **Raw Mode Toggle** — Switch to raw markdown view anytime with `Cmd+Shift+E`
- **Native macOS** — Built with SwiftUI for a fast, native experience
- **File Support** — Open and save `.md` files directly

### Supported Markdown

- Headers (H1-H6)
- **Bold** and *italic* text
- [Links](https://example.com)
- Ordered and unordered lists
- Blockquotes
- Inline `code`

## Installation

### Prerequisites

- macOS 13.0 (Ventura) or later
- Swift 5.9 or later (included with Xcode 15+)

### Build from Source

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/mktext.git
   cd mktext
   ```

2. **Build the app**
   ```bash
   swift build -c release
   ```

3. **Create the app bundle**
   ```bash
   # Create bundle structure
   mkdir -p mktext.app/Contents/MacOS
   mkdir -p mktext.app/Contents/Resources

   # Copy executable
   cp .build/release/mktext mktext.app/Contents/MacOS/

   # Copy resources (if iconset exists)
   if [ -d "mktext.iconset" ]; then
       iconutil -c icns mktext.iconset -o mktext.app/Contents/Resources/AppIcon.icns
   fi

   # Copy Info.plist
   cp mktext/Info.plist mktext.app/Contents/
   ```

4. **Run the app**
   ```bash
   open mktext.app
   ```

### Quick Install Script

Run this one-liner to build and launch:

```bash
swift build -c release && \
mkdir -p mktext.app/Contents/{MacOS,Resources} && \
cp .build/release/mktext mktext.app/Contents/MacOS/ && \
cp mktext/Info.plist mktext.app/Contents/ && \
open mktext.app
```

## Usage

### Creating Documents

- **New Document**: `Cmd+N`
- **Open Document**: `Cmd+O`
- **Save Document**: `Cmd+S`

### Formatting

| Action | Shortcut |
|--------|----------|
| Bold | `Cmd+B` |
| Italic | `Cmd+I` |
| Link | `Cmd+K` |
| Heading 1-6 | `Cmd+1` through `Cmd+6` |
| Toggle Raw Markdown | `Cmd+Shift+E` |

### How WYSIWYG Works

When you type markdown:
1. The syntax (like `**` for bold) is automatically hidden
2. The text appears formatted (bold, italic, etc.)
3. Move your cursor into the formatted text to reveal and edit the syntax
4. Move away, and it hides again

## Development

### Project Structure

```
mktext/
├── Package.swift              # Swift package manifest
├── mktext/
│   ├── App/
│   │   └── mktextApp.swift    # App entry point
│   ├── Models/
│   │   ├── MarkdownDocument.swift
│   │   └── MarkdownElement.swift
│   ├── Parsing/
│   │   └── MarkdownParser.swift
│   ├── Editor/
│   │   ├── WYSIWYGTextView.swift
│   │   └── WYSIWYGCoordinator.swift
│   ├── Views/
│   │   ├── EditorView.swift
│   │   └── ToolbarView.swift
│   └── Styling/
│       ├── MarkdownStyler.swift
│       └── MarkdownTheme.swift
└── mktextTests/
    └── MarkdownParserTests.swift
```

### Building for Development

```bash
# Debug build
swift build

# Run directly (without app bundle)
.build/debug/mktext

# Watch for changes and rebuild (requires entr)
find mktext -name "*.swift" | entr -c swift build
```

### Opening in Xcode

If you have Xcode installed:

```bash
open Package.swift
```

This opens the project in Xcode where you can:
- Use the debugger
- See SwiftUI previews
- Run on different simulators

### Running Tests

```bash
swift test
```

Note: Some tests may require Xcode's test infrastructure. For full testing, open in Xcode and run tests from there (`Cmd+U`).

### Dependencies

- [swift-markdown](https://github.com/swiftlang/swift-markdown) — Apple's official markdown parser

## Architecture

### Core Components

1. **MarkdownParser** — Wraps swift-markdown to parse text into an AST and extract element positions

2. **MarkdownStyler** — Converts parsed elements to `NSAttributedString` styles, handling the show/hide logic for syntax characters

3. **WYSIWYGTextView** — `NSViewRepresentable` that bridges `NSTextView` to SwiftUI for rich text editing

4. **WYSIWYGCoordinator** — Manages text changes, cursor tracking, and triggers re-styling when needed

### How Styling Works

```
User types → NSTextView captures input → Parse markdown into AST
→ Find element at cursor position → Apply styles (hide syntax unless cursor is inside)
→ Render formatted text
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Roadmap

- [ ] Code blocks with syntax highlighting
- [ ] Table support
- [ ] Image embedding
- [ ] Multiple themes
- [ ] Export to HTML/PDF
- [ ] iCloud sync
- [ ] Vim keybindings

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Inspired by [Typora](https://typora.io/) and its WYSIWYG approach
- Built with [swift-markdown](https://github.com/swiftlang/swift-markdown) by Apple
