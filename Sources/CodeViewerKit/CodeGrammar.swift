import Foundation

/// A native Tree-sitter grammar linked into the consuming application.
///
/// Add only the `CodeViewerKitLanguage…` products your application needs,
/// then pass their grammar values to ``CodeHighlightStore/init(grammars:)``.
public struct CodeGrammar: @unchecked Sendable {
    let identifier: String
    let aliases: [String]
    let language: OpaquePointer
    let queryURLs: [URL]

    /// Creates a grammar supplied by a CodeViewerKit language product.
    public init(
        identifier: String,
        aliases: [String] = [],
        language: OpaquePointer,
        queryURLs: [URL]
    ) {
        self.identifier = identifier
        self.aliases = aliases
        self.language = language
        self.queryURLs = queryURLs
    }
}
