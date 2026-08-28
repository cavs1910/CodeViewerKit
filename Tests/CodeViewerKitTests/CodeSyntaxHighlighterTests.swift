import XCTest
@testable import CodeViewerKit

final class CodeSyntaxHighlighterTests: XCTestCase {
    func testUnregisteredLanguageProducesNoHighlightBatches() async {
        let source = "some custom syntax"
        let highlighter = CodeSyntaxHighlighter(grammars: [])
        let stream = await highlighter.highlightedBatches(
            source,
            language: "language-created-tomorrow"
        )

        var batches: [CodeHighlightBatch] = []
        for await batch in stream {
            batches.append(batch)
        }

        XCTAssertTrue(batches.isEmpty)
    }

    func testChunkRangesCoverTheDocumentWithoutGaps() {
        let source = "first\nsecond\nthird\nfourth"
        let ranges = CodeHighlightChunker.ranges(
            in: source,
            targetUTF16Length: 7
        )

        XCTAssertEqual(ranges.first?.location, 0)
        XCTAssertEqual(ranges.last.map(NSMaxRange), (source as NSString).length)
        for pair in zip(ranges, ranges.dropFirst()) {
            XCTAssertEqual(NSMaxRange(pair.0), pair.1.location)
        }
    }

    func testHighlightTokenPreservesPaletteCategories() {
        XCTAssertEqual(
            CodeHighlightToken(nameComponents: ["variable", "builtin"]),
            .builtinVariable
        )
        XCTAssertNil(CodeHighlightToken(nameComponents: ["variable"]))
        XCTAssertEqual(
            CodeHighlightToken.string.colorValue(for: .dark),
            0xFC6A_5D
        )
    }
}
