import CodeViewerKit
import TreeSitterJavaScriptQueries
import TreeSitterTypeScript
import TreeSitterTypeScriptQueries

public extension CodeGrammar {
    static let typeScript = CodeGrammar(identifier: "typescript", aliases: ["ts"], language: tree_sitter_typescript(), queryURLs: [TreeSitterJavaScriptQueries.Query.highlightsFileURL, TreeSitterTypeScriptQueries.Query.highlightsFileURL])
}
