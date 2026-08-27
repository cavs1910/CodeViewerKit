import CodeViewerKit
import TreeSitterC
import TreeSitterCQueries

public extension CodeGrammar {
    static let c = CodeGrammar(identifier: "c", language: tree_sitter_c(), queryURLs: [TreeSitterCQueries.Query.highlightsFileURL])
    static let objectiveC = CodeGrammar(identifier: "objectivec", aliases: ["objective-c", "objc", "m", "mm"], language: tree_sitter_c(), queryURLs: [TreeSitterCQueries.Query.highlightsFileURL])
}
