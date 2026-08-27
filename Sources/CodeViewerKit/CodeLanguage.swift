/// A syntax-highlighting language understood by `CodeViewerKit`.
///
/// Use one of the common predefined values, ``automatic``, or any language
/// alias bundled by Highlight.js:
///
/// ```swift
/// let language: CodeLanguage = "elixir"
/// ```
public struct CodeLanguage: Hashable, Sendable, ExpressibleByStringLiteral {
    let identifier: String?

    /// Creates a language from a Highlight.js language identifier or alias.
    public init(_ identifier: String) {
        self.identifier = identifier
    }

    public init(stringLiteral value: String) {
        self.init(value)
    }

    private init(identifier: String?) {
        self.identifier = identifier
    }

    /// Lets Highlight.js detect the language from the source contents.
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
