import Foundation
import XCTest
@testable import CodeViewerKit

#if os(macOS)
import AppKit
#else
import UIKit
#endif

final class CodeSyntaxHighlighterTests: XCTestCase {
    func testUnregisteredLanguageReturnsPlainText() async throws {
        let source = "some custom syntax"
        let highlighter = CodeSyntaxHighlighter(grammars: [])
        let highlighted = await highlighter.attributedText(
            source,
            language: "language-created-tomorrow",
            appearance: .dark
        )
        let result = try XCTUnwrap(highlighted)
        let nativeText = NSAttributedString(result)

        XCTAssertEqual(nativeText.string, source)
        XCTAssertNil(
            nativeText.attribute(
                .foregroundColor,
                at: 0,
                effectiveRange: nil
            )
        )
    }
}
