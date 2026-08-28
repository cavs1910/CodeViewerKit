import SwiftUI
import XCTest
@testable import CodeViewerKit

#if os(macOS)
import AppKit
#endif

final class CodeTextCoreTests: XCTestCase {
    #if os(macOS)
    @MainActor
    func testMacTextViewUsesNoncontiguousLayout() throws {
        let textView = CodeMacTextLayout.makeTextView()
        let layoutManager = try XCTUnwrap(textView.layoutManager)

        XCTAssertNil(textView.textLayoutManager)
        XCTAssertTrue(layoutManager.allowsNonContiguousLayout)
        XCTAssertFalse(layoutManager.backgroundLayoutEnabled)
    }
    #endif

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

    func testLayoutPreparationResolvesConfiguredModesAndAutomaticLimit() {
        XCTAssertEqual(
            CodeLayoutPreparation.defaultAutomaticMaximumUTF16Length,
            64_000
        )
        XCTAssertFalse(
            CodeLayoutPreparation.progressive.preparesCompleteLayout(
                forUTF16Length: 10
            )
        )
        XCTAssertTrue(
            CodeLayoutPreparation.complete.preparesCompleteLayout(
                forUTF16Length: 1_000_000
            )
        )

        let automatic = CodeLayoutPreparation.automatic(
            maximumUTF16Length: 64_000
        )
        XCTAssertTrue(
            automatic.preparesCompleteLayout(forUTF16Length: 64_000)
        )
        XCTAssertFalse(
            automatic.preparesCompleteLayout(forUTF16Length: 64_001)
        )
        XCTAssertFalse(
            CodeLayoutPreparation.automatic(maximumUTF16Length: -1)
                .preparesCompleteLayout(forUTF16Length: 1)
        )
    }

    #if os(macOS)
    @MainActor
    func testCompletePreparationFillsSparseTextKitLayout() throws {
        let textView = CodeMacTextLayout.makeTextView()
        let layoutManager = try XCTUnwrap(textView.layoutManager)
        let textContainer = try XCTUnwrap(textView.textContainer)
        let text = String(repeating: "let value = 1\n", count: 500)

        textView.textStorage?.setAttributedString(
            NSAttributedString(
                string: text,
                attributes: [
                    .font: NSFont.monospacedSystemFont(
                        ofSize: 12,
                        weight: .regular
                    )
                ]
            )
        )

        XCTAssertTrue(
            CodeNativeLayoutPreparation.prepare(
                .automatic(maximumUTF16Length: 64_000),
                layoutManager: layoutManager,
                textContainer: textContainer
            )
        )
        XCTAssertEqual(
            layoutManager.firstUnlaidCharacterIndex(),
            textView.textStorage?.length
        )
        XCTAssertFalse(layoutManager.hasNonContiguousLayout)

        textView.textStorage?.addAttribute(
            .foregroundColor,
            value: NSColor.systemRed,
            range: NSRange(location: 0, length: 3)
        )
        XCTAssertTrue(layoutManager.hasNonContiguousLayout)

        CodeNativeLayoutPreparation.prepare(
            .complete,
            layoutManager: layoutManager,
            textContainer: textContainer
        )
        XCTAssertFalse(layoutManager.hasNonContiguousLayout)
    }
    #endif

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
