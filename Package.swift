// swift-tools-version: 6.0

import PackageDescription

let languageTargets: [Target] = [
    .target(name: "CodeViewerKitLanguageBash", dependencies: ["CodeViewerKit", .product(name: "TreeSitterBash", package: "TreeSitterLanguages"), .product(name: "TreeSitterBashQueries", package: "TreeSitterLanguages")]),
    .target(name: "CodeViewerKitLanguageC", dependencies: ["CodeViewerKit", .product(name: "TreeSitterC", package: "TreeSitterLanguages"), .product(name: "TreeSitterCQueries", package: "TreeSitterLanguages")]),
    .target(name: "CodeViewerKitLanguageCPP", dependencies: ["CodeViewerKit", .product(name: "TreeSitterCQueries", package: "TreeSitterLanguages"), .product(name: "TreeSitterCPP", package: "TreeSitterLanguages"), .product(name: "TreeSitterCPPQueries", package: "TreeSitterLanguages")]),
    .target(name: "CodeViewerKitLanguageCSharp", dependencies: ["CodeViewerKit", .product(name: "TreeSitterCSharp", package: "TreeSitterLanguages"), .product(name: "TreeSitterCSharpQueries", package: "TreeSitterLanguages")]),
    .target(name: "CodeViewerKitLanguageCSS", dependencies: ["CodeViewerKit", .product(name: "TreeSitterCSS", package: "TreeSitterLanguages"), .product(name: "TreeSitterCSSQueries", package: "TreeSitterLanguages")]),
    .target(name: "CodeViewerKitLanguageGo", dependencies: ["CodeViewerKit", .product(name: "TreeSitterGo", package: "TreeSitterLanguages"), .product(name: "TreeSitterGoQueries", package: "TreeSitterLanguages")]),
    .target(name: "CodeViewerKitLanguageHTML", dependencies: ["CodeViewerKit", .product(name: "TreeSitterHTML", package: "TreeSitterLanguages"), .product(name: "TreeSitterHTMLQueries", package: "TreeSitterLanguages")]),
    .target(name: "CodeViewerKitLanguageJava", dependencies: ["CodeViewerKit", .product(name: "TreeSitterJava", package: "TreeSitterLanguages"), .product(name: "TreeSitterJavaQueries", package: "TreeSitterLanguages")]),
    .target(name: "CodeViewerKitLanguageJavaScript", dependencies: ["CodeViewerKit", .product(name: "TreeSitterJavaScript", package: "TreeSitterLanguages"), .product(name: "TreeSitterJavaScriptQueries", package: "TreeSitterLanguages")]),
    .target(name: "CodeViewerKitLanguageJSON", dependencies: ["CodeViewerKit", .product(name: "TreeSitterJSON", package: "TreeSitterLanguages"), .product(name: "TreeSitterJSONQueries", package: "TreeSitterLanguages")]),
    .target(name: "CodeViewerKitLanguageMarkdown", dependencies: ["CodeViewerKit", .product(name: "TreeSitterMarkdown", package: "TreeSitterLanguages"), .product(name: "TreeSitterMarkdownQueries", package: "TreeSitterLanguages")]),
    .target(name: "CodeViewerKitLanguagePHP", dependencies: ["CodeViewerKit", .product(name: "TreeSitterPHP", package: "TreeSitterLanguages"), .product(name: "TreeSitterPHPQueries", package: "TreeSitterLanguages")]),
    .target(name: "CodeViewerKitLanguagePython", dependencies: ["CodeViewerKit", .product(name: "TreeSitterPython", package: "TreeSitterLanguages"), .product(name: "TreeSitterPythonQueries", package: "TreeSitterLanguages")]),
    .target(name: "CodeViewerKitLanguageRuby", dependencies: ["CodeViewerKit", .product(name: "TreeSitterRuby", package: "TreeSitterLanguages"), .product(name: "TreeSitterRubyQueries", package: "TreeSitterLanguages")]),
    .target(name: "CodeViewerKitLanguageRust", dependencies: ["CodeViewerKit", .product(name: "TreeSitterRust", package: "TreeSitterLanguages"), .product(name: "TreeSitterRustQueries", package: "TreeSitterLanguages")]),
    .target(name: "CodeViewerKitLanguageSQL", dependencies: ["CodeViewerKit", .product(name: "TreeSitterSQL", package: "TreeSitterLanguages"), .product(name: "TreeSitterSQLQueries", package: "TreeSitterLanguages")]),
    .target(name: "CodeViewerKitLanguageSwift", dependencies: ["CodeViewerKit", .product(name: "TreeSitterSwift", package: "TreeSitterLanguages"), .product(name: "TreeSitterSwiftQueries", package: "TreeSitterLanguages")]),
    .target(name: "CodeViewerKitLanguageTypeScript", dependencies: ["CodeViewerKit", .product(name: "TreeSitterJavaScriptQueries", package: "TreeSitterLanguages"), .product(name: "TreeSitterTypeScript", package: "TreeSitterLanguages"), .product(name: "TreeSitterTypeScriptQueries", package: "TreeSitterLanguages")]),
    .target(name: "CodeViewerKitLanguageYAML", dependencies: ["CodeViewerKit", .product(name: "TreeSitterYAML", package: "TreeSitterLanguages"), .product(name: "TreeSitterYAMLQueries", package: "TreeSitterLanguages")])
]

let package = Package(
    name: "CodeViewerKit",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [.library(name: "CodeViewerKit", targets: ["CodeViewerKit"])]
        + languageTargets.map { .library(name: $0.name, targets: [$0.name]) },
    dependencies: [
        .package(url: "https://github.com/tree-sitter/swift-tree-sitter.git", from: "0.25.0"),
        .package(url: "https://github.com/simonbs/TreeSitterLanguages.git", exact: "0.1.10")
    ],
    targets: [
        .target(name: "CodeViewerKit", dependencies: [
            .product(name: "SwiftTreeSitter", package: "swift-tree-sitter")
        ]),
        .testTarget(name: "CodeViewerKitTests", dependencies: [
            "CodeViewerKit",
            "CodeViewerKitLanguageBash", "CodeViewerKitLanguageC",
            "CodeViewerKitLanguageCPP", "CodeViewerKitLanguageCSharp",
            "CodeViewerKitLanguageCSS", "CodeViewerKitLanguageGo",
            "CodeViewerKitLanguageHTML", "CodeViewerKitLanguageJava",
            "CodeViewerKitLanguageJavaScript", "CodeViewerKitLanguageJSON",
            "CodeViewerKitLanguageMarkdown", "CodeViewerKitLanguagePHP",
            "CodeViewerKitLanguagePython", "CodeViewerKitLanguageRuby",
            "CodeViewerKitLanguageRust", "CodeViewerKitLanguageSQL",
            "CodeViewerKitLanguageSwift", "CodeViewerKitLanguageTypeScript",
            "CodeViewerKitLanguageYAML"
        ])
    ] + languageTargets
)
