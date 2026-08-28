import SwiftUI
import XCTest
@testable import CodeViewerKit

#if os(macOS)
import AppKit
#endif

final class CodeTextCoreTests: XCTestCase {
    func testDocumentStateClassifiesUpdatesAndNewDocuments() throws {
        var state = CodeTextDocumentState()
        let text = AttributedString("first\nsecond")

        let initialChange = try XCTUnwrap(
            state.change(
                documentID: "first",
                text: text,
                plainTextColor: .white,
                fontSize: 12
            )
        )
        XCTAssertTrue(initialChange.isNewDocument)

        state.apply(
            documentID: "first",
            text: text,
            plainTextColor: .white,
            fontSize: 12,
            plainText: "first\nsecond"
        )
        XCTAssertNil(
            state.change(
                documentID: "first",
                text: text,
                plainTextColor: .white,
                fontSize: 12
            )
        )
        XCTAssertFalse(
            try XCTUnwrap(
                state.change(
                    documentID: "first",
                    text: text,
                    plainTextColor: .white,
                    fontSize: 13
                )
            ).isNewDocument
        )
        XCTAssertFalse(
            try XCTUnwrap(
                state.change(
                    documentID: "first",
                    text: text,
                    plainTextColor: .black,
                    fontSize: 12
                )
            ).isNewDocument
        )
        XCTAssertTrue(
            try XCTUnwrap(
                state.change(
                    documentID: "second",
                    text: text,
                    plainTextColor: .white,
                    fontSize: 12
                )
            ).isNewDocument
        )
    }

    func testDocumentStateBuildsTheSharedLogicalLineIndex() {
        var state = CodeTextDocumentState()

        state.apply(
            documentID: "sample",
            text: AttributedString("first\nsecond\n"),
            plainTextColor: .white,
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

    #if os(macOS)
    func testInitialMacScrollPositionAccountsForContentInsets() {
        let origin = MacCodeScrollPosition.leadingOrigin(
            contentInsets: NSEdgeInsets(
                top: 52,
                left: 8,
                bottom: 4,
                right: 12
            )
        )

        XCTAssertEqual(origin, CGPoint(x: 0, y: -52))
    }

    func testMacScrollPositionPreservesContentOffsetWhenToolbarInsetChanges() {
        XCTAssertEqual(
            MacCodeScrollPosition.preservingContentOffset(
                CGPoint(x: 7, y: -52),
                previousTopInset: 52,
                newTopInset: 60
            ),
            CGPoint(x: 7, y: -60)
        )
        XCTAssertEqual(
            MacCodeScrollPosition.preservingContentOffset(
                CGPoint(x: 7, y: 148),
                previousTopInset: 52,
                newTopInset: 60
            ),
            CGPoint(x: 7, y: 140)
        )
    }

    @MainActor
    func testMacViewerKeepsFirstLineBelowToolbarWhileWindowResizes() throws {
        let highlights = CodeHighlightStore(grammars: [])
        let sourceCode = (1...200)
            .map {
                "let line\($0) = \($0) // " + String(repeating: "x", count: 60)
            }
            .joined(separator: "\n")
        let hostingView = NSHostingView(
            rootView: CodeViewer(
                documentID: "resize-test",
                sourceCode: sourceCode,
                highlightStore: highlights,
                language: "plain"
            )
            .ignoresSafeArea()
        )
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 500),
            styleMask: [.titled, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.toolbar = NSToolbar(identifier: "CodeViewerKit.ResizeTest")
        window.contentView = hostingView

        hostingView.layoutSubtreeIfNeeded()

        let scrollView = try XCTUnwrap(
            hostingView.firstDescendant(ofType: NSScrollView.self)
        )
        XCTAssertGreaterThan(scrollView.contentInsets.top, 0)
        XCTAssertFalse(scrollView.automaticallyAdjustsContentInsets)
        XCTAssertFalse(scrollView.contentView.automaticallyAdjustsContentInsets)
        XCTAssertEqual(
            scrollView.contentView.bounds.minY + scrollView.contentInsets.top,
            0,
            accuracy: 0.5
        )

        for size in [
            NSSize(width: 300, height: 350),
            NSSize(width: 900, height: 600)
        ] {
            window.setContentSize(size)
            hostingView.layoutSubtreeIfNeeded()

            XCTAssertEqual(
                scrollView.contentView.bounds.minY + scrollView.contentInsets.top,
                0,
                accuracy: 0.5
            )
        }
    }
    #endif

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
}

#if os(macOS)
private extension NSView {
    func firstDescendant<ViewType: NSView>(
        ofType type: ViewType.Type
    ) -> ViewType? {
        if let match = self as? ViewType {
            return match
        }

        for subview in subviews {
            if let match = subview.firstDescendant(ofType: type) {
                return match
            }
        }
        return nil
    }
}
#endif
