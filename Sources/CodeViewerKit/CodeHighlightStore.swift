import Observation
import SwiftUI

/// A session-scoped cache for highlighted source code.
///
/// Create one store at a stable ownership boundary and pass it to each
/// ``CodeViewer`` that should share prepared documents. Replacing the store
/// releases the cached source and highlighting results.
@Observable @MainActor
public final class CodeHighlightStore {
    private struct Key: Hashable, Sendable {
        let documentID: String
        let sourceCode: String
        let language: CodeLanguage
        let appearance: CodeHighlightAppearance
    }

    private let highlighter = CodeSyntaxHighlighter()
    private var snippets = [Key: AttributedString]()
    private var completedKeys = Set<Key>()
    private var preparationTasks = [Key: Task<AttributedString, Never>]()

    /// Creates an empty highlighting cache.
    public init() {}

    func displayedCode(
        documentID: String,
        sourceCode: String,
        language: CodeLanguage,
        colorScheme: ColorScheme
    ) -> AttributedString {
        let key = key(
            documentID: documentID,
            sourceCode: sourceCode,
            language: language,
            colorScheme: colorScheme
        )
        return snippets[key] ?? AttributedString(sourceCode)
    }

    /// Returns whether the complete highlighted representation is cached.
    ///
    /// The document identity, source contents, language, and color scheme all
    /// participate in the cache key.
    public func isPrepared(
        documentID: String,
        sourceCode: String,
        language: CodeLanguage = .swift,
        colorScheme: ColorScheme
    ) -> Bool {
        completedKeys.contains(
            key(
                documentID: documentID,
                sourceCode: sourceCode,
                language: language,
                colorScheme: colorScheme
            )
        )
    }

    /// Prepares highlighting for a source document.
    ///
    /// Every supported language is prepared as a complete document with
    /// native Tree-sitter. Calling this method again with the same inputs
    /// reuses the existing result or task.
    public func prepare(
        documentID: String,
        sourceCode: String,
        language: CodeLanguage = .swift,
        colorScheme: ColorScheme
    ) async {
        let key = key(
            documentID: documentID,
            sourceCode: sourceCode,
            language: language,
            colorScheme: colorScheme
        )
        guard !completedKeys.contains(key) else { return }

        let highlighter = highlighter

        let task: Task<AttributedString, Never>
        if let existingTask = preparationTasks[key] {
            task = existingTask
        } else {
            task = Task.detached(priority: .userInitiated) {
                await highlightSource(
                    sourceCode,
                    language: key.language,
                    appearance: key.appearance,
                    using: highlighter
                ) ?? AttributedString(sourceCode)
            }
            preparationTasks[key] = task
        }

        let highlightedText = await withTaskCancellationHandler {
            await task.value
        } onCancel: {
            task.cancel()
        }
        guard !Task.isCancelled else {
            preparationTasks[key] = nil
            return
        }

        snippets[key] = highlightedText
        completedKeys.insert(key)
        preparationTasks[key] = nil
    }

    private func key(
        documentID: String,
        sourceCode: String,
        language: CodeLanguage,
        colorScheme: ColorScheme
    ) -> Key {
        Key(
            documentID: documentID,
            sourceCode: sourceCode,
            language: language,
            appearance: colorScheme == .dark ? .dark : .light
        )
    }
}

private func highlightSource(
    _ sourceCode: String,
    language: CodeLanguage,
    appearance: CodeHighlightAppearance,
    using highlighter: CodeSyntaxHighlighter
) async -> AttributedString? {
    return await highlighter.attributedText(
        sourceCode,
        language: language,
        appearance: appearance
    )
}
