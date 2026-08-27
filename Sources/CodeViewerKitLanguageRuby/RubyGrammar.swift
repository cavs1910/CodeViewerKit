import CodeViewerKit
import TreeSitterRuby
import TreeSitterRubyQueries

public extension CodeGrammar {
    static let ruby = CodeGrammar(identifier: "ruby", aliases: ["rb"], language: tree_sitter_ruby(), queryURLs: [TreeSitterRubyQueries.Query.highlightsFileURL])
}
