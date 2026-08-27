import CodeViewerKit
import SwiftUI
import XCTest

@MainActor
final class PublicAPICompilationTests: XCTestCase {
    func testPublicViewerSurfaceCanBeConstructed() {
        let highlights = CodeHighlightStore()

        _ = CodeViewer(
            documentID: "example",
            sourceCode: "import SwiftUI",
            highlightStore: highlights,
            language: .python,
            plainTextColor: .orange,
            scrollIndicatorInsets: EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 4)
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
