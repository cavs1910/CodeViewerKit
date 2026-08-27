import SwiftUI
import XCTest
@testable import CodeViewerKit

final class CodeLanguageTests: XCTestCase {
    func testProvidesPredefinedCustomAndAutomaticLanguages() {
        XCTAssertEqual(CodeLanguage.swift.identifier, "swift")
        XCTAssertEqual(CodeLanguage.python.identifier, "python")
        XCTAssertEqual(CodeLanguage("elixir").identifier, "elixir")

        let literal: CodeLanguage = "go"
        XCTAssertEqual(literal.identifier, "go")
        XCTAssertNil(CodeLanguage.automatic.identifier)
    }

    @MainActor
    func testHighlightCacheSeparatesLanguages() async {
        let store = CodeHighlightStore(grammars: allTestGrammars)
        let source = "let value = 1"

        await store.prepare(
            documentID: "sample",
            sourceCode: source,
            language: .swift,
            colorScheme: .dark
        )

        XCTAssertTrue(
            store.isPrepared(
                documentID: "sample",
                sourceCode: source,
                language: .swift,
                colorScheme: .dark
            )
        )
        XCTAssertFalse(
            store.isPrepared(
                documentID: "sample",
                sourceCode: source,
                language: .python,
                colorScheme: .dark
            )
        )
    }
}
