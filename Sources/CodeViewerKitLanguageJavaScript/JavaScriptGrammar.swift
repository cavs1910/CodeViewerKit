import CodeViewerKit
import TreeSitterJavaScript
import TreeSitterJavaScriptQueries

public extension CodeGrammar {
    static let javaScript = CodeGrammar(identifier: "javascript", aliases: ["js", "jsx", "mjs", "cjs"], language: tree_sitter_javascript(), queryURLs: [TreeSitterJavaScriptQueries.Query.highlightsFileURL])
}
