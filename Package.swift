// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Overfold",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Overfold",
            path: "Sources/Overfold",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
