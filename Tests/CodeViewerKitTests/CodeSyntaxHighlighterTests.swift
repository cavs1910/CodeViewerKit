import Foundation
import XCTest
@testable import CodeViewerKit

#if os(macOS)
import AppKit
#else
import UIKit
#endif

final class CodeSyntaxHighlighterTests: XCTestCase {
    func testSwiftUsesTheWholeDocumentTreeSitterPath() {
        XCTAssertTrue(
            CodeSyntaxHighlighter.highlightsWholeDocumentImmediately(
                language: .swift
            )
        )
        XCTAssertFalse(
            CodeSyntaxHighlighter.highlightsWholeDocumentImmediately(
                language: .python
            )
        )
        XCTAssertFalse(
            CodeSyntaxHighlighter.highlightsWholeDocumentImmediately(
                language: .automatic
            )
        )
    }

    func testTreeSitterAppliesDifferentSwiftTokenColors() throws {
        let source = "let value = \"Hello\""
        let highlighter = try SwiftTreeSitterHighlighter()
        let highlighted = try highlighter.attributedText(
            source,
            appearance: .dark
        )
        let nativeText = NSAttributedString(highlighted)
        let keywordRange = (source as NSString).range(of: "let")
        let stringRange = (source as NSString).range(of: "\"Hello\"")

        let keywordColor = nativeText.attribute(
            .foregroundColor,
            at: keywordRange.location,
            effectiveRange: nil
        )
        let stringColor = nativeText.attribute(
            .foregroundColor,
            at: stringRange.location,
            effectiveRange: nil
        )

        XCTAssertNotNil(keywordColor)
        XCTAssertNotNil(stringColor)
        XCTAssertNotEqual(
            keywordColor as? NSObject,
            stringColor as? NSObject
        )
    }

    func testNonSwiftLanguageUsesHighlightSwiftFallback() async throws {
        let source = "def greet():\n    return \"Hello\""
        let highlighter = CodeSyntaxHighlighter()
        let result = await highlighter.attributedText(
            source,
            language: .python,
            appearance: .dark
        )
        let highlighted = try XCTUnwrap(result)
        let nativeText = NSAttributedString(highlighted)
        let keywordRange = (nativeText.string as NSString).range(of: "def")

        XCTAssertNotNil(
            nativeText.attribute(
                .foregroundColor,
                at: keywordRange.location,
                effectiveRange: nil
            )
        )
    }
}
