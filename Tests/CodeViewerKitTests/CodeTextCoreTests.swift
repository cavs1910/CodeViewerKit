import XCTest
@testable import CodeViewerKit

final class CodeTextCoreTests: XCTestCase {
    func testDocumentStateClassifiesUpdatesAndNewDocuments() throws {
        var state = CodeTextDocumentState()
        let text = AttributedString("first\nsecond")

        let initialChange = try XCTUnwrap(
            state.change(documentID: "first", text: text, fontSize: 12)
        )
        XCTAssertTrue(initialChange.isNewDocument)

        state.apply(
            documentID: "first",
            text: text,
            fontSize: 12,
            plainText: "first\nsecond"
        )
        XCTAssertNil(state.change(documentID: "first", text: text, fontSize: 12))
        XCTAssertFalse(
            try XCTUnwrap(
                state.change(documentID: "first", text: text, fontSize: 13)
            ).isNewDocument
        )
        XCTAssertTrue(
            try XCTUnwrap(
                state.change(documentID: "second", text: text, fontSize: 12)
            ).isNewDocument
        )
    }

    func testDocumentStateBuildsTheSharedLogicalLineIndex() {
        var state = CodeTextDocumentState()

        state.apply(
            documentID: "sample",
            text: AttributedString("first\nsecond\n"),
            fontSize: 12,
            plainText: "first\nsecond\n"
        )

        XCTAssertEqual(state.lineIndex.count, 3)
    }

    func testGutterMetricsUseOneGeometryForBothPlatforms() {
        XCTAssertEqual(CodeGutterMetrics.digitSample(lineCount: 1), "00")
        XCTAssertEqual(CodeGutterMetrics.digitSample(lineCount: 100), "000")
        XCTAssertEqual(CodeGutterMetrics.requiredWidth(measuredLabelWidth: 20), 36)
        XCTAssertEqual(
            CodeGutterMetrics.lineNumberOriginX(containerWidth: 50, labelWidth: 10),
            28
        )

        let frames = CodeGutterMetrics.frames(
            in: CGRect(x: 0, y: 0, width: 100, height: 80),
            gutterWidth: 24
        )
        XCTAssertEqual(frames.gutter, CGRect(x: 0, y: 0, width: 24, height: 80))
        XCTAssertEqual(frames.text, CGRect(x: 24, y: 0, width: 76, height: 80))
    }
}
