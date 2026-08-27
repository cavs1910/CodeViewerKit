import CodeViewerKit
import TreeSitterMarkdown
import TreeSitterMarkdownQueries

public extension CodeGrammar {
    static let markdown = CodeGrammar(identifier: "markdown", aliases: ["md"], language: tree_sitter_markdown(), queryURLs: [TreeSitterMarkdownQueries.Query.highlightsFileURL])
}
