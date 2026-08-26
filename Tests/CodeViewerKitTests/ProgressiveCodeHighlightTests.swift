import XCTest
@testable import CodeViewerKit

final class ProgressiveCodeHighlightTests: XCTestCase {
    func testKeepsShortDocumentsInTheLeadingStage() {
        let source = "one\ntwo\nthree"

        let result = ProgressiveCodeHighlight.splitLeadingLines(source)

        XCTAssertEqual(result.0, source)
        XCTAssertTrue(result.1.isEmpty)
    }

    func testSplitsLongDocumentsAfterEightyLines() {
        let lines = (1...100).map { "line \($0)" }
        let source = lines.joined(separator: "\n")

        let result = ProgressiveCodeHighlight.splitLeadingLines(source)

        XCTAssertEqual(result.0.split(separator: "\n").count, 80)
        XCTAssertTrue(result.1.hasPrefix("line 81"))
    }
}
