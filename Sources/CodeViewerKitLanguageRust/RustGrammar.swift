import CodeViewerKit
import TreeSitterRust
import TreeSitterRustQueries

public extension CodeGrammar {
    static let rust = CodeGrammar(identifier: "rust", aliases: ["rs"], language: tree_sitter_rust(), queryURLs: [TreeSitterRustQueries.Query.highlightsFileURL])
}
