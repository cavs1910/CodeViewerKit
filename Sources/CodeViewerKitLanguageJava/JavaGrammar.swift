import CodeViewerKit
import TreeSitterJava
import TreeSitterJavaQueries

public extension CodeGrammar {
    static let java = CodeGrammar(identifier: "java", language: tree_sitter_java(), queryURLs: [TreeSitterJavaQueries.Query.highlightsFileURL])
    static let kotlin = CodeGrammar(identifier: "kotlin", aliases: ["kt", "kts"], language: tree_sitter_java(), queryURLs: [TreeSitterJavaQueries.Query.highlightsFileURL])
}
