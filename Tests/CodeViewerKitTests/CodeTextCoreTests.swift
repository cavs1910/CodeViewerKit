import SwiftUI
import XCTest
@testable import CodeViewerKit

#if os(macOS)
import AppKit
#endif

final class CodeTextCoreTests: XCTestCase {
    func testDocumentStateClassifiesUpdatesAndNewDocuments() throws {
        var state = CodeTextDocumentState()
        let text = "first\nsecond"

        let initialChange = try XCTUnwrap(
            state.change(
                documentID: "first",
                text: text,
                plainTextColor: .white,
                fontSize: 12,
                highlightLanguage: "swift",
                highlightAppearance: .light
            )
        )
        XCTAssertTrue(initialChange.isNewDocument)

        state.apply(
            documentID: "first",
            text: text,
            plainTextColor: .white,
            fontSize: 12,
            highlightLanguage: "swift",
            highlightAppearance: .light
        )
        XCTAssertNil(
            state.change(
                documentID: "first",
                text: text,
                plainTextColor: .white,
                fontSize: 12,
                highlightLanguage: "swift",
                highlightAppearance: .light
            )
        )
        XCTAssertFalse(
            try XCTUnwrap(
                state.change(
                    documentID: "first",
                    text: text,
                    plainTextColor: .white,
                    fontSize: 13,
                    highlightLanguage: "swift",
                    highlightAppearance: .light
                )
            ).isNewDocument
        )
        XCTAssertFalse(
            try XCTUnwrap(
                state.change(
                    documentID: "first",
                    text: text,
                    plainTextColor: .black,
                    fontSize: 12,
                    highlightLanguage: "swift",
                    highlightAppearance: .light
                )
            ).isNewDocument
        )
        XCTAssertTrue(
            try XCTUnwrap(
                state.change(
                    documentID: "second",
                    text: text,
                    plainTextColor: .white,
                    fontSize: 12,
                    highlightLanguage: "swift",
                    highlightAppearance: .light
                )
            ).isNewDocument
        )
    }

    func testDocumentStateBuildsTheSharedLogicalLineIndex() {
        var state = CodeTextDocumentState()

        state.apply(
            documentID: "sample",
            text: "first\nsecond\n",
            plainTextColor: .white,
            fontSize: 12,
            highlightLanguage: "swift",
            highlightAppearance: .light
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

    func testPlainTextStyleUsesAnAppearanceAwareDefault() {
        XCTAssertEqual(
            CodePlainTextStyle.resolve(configuredColor: nil, colorScheme: .light),
            .black
        )
        XCTAssertEqual(
            CodePlainTextStyle.resolve(configuredColor: nil, colorScheme: .dark),
            .white
        )
        XCTAssertEqual(
            CodePlainTextStyle.resolve(configuredColor: .orange, colorScheme: .dark),
            .orange
        )
    }

    func testNativePlainTextFallbackUsesTextKitColorAndPreservesSyntaxColors() {
        #if os(macOS)
        let text = NSMutableAttributedString(string: "plain highlighted")
        let highlightedRange = (text.string as NSString).range(of: "highlighted")
        text.addAttribute(
            .foregroundColor,
            value: NSColor.systemRed,
            range: highlightedRange
        )

        CodeNativeTextColor.applyFallback(.white, to: text)

        XCTAssertEqual(
            text.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? NSColor,
            NSColor(Color.white)
        )
        XCTAssertEqual(
            text.attribute(
                .foregroundColor,
                at: highlightedRange.location,
                effectiveRange: nil
            ) as? NSColor,
            .systemRed
        )
        #endif
    }

    func testNativeHighlightingAppliesOnlyThePublishedBatch() {
        #if os(macOS)
        let text = NSMutableAttributedString(string: "let value")
        let batch = CodeHighlightBatch(
            sequence: 0,
            coveredRange: NSRange(location: 0, length: 3),
            spans: [
                CodeHighlightSpan(
                    range: NSRange(location: 0, length: 3),
                    token: .keyword
                )
            ]
        )

        CodeNativeHighlighting.apply(batch, appearance: .light, to: text)

        XCTAssertEqual(text.string, "let value")
        XCTAssertNotNil(
            text.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? NSColor
        )
        XCTAssertNil(
            text.attribute(.foregroundColor, at: 4, effectiveRange: nil)
        )
        #endif
    }
}
