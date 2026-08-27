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
        ),
        .package(
            url: "https://github.com/tree-sitter/swift-tree-sitter.git",
            from: "0.25.0"
        ),
        .package(
            url: "https://github.com/alex-pinkus/tree-sitter-swift.git",
            revision: "31d17fe7e818a2048c808b5c6fdc2dc792f4f5b5"
        )
    ],
    targets: [
        .target(
            name: "CodeViewerKit",
            dependencies: [
                .product(
                    name: "HighlightSwift",
                    package: "HighlightSwift"
                ),
                .product(
                    name: "SwiftTreeSitter",
                    package: "swift-tree-sitter"
                ),
                .product(
                    name: "TreeSitterSwift",
                    package: "tree-sitter-swift"
                )
            ]
        ),
        .testTarget(
            name: "CodeViewerKitTests",
            dependencies: ["CodeViewerKit"]
        )
    ]
)
