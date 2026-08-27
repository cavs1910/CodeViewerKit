import Foundation

/// A syntax-highlighting language understood by `CodeViewerKit`.
///
/// Use one of the predefined values, ``automatic``, or a supported alias:
///
/// ```swift
/// let language: CodeLanguage = "python"
/// ```
public struct CodeLanguage: Hashable, Sendable, ExpressibleByStringLiteral {
    let identifier: String?

    /// Creates a language from a Tree-sitter language identifier or alias.
    public init(_ identifier: String) {
        self.identifier = identifier
    }

    public init(stringLiteral value: String) {
        self.init(value)
    }

    private init(identifier: String?) {
        self.identifier = identifier
    }

    /// Detects a supported language from the source contents.
    public static let automatic = Self(identifier: nil)

    public static let bash: Self = "bash"
    public static let c: Self = "c"
    public static let cPlusPlus: Self = "cpp"
    public static let cSharp: Self = "csharp"
    public static let css: Self = "css"
    public static let go: Self = "go"
    public static let html: Self = "html"
    public static let java: Self = "java"
    public static let javaScript: Self = "javascript"
    public static let json: Self = "json"
    public static let kotlin: Self = "kotlin"
    public static let markdown: Self = "markdown"
    public static let objectiveC: Self = "objectivec"
    public static let php: Self = "php"
    public static let python: Self = "python"
    public static let ruby: Self = "ruby"
    public static let rust: Self = "rust"
    public static let shell: Self = "shell"
    public static let sql: Self = "sql"
    public static let swift: Self = "swift"
    public static let typeScript: Self = "typescript"
    public static let yaml: Self = "yaml"
}

extension CodeLanguage {
    func resolvedIdentifier(for sourceCode: String) -> String {
        identifier ?? AutomaticCodeLanguageDetector.detect(sourceCode)
    }
}

private enum AutomaticCodeLanguageDetector {
    static func detect(_ sourceCode: String) -> String {
        let source = sourceCode.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowercase = source.lowercased()

        if source.hasPrefix("{") || source.hasPrefix("[") {
            if (try? JSONSerialization.jsonObject(with: Data(source.utf8))) != nil {
                return "json"
            }
        }
        if lowercase.hasPrefix("<?php") { return "php" }
        if lowercase.hasPrefix("<!doctype html") || lowercase.hasPrefix("<html") {
            return "html"
        }
        if source.hasPrefix("#!") {
            if lowercase.contains("python") { return "python" }
            if lowercase.contains("ruby") { return "ruby" }
            return "bash"
        }
        if source.contains("@interface") || source.contains("@implementation") {
            return "objectivec"
        }
        if source.contains("import SwiftUI") || source.contains("import Foundation") {
            return "swift"
        }
        if lowercase.contains("using system;") || lowercase.contains("namespace ") {
            return "csharp"
        }
        if lowercase.hasPrefix("package ") && source.contains("fun ") {
            return "kotlin"
        }
        if lowercase.hasPrefix("package ") && source.contains("class ") {
            return "java"
        }
        if lowercase.hasPrefix("package ") || source.contains("func main()") {
            return "go"
        }
        if source.contains("fn main()") || source.contains("let mut ") {
            return "rust"
        }
        if source.contains("interface ") || source.contains(": string") {
            return "typescript"
        }
        if source.contains("=>") || source.contains("console.log(") {
            return "javascript"
        }
        if lowercase.hasPrefix("select ") || lowercase.hasPrefix("insert ")
            || lowercase.hasPrefix("update ") || lowercase.hasPrefix("create table ") {
            return "sql"
        }
        if source.hasPrefix("# ") || source.contains("\n## ")
            || source.contains("```") {
            return "markdown"
        }
        if source.contains("def ") && source.contains(":") { return "python" }
        if source.contains("#include") {
            return source.contains("std::") ? "cpp" : "c"
        }
        if source.contains("{") && source.contains("}")
            && (source.contains("color:") || source.contains("display:")) {
            return "css"
        }
        if source.hasPrefix("---") { return "yaml" }
        return "swift"
    }
}
