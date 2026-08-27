import CodeViewerKit
import TreeSitterCSharp
import TreeSitterCSharpQueries

public extension CodeGrammar {
    static let cSharp = CodeGrammar(identifier: "csharp", aliases: ["c#", "cs"], language: tree_sitter_c_sharp(), queryURLs: [TreeSitterCSharpQueries.Query.highlightsFileURL])
}
