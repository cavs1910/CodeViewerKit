import CodeViewerKit
import TreeSitterJSON
import TreeSitterJSONQueries

public extension CodeGrammar {
    static let json = CodeGrammar(identifier: "json", language: tree_sitter_json(), queryURLs: [TreeSitterJSONQueries.Query.highlightsFileURL])
}
