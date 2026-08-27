import Foundation
import XCTest
@testable import CodeViewerKit

#if os(macOS)
import AppKit
#else
import UIKit
#endif

final class CodeSyntaxHighlighterTests: XCTestCase {
    func testTreeSitterHighlightsEveryPredefinedLanguage() async throws {
        let samples: [(CodeLanguage, String)] = [
            (.bash, "if true; then echo \"Hello\"; fi"),
            (.c, "int main(void) { return 0; }"),
            (.cPlusPlus, "std::string value = \"Hello\";"),
            (.cSharp, "public class Greeter { }"),
            (.css, ".title { color: red; }"),
            (.go, "package main\nfunc main() {}"),
            (.html, "<main>Hello</main>"),
            (.java, "public class Greeter { }"),
            (.javaScript, "const value = \"Hello\";"),
            (.json, "{\"value\": true}"),
            (.kotlin, "class Greeter { fun greet() = \"Hello\" }"),
            (.markdown, "# Hello"),
            (.objectiveC, "@interface Greeter : NSObject\n@end"),
            (.php, "<?php echo \"Hello\"; ?>"),
            (.python, "def greet():\n    return \"Hello\""),
            (.ruby, "def greet\n  \"Hello\"\nend"),
            (.rust, "fn main() { let value = \"Hello\"; }"),
            (.shell, "if true; then echo \"Hello\"; fi"),
            (.sql, "SELECT name FROM people;"),
            (.swift, "let value = \"Hello\""),
            (.typeScript, "const value: string = \"Hello\";"),
            (.yaml, "enabled: true")
        ]
        let highlighter = CodeSyntaxHighlighter()

        for (language, source) in samples {
            let highlighted = await highlighter.attributedText(
                source,
                language: language,
                appearance: .dark
            )
            let result = try XCTUnwrap(
                highlighted,
                "Failed to highlight \(language.identifier ?? "automatic")"
            )
            let nativeText = NSAttributedString(result)
            var foundColor = false
            nativeText.enumerateAttribute(
                .foregroundColor,
                in: NSRange(location: 0, length: nativeText.length)
            ) { value, _, stop in
                if value != nil {
                    foundColor = true
                    stop.pointee = true
                }
            }
            XCTAssertTrue(
                foundColor,
                "No tokens highlighted for \(language.identifier ?? "automatic")"
            )
        }
    }

    func testAutomaticLanguageDetectionUsesTreeSitter() async throws {
        let source = "{\"enabled\": true}"
        let highlighter = CodeSyntaxHighlighter()
        let highlighted = await highlighter.attributedText(
            source,
            language: .automatic,
            appearance: .light
        )
        let result = try XCTUnwrap(highlighted)
        let nativeText = NSAttributedString(result)
        let booleanRange = (source as NSString).range(of: "true")

        XCTAssertNotNil(
            nativeText.attribute(
                .foregroundColor,
                at: booleanRange.location,
                effectiveRange: nil
            )
        )
    }

    func testUnknownLanguageReturnsPlainTextWithoutAnotherEngine() async throws {
        let source = "some custom syntax"
        let highlighter = CodeSyntaxHighlighter()
        let highlighted = await highlighter.attributedText(
            source,
            language: "unknown-language",
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
