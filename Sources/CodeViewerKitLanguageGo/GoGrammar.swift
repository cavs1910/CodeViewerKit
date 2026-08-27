import CodeViewerKit
import TreeSitterGo
import TreeSitterGoQueries

public extension CodeGrammar {
    static let go = CodeGrammar(identifier: "go", aliases: ["golang"], language: tree_sitter_go(), queryURLs: [TreeSitterGoQueries.Query.highlightsFileURL])
}
