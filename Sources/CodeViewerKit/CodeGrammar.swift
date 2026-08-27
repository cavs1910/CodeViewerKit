import Foundation

/// A native Tree-sitter grammar linked into the consuming application.
///
/// Obtain a parser from any Tree-sitter grammar package, then pass its
/// definition to ``CodeHighlightStore/init(grammars:)``.
public struct CodeGrammar: @unchecked Sendable {
    let identifier: String
    let aliases: [String]
    let language: OpaquePointer
    let queryURLs: [URL]
    let detectsSource: (@Sendable (String) -> Bool)?

    /// Creates a grammar supplied by a CodeViewerKit language product.
    public init(
        identifier: String,
        aliases: [String] = [],
        language: OpaquePointer,
        queryURLs: [URL],
        detectsSource: (@Sendable (String) -> Bool)? = nil
    ) {
        self.identifier = identifier
        self.aliases = aliases
        self.language = language
        self.queryURLs = queryURLs
        self.detectsSource = detectsSource
    }
}
