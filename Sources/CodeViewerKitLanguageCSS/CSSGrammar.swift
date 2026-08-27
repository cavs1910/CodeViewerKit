import CodeViewerKit
import TreeSitterCSS
import TreeSitterCSSQueries

public extension CodeGrammar {
    static let css = CodeGrammar(identifier: "css", language: tree_sitter_css(), queryURLs: [TreeSitterCSSQueries.Query.highlightsFileURL])
}
