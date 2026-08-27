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
        ),
        .package(
            url: "https://github.com/simonbs/TreeSitterLanguages.git",
            exact: "0.1.10"
        )
    ],
    targets: [
        .target(
            name: "CodeViewerKit",
            dependencies: [
                .product(
                    name: "SwiftTreeSitter",
                    package: "swift-tree-sitter"
                ),
                .product(name: "TreeSitterBash", package: "TreeSitterLanguages"),
                .product(name: "TreeSitterBashQueries", package: "TreeSitterLanguages"),
                .product(name: "TreeSitterC", package: "TreeSitterLanguages"),
                .product(name: "TreeSitterCQueries", package: "TreeSitterLanguages"),
                .product(name: "TreeSitterCPP", package: "TreeSitterLanguages"),
                .product(name: "TreeSitterCPPQueries", package: "TreeSitterLanguages"),
                .product(name: "TreeSitterCSharp", package: "TreeSitterLanguages"),
                .product(name: "TreeSitterCSharpQueries", package: "TreeSitterLanguages"),
                .product(name: "TreeSitterCSS", package: "TreeSitterLanguages"),
                .product(name: "TreeSitterCSSQueries", package: "TreeSitterLanguages"),
                .product(name: "TreeSitterGo", package: "TreeSitterLanguages"),
                .product(name: "TreeSitterGoQueries", package: "TreeSitterLanguages"),
                .product(name: "TreeSitterHTML", package: "TreeSitterLanguages"),
                .product(name: "TreeSitterHTMLQueries", package: "TreeSitterLanguages"),
                .product(name: "TreeSitterJava", package: "TreeSitterLanguages"),
                .product(name: "TreeSitterJavaQueries", package: "TreeSitterLanguages"),
                .product(name: "TreeSitterJavaScript", package: "TreeSitterLanguages"),
                .product(name: "TreeSitterJavaScriptQueries", package: "TreeSitterLanguages"),
                .product(name: "TreeSitterJSON", package: "TreeSitterLanguages"),
                .product(name: "TreeSitterJSONQueries", package: "TreeSitterLanguages"),
                .product(name: "TreeSitterMarkdown", package: "TreeSitterLanguages"),
                .product(name: "TreeSitterMarkdownQueries", package: "TreeSitterLanguages"),
                .product(name: "TreeSitterPHP", package: "TreeSitterLanguages"),
                .product(name: "TreeSitterPHPQueries", package: "TreeSitterLanguages"),
                .product(name: "TreeSitterPython", package: "TreeSitterLanguages"),
                .product(name: "TreeSitterPythonQueries", package: "TreeSitterLanguages"),
                .product(name: "TreeSitterRuby", package: "TreeSitterLanguages"),
                .product(name: "TreeSitterRubyQueries", package: "TreeSitterLanguages"),
                .product(name: "TreeSitterRust", package: "TreeSitterLanguages"),
                .product(name: "TreeSitterRustQueries", package: "TreeSitterLanguages"),
                .product(name: "TreeSitterSQL", package: "TreeSitterLanguages"),
                .product(name: "TreeSitterSQLQueries", package: "TreeSitterLanguages"),
                .product(name: "TreeSitterSwift", package: "TreeSitterLanguages"),
                .product(name: "TreeSitterSwiftQueries", package: "TreeSitterLanguages"),
                .product(name: "TreeSitterTypeScript", package: "TreeSitterLanguages"),
                .product(name: "TreeSitterTypeScriptQueries", package: "TreeSitterLanguages"),
                .product(name: "TreeSitterYAML", package: "TreeSitterLanguages"),
                .product(name: "TreeSitterYAMLQueries", package: "TreeSitterLanguages")
            ]
        ),
        .testTarget(
            name: "CodeViewerKitTests",
            dependencies: ["CodeViewerKit"]
        )
    ]
)
