// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "mktext",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "mktext", targets: ["mktext"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-markdown.git", from: "0.4.0")
    ],
    targets: [
        .executableTarget(
            name: "mktext",
            dependencies: [
                .product(name: "Markdown", package: "swift-markdown")
            ],
            path: "mktext",
            exclude: ["Info.plist"]
        ),
        .testTarget(
            name: "mktextTests",
            dependencies: ["mktext"],
            path: "mktextTests"
        )
    ]
)
