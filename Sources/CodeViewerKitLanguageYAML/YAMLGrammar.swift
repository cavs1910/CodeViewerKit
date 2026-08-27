import CodeViewerKit
import TreeSitterYAML
import TreeSitterYAMLQueries

public extension CodeGrammar {
    static let yaml = CodeGrammar(identifier: "yaml", aliases: ["yml"], language: tree_sitter_yaml(), queryURLs: [TreeSitterYAMLQueries.Query.highlightsFileURL])
}
