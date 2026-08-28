import XCTest
@testable import CodeViewerKit

final class CodeLineIndexTests: XCTestCase {
    func testCountsLogicalLinesIncludingTrailingEmptyLine() {
        let index = CodeLineIndex(text: "first\nsecond\n")

        XCTAssertEqual(index.count, 3)
    }

    func testResolvesUTF16OffsetsToLogicalLines() {
        let index = CodeLineIndex(text: "one\ntwo\nthree")

        XCTAssertEqual(index.lineNumber(containing: 0), 1)
        XCTAssertEqual(index.lineNumber(containing: 4), 2)
        XCTAssertEqual(index.lineNumber(containing: 8), 3)
    }

    func testIdentifiesOnlyLogicalLineStarts() {
        let index = CodeLineIndex(text: "one\ntwo\nthree")

        XCTAssertTrue(index.isLineStart(0))
        XCTAssertTrue(index.isLineStart(4))
        XCTAssertTrue(index.isLineStart(8))
        XCTAssertFalse(index.isLineStart(1))
        XCTAssertFalse(index.isLineStart(7))
    }
}
