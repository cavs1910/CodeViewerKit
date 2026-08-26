// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "CodeViewerKit",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(name: "CodeViewerKit", targets: ["CodeViewerKit"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/appstefan/HighlightSwift.git",
            from: "1.1.0"
        )
    ],
    targets: [
        .target(
            name: "CodeViewerKit",
            dependencies: [
                .product(
                    name: "HighlightSwift",
                    package: "HighlightSwift"
                )
            ]
        ),
        .testTarget(
            name: "CodeViewerKitTests",
            dependencies: ["CodeViewerKit"]
        )
    ]
)
