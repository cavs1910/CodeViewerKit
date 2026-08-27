import CodeViewerKit
import TreeSitterPHP
import TreeSitterPHPQueries

public extension CodeGrammar {
    static let php = CodeGrammar(identifier: "php", language: tree_sitter_php(), queryURLs: [TreeSitterPHPQueries.Query.highlightsFileURL])
}
