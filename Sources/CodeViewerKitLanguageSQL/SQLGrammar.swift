import CodeViewerKit
import TreeSitterSQL
import TreeSitterSQLQueries

public extension CodeGrammar {
    static let sql = CodeGrammar(identifier: "sql", language: tree_sitter_sql(), queryURLs: [TreeSitterSQLQueries.Query.highlightsFileURL])
}
