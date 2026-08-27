import CodeViewerKit
import TreeSitterCQueries
import TreeSitterCPP
import TreeSitterCPPQueries

public extension CodeGrammar {
    static let cPlusPlus = CodeGrammar(identifier: "cpp", aliases: ["c++", "cc", "cxx"], language: tree_sitter_cpp(), queryURLs: [TreeSitterCQueries.Query.highlightsFileURL, TreeSitterCPPQueries.Query.highlightsFileURL])
}
