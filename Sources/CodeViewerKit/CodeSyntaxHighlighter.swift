import Foundation
import HighlightSwift
import SwiftTreeSitter
import TreeSitterSwift

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

    var highlightSwiftColors: HighlightColors {
        switch self {
        case .light: .light(.xcode)
        case .dark: .dark(.xcode)
        }
    }
}

actor CodeSyntaxHighlighter {
    private let fallbackHighlighter = Highlight()
    private var swiftTreeSitterHighlighter: SwiftTreeSitterHighlighter?
    private var swiftHighlighterInitializationFailed = false

    nonisolated static func highlightsWholeDocumentImmediately(
        language: CodeLanguage
    ) -> Bool {
        language.identifier == CodeLanguage.swift.identifier
    }

    func attributedText(
        _ sourceCode: String,
        language: CodeLanguage,
        appearance: CodeHighlightAppearance
    ) async -> AttributedString? {
        if Self.highlightsWholeDocumentImmediately(language: language),
           let highlightedText = swiftAttributedText(
               sourceCode,
               appearance: appearance
           ) {
            return highlightedText
        }

        if let identifier = language.identifier {
            return try? await fallbackHighlighter.attributedText(
                sourceCode,
                language: identifier,
                colors: appearance.highlightSwiftColors
            )
        }

        return try? await fallbackHighlighter.attributedText(
            sourceCode,
            colors: appearance.highlightSwiftColors
        )
    }

    private func swiftAttributedText(
        _ sourceCode: String,
        appearance: CodeHighlightAppearance
    ) -> AttributedString? {
        guard let highlighter = preparedSwiftHighlighter() else { return nil }
        return try? highlighter.attributedText(
            sourceCode,
            appearance: appearance
        )
    }

    private func preparedSwiftHighlighter() -> SwiftTreeSitterHighlighter? {
        if let swiftTreeSitterHighlighter {
            return swiftTreeSitterHighlighter
        }
        guard !swiftHighlighterInitializationFailed else { return nil }

        do {
            let highlighter = try SwiftTreeSitterHighlighter()
            swiftTreeSitterHighlighter = highlighter
            return highlighter
        } catch {
            swiftHighlighterInitializationFailed = true
            return nil
        }
    }
}

final class SwiftTreeSitterHighlighter {
    private let parser: Parser
    private let highlightQuery: Query

    init() throws {
        let configuration = try SwiftTreeSitterResources.configuration()
        guard let highlightQuery = configuration.queries[.highlights] else {
            throw SwiftTreeSitterHighlightError.missingHighlightQuery
        }

        let parser = Parser()
        try parser.setLanguage(configuration.language)
        self.parser = parser
        self.highlightQuery = highlightQuery
    }

    func attributedText(
        _ sourceCode: String,
        appearance: CodeHighlightAppearance
    ) throws -> AttributedString {
        guard let tree = parser.parse(sourceCode) else {
            throw SwiftTreeSitterHighlightError.parsingFailed
        }

        let highlights = highlightQuery.execute(in: tree)
            .resolve(with: .init(string: sourceCode))
            .highlights()
        let result = NSMutableAttributedString(string: sourceCode)

        for highlight in highlights {
            guard let color = SwiftTreeSitterPalette.color(
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

private enum SwiftTreeSitterResources {
    private static let bundleName = "TreeSitterSwift_TreeSitterSwift.bundle"

    static func configuration() throws -> LanguageConfiguration {
        guard let queriesURL = queriesURL() else {
            throw SwiftTreeSitterHighlightError.missingHighlightQuery
        }
        return try LanguageConfiguration(
            tree_sitter_swift(),
            name: "Swift",
            queriesURL: queriesURL
        )
    }

    private static func queriesURL() -> URL? {
        // SwiftPM uses a flat resource bundle beside command-line and test
        // executables on macOS, while SwiftTreeSitter currently probes only
        // Contents/Resources. Keep both layouts until its loader handles both.
        let discoveredBundles = Bundle.allBundles + Bundle.allFrameworks
        let roots = [
            Bundle.main.bundleURL,
            Bundle.main.resourceURL,
            Bundle.main.executableURL?.deletingLastPathComponent()
        ].compactMap { $0 } + discoveredBundles.flatMap { bundle in
            [
                bundle.bundleURL,
                bundle.resourceURL,
                bundle.bundleURL.deletingLastPathComponent()
            ].compactMap { $0 }
        }

        for root in roots {
            let parserBundle = root.lastPathComponent == bundleName
                ? root
                : root.appendingPathComponent(bundleName, isDirectory: true)
            let candidates = [
                parserBundle.appendingPathComponent("queries", isDirectory: true),
                parserBundle.appendingPathComponent(
                    "Contents/Resources/queries",
                    isDirectory: true
                )
            ]
            if let candidate = candidates.first(where: { queriesURL in
                FileManager.default.isReadableFile(
                    atPath: queriesURL
                        .appendingPathComponent("highlights.scm")
                        .path
                )
            }) {
                return candidate
            }
        }

        return nil
    }
}

private enum SwiftTreeSitterHighlightError: Error {
    case missingHighlightQuery
    case parsingFailed
}

private enum SwiftTreeSitterPalette {
    static func color(
        for nameComponents: [String],
        appearance: CodeHighlightAppearance
    ) -> CodeHighlightPlatformColor? {
        guard let category = nameComponents.first else { return nil }

        return switch category {
        case "attribute":
            color(light: 0x9C2F_AE, dark: 0xD0A8_FF, appearance: appearance)
        case "boolean", "character", "constant", "number":
            color(light: 0x272A_D8, dark: 0xD0BF_69, appearance: appearance)
        case "comment":
            color(light: 0x5D6C_79, dark: 0x7F8C_98, appearance: appearance)
        case "constructor", "function":
            color(light: 0x326D_74, dark: 0x67B7_A4, appearance: appearance)
        case "keyword", "label":
            color(light: 0xAD3D_A4, dark: 0xFF7A_B2, appearance: appearance)
        case "string":
            color(light: 0xD12F_1B, dark: 0xFC6A_5D, appearance: appearance)
        case "type":
            color(light: 0x703D_AA, dark: 0xDABA_FF, appearance: appearance)
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
