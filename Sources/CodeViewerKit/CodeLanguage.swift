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

    /// Asks the registered grammars to detect the source contents.
    public static let automatic = Self(identifier: nil)
}
