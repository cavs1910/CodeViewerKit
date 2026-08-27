import CodeViewerKit
import TreeSitterPython
import TreeSitterPythonQueries

public extension CodeGrammar {
    static let python = CodeGrammar(identifier: "python", aliases: ["py"], language: tree_sitter_python(), queryURLs: [TreeSitterPythonQueries.Query.highlightsFileURL])
}
