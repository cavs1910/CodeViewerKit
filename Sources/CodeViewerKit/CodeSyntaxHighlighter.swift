import Foundation
import SwiftTreeSitter
import TreeSitterBash
import TreeSitterBashQueries
import TreeSitterC
import TreeSitterCQueries
import TreeSitterCPP
import TreeSitterCPPQueries
import TreeSitterCSharp
import TreeSitterCSharpQueries
import TreeSitterCSS
import TreeSitterCSSQueries
import TreeSitterGo
import TreeSitterGoQueries
import TreeSitterHTML
import TreeSitterHTMLQueries
import TreeSitterJava
import TreeSitterJavaQueries
import TreeSitterJavaScript
import TreeSitterJavaScriptQueries
import TreeSitterJSON
import TreeSitterJSONQueries
import TreeSitterMarkdown
import TreeSitterMarkdownQueries
import TreeSitterPHP
import TreeSitterPHPQueries
import TreeSitterPython
import TreeSitterPythonQueries
import TreeSitterRuby
import TreeSitterRubyQueries
import TreeSitterRust
import TreeSitterRustQueries
import TreeSitterSQL
import TreeSitterSQLQueries
import TreeSitterSwift
import TreeSitterSwiftQueries
import TreeSitterTypeScript
import TreeSitterTypeScriptQueries
import TreeSitterYAML
import TreeSitterYAMLQueries

#if os(macOS)
import AppKit
private typealias CodeHighlightPlatformColor = NSColor
#else
import UIKit
private typealias CodeHighlightPlatformColor = UIColor
#endif

enum CodeHighlightAppearance: Hashable, Sendable {
    case light
    case dark
}

actor CodeSyntaxHighlighter {
    private var highlighters = [String: TreeSitterCodeHighlighter]()
    private var failedLanguages = Set<String>()

    func attributedText(
        _ sourceCode: String,
        language: CodeLanguage,
        appearance: CodeHighlightAppearance
    ) -> AttributedString? {
        let identifier = language.resolvedIdentifier(for: sourceCode)
        guard let specification = TreeSitterLanguageRegistry.specification(
            for: identifier
        ) else {
            return AttributedString(sourceCode)
        }
        guard let highlighter = preparedHighlighter(for: specification) else {
            return nil
        }
        return try? highlighter.attributedText(
            sourceCode,
            appearance: appearance
        )
    }

    private func preparedHighlighter(
        for specification: TreeSitterLanguageSpecification
    ) -> TreeSitterCodeHighlighter? {
        if let highlighter = highlighters[specification.identifier] {
            return highlighter
        }
        guard !failedLanguages.contains(specification.identifier) else {
            return nil
        }

        do {
            let highlighter = try TreeSitterCodeHighlighter(
                specification: specification
            )
            highlighters[specification.identifier] = highlighter
            return highlighter
        } catch {
            failedLanguages.insert(specification.identifier)
            return nil
        }
    }
}

final class TreeSitterCodeHighlighter {
    private let parser: Parser
    private let highlightQuery: SwiftTreeSitter.Query

    init(specification: TreeSitterLanguageSpecification) throws {
        let language = Language(specification.language)
        let queryData = try specification.queryURLs
            .map { try Data(contentsOf: $0) }
            .joinedQueries()
        let parser = Parser()
        try parser.setLanguage(language)
        self.parser = parser
        self.highlightQuery = try SwiftTreeSitter.Query(
            language: language,
            data: queryData
        )
    }

    func attributedText(
        _ sourceCode: String,
        appearance: CodeHighlightAppearance
    ) throws -> AttributedString {
        guard let tree = parser.parse(sourceCode) else {
            throw TreeSitterHighlightError.parsingFailed
        }

        let highlights = highlightQuery.execute(in: tree)
            .resolve(with: .init(string: sourceCode))
            .highlights()
        let result = NSMutableAttributedString(string: sourceCode)

        for highlight in highlights {
            guard let color = TreeSitterPalette.color(
                for: highlight.nameComponents,
                appearance: appearance
            ), NSMaxRange(highlight.range) <= result.length else {
                continue
            }
            result.addAttribute(
                .foregroundColor,
                value: color,
                range: highlight.range
            )
        }

#if os(macOS)
        return try AttributedString(result, including: \.appKit)
#else
        return try AttributedString(result, including: \.uiKit)
#endif
    }
}

struct TreeSitterLanguageSpecification {
    let identifier: String
    let language: OpaquePointer
    let queryURLs: [URL]
}

private enum TreeSitterLanguageRegistry {
    static func specification(
        for identifier: String
    ) -> TreeSitterLanguageSpecification? {
        switch normalized(identifier) {
        case "bash", "shell", "sh", "zsh":
            specification("bash", tree_sitter_bash(), TreeSitterBashQueries.Query.highlightsFileURL)
        case "c":
            specification("c", tree_sitter_c(), TreeSitterCQueries.Query.highlightsFileURL)
        case "cpp", "c++", "cc", "cxx":
            specification(
                "cpp", tree_sitter_cpp(),
                TreeSitterCQueries.Query.highlightsFileURL,
                TreeSitterCPPQueries.Query.highlightsFileURL
            )
        case "csharp", "c#", "cs":
            specification("csharp", tree_sitter_c_sharp(), TreeSitterCSharpQueries.Query.highlightsFileURL)
        case "css":
            specification("css", tree_sitter_css(), TreeSitterCSSQueries.Query.highlightsFileURL)
        case "go", "golang":
            specification("go", tree_sitter_go(), TreeSitterGoQueries.Query.highlightsFileURL)
        case "html", "htm":
            specification("html", tree_sitter_html(), TreeSitterHTMLQueries.Query.highlightsFileURL)
        case "java":
            specification("java", tree_sitter_java(), TreeSitterJavaQueries.Query.highlightsFileURL)
        case "javascript", "js", "jsx", "mjs", "cjs":
            specification("javascript", tree_sitter_javascript(), TreeSitterJavaScriptQueries.Query.highlightsFileURL)
        case "json":
            specification("json", tree_sitter_json(), TreeSitterJSONQueries.Query.highlightsFileURL)
        case "kotlin", "kt", "kts":
            specification("kotlin", tree_sitter_java(), TreeSitterJavaQueries.Query.highlightsFileURL)
        case "markdown", "md":
            specification("markdown", tree_sitter_markdown(), TreeSitterMarkdownQueries.Query.highlightsFileURL)
        case "objectivec", "objective-c", "objc", "m", "mm":
            specification("objectivec", tree_sitter_c(), TreeSitterCQueries.Query.highlightsFileURL)
        case "php":
            specification("php", tree_sitter_php(), TreeSitterPHPQueries.Query.highlightsFileURL)
        case "python", "py":
            specification("python", tree_sitter_python(), TreeSitterPythonQueries.Query.highlightsFileURL)
        case "ruby", "rb":
            specification("ruby", tree_sitter_ruby(), TreeSitterRubyQueries.Query.highlightsFileURL)
        case "rust", "rs":
            specification("rust", tree_sitter_rust(), TreeSitterRustQueries.Query.highlightsFileURL)
        case "sql":
            specification("sql", tree_sitter_sql(), TreeSitterSQLQueries.Query.highlightsFileURL)
        case "swift":
            specification("swift", tree_sitter_swift(), TreeSitterSwiftQueries.Query.highlightsFileURL)
        case "typescript", "ts":
            specification(
                "typescript", tree_sitter_typescript(),
                TreeSitterJavaScriptQueries.Query.highlightsFileURL,
                TreeSitterTypeScriptQueries.Query.highlightsFileURL
            )
        case "yaml", "yml":
            specification("yaml", tree_sitter_yaml(), TreeSitterYAMLQueries.Query.highlightsFileURL)
        default:
            nil
        }
    }

    private static func specification(
        _ identifier: String,
        _ language: OpaquePointer,
        _ queryURLs: URL...
    ) -> TreeSitterLanguageSpecification {
        TreeSitterLanguageSpecification(
            identifier: identifier,
            language: language,
            queryURLs: queryURLs
        )
    }

    private static func normalized(_ identifier: String) -> String {
        identifier.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

private extension Array where Element == Data {
    func joinedQueries() -> Data {
        reduce(into: Data()) { result, query in
            if !result.isEmpty { result.append(contentsOf: [0x0A]) }
            result.append(query)
        }
    }
}

private enum TreeSitterHighlightError: Error {
    case parsingFailed
}

private enum TreeSitterPalette {
    static func color(
        for nameComponents: [String],
        appearance: CodeHighlightAppearance
    ) -> CodeHighlightPlatformColor? {
        guard let category = nameComponents.first else { return nil }

        return switch category {
        case "attribute", "property":
            color(light: 0x9C2F_AE, dark: 0xD0A8_FF, appearance: appearance)
        case "boolean", "character", "constant", "number":
            color(light: 0x272A_D8, dark: 0xD0BF_69, appearance: appearance)
        case "comment":
            color(light: 0x5D6C_79, dark: 0x7F8C_98, appearance: appearance)
        case "constructor", "function", "method":
            color(light: 0x326D_74, dark: 0x67B7_A4, appearance: appearance)
        case "keyword", "label", "operator", "punctuation", "tag", "text":
            color(light: 0xAD3D_A4, dark: 0xFF7A_B2, appearance: appearance)
        case "string":
            color(light: 0xD12F_1B, dark: 0xFC6A_5D, appearance: appearance)
        case "type":
            color(light: 0x703D_AA, dark: 0xDABA_FF, appearance: appearance)
        case "variable":
            nameComponents.contains("builtin")
                ? color(light: 0x703D_AA, dark: 0xDABA_FF, appearance: appearance)
                : nil
        default:
            nil
        }
    }

    private static func color(
        light: UInt32,
        dark: UInt32,
        appearance: CodeHighlightAppearance
    ) -> CodeHighlightPlatformColor {
        let value = appearance == .dark ? dark : light
        return CodeHighlightPlatformColor(
            red: CGFloat((value >> 16) & 0xFF) / 255,
            green: CGFloat((value >> 8) & 0xFF) / 255,
            blue: CGFloat(value & 0xFF) / 255,
            alpha: 1
        )
    }
}
