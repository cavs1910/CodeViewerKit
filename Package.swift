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
            url: "https://github.com/tree-sitter/swift-tree-sitter.git",
            from: "0.25.0"
        )
    ],
    targets: [
        .target(
            name: "CodeViewerKit",
            dependencies: [
                .product(
                    name: "SwiftTreeSitter",
                    package: "swift-tree-sitter"
                )
            ]
        ),
        .testTarget(
            name: "CodeViewerKitTests",
            dependencies: ["CodeViewerKit"]
        )
    ]
)
