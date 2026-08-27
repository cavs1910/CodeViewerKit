import CodeViewerKit
import SwiftUI
import XCTest

@MainActor
final class PublicAPICompilationTests: XCTestCase {
    func testPublicViewerSurfaceCanBeConstructed() {
        let highlights = CodeHighlightStore(grammars: allTestGrammars)

        _ = CodeViewer(
            documentID: "example",
            sourceCode: "import SwiftUI",
            highlightStore: highlights,
            language: .python,
            lineWrapping: .word,
            plainTextColor: .orange
        )
        _ = CodeViewerCommands()

        XCTAssertFalse(
            highlights.isPrepared(
                documentID: "example",
                sourceCode: "import SwiftUI",
                language: .python,
                colorScheme: .light
            )
        )

        _ = CodeLanguage.automatic
        _ = CodeLanguage.swift
        _ = CodeLanguage("elixir")
        let _: CodeLanguage = "go"
    }
}
