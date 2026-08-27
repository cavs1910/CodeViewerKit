import Foundation
import SwiftTreeSitter

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
    private let specifications: [String: TreeSitterLanguageSpecification]
    private var highlighters = [String: TreeSitterCodeHighlighter]()
    private var failedLanguages = Set<String>()

    init(grammars: [CodeGrammar]) {
        specifications = grammars.reduce(into: [:]) { result, grammar in
            let specification = TreeSitterLanguageSpecification(
                identifier: grammar.identifier,
                language: grammar.language,
                queryURLs: grammar.queryURLs
            )
            for identifier in [grammar.identifier] + grammar.aliases {
                result[Self.normalized(identifier)] = specification
            }
        }
    }

    func attributedText(
        _ sourceCode: String,
        language: CodeLanguage,
        appearance: CodeHighlightAppearance
    ) -> AttributedString? {
        let identifier = language.resolvedIdentifier(for: sourceCode)
        guard let specification = specifications[Self.normalized(identifier)] else {
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

    private static func normalized(_ identifier: String) -> String {
        identifier.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
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
