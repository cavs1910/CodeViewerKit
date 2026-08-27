import CodeViewerKit
import TreeSitterBash
import TreeSitterBashQueries

public extension CodeGrammar {
    static let bash = CodeGrammar(identifier: "bash", aliases: ["shell", "sh", "zsh"], language: tree_sitter_bash(), queryURLs: [TreeSitterBashQueries.Query.highlightsFileURL])
}
