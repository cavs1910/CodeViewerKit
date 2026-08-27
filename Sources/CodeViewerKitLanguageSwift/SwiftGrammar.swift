import CodeViewerKit
import TreeSitterSwift
import TreeSitterSwiftQueries

public extension CodeGrammar {
    static let swift = CodeGrammar(identifier: "swift", language: tree_sitter_swift(), queryURLs: [TreeSitterSwiftQueries.Query.highlightsFileURL])
}
