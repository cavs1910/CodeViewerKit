import CodeViewerKit
import TreeSitterHTML
import TreeSitterHTMLQueries

public extension CodeGrammar {
    static let html = CodeGrammar(identifier: "html", aliases: ["htm"], language: tree_sitter_html(), queryURLs: [TreeSitterHTMLQueries.Query.highlightsFileURL])
}
