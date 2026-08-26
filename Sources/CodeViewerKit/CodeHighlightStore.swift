import HighlightSwift
import Observation
import SwiftUI

/// A session-scoped cache for progressively highlighted Swift source code.
///
/// Create one store at a stable ownership boundary and pass it to each
/// ``CodeViewer`` that should share prepared documents. Replacing the store
/// releases the cached source and highlighting results.
@Observable @MainActor
public final class CodeHighlightStore {
    private enum Appearance: Hashable, Sendable {
        case light
        case dark

        var colors: HighlightColors {
            switch self {
            case .light: .light(.xcode)
            case .dark: .dark(.xcode)
            }
        }
    }

    private struct Key: Hashable, Sendable {
        let documentID: String
        let sourceCode: String
        let appearance: Appearance
    }

    private let highlighter = Highlight()
    private var snippets = [Key: AttributedString]()
    private var completedKeys = Set<Key>()
    private var preparationTasks = [Key: Task<AttributedString, Never>]()

    /// Creates an empty highlighting cache.
    public init() {}

    func displayedCode(
        documentID: String,
        sourceCode: String,
        colorScheme: ColorScheme
    ) -> AttributedString {
        let key = key(
            documentID: documentID,
            sourceCode: sourceCode,
            colorScheme: colorScheme
        )
        return snippets[key] ?? AttributedString(sourceCode)
    }

    /// Returns whether the complete highlighted representation is cached.
    ///
    /// The document identity, source contents, and color scheme all
    /// participate in the cache key.
    public func isPrepared(
        documentID: String,
        sourceCode: String,
        colorScheme: ColorScheme
    ) -> Bool {
        completedKeys.contains(
            key(
                documentID: documentID,
                sourceCode: sourceCode,
                colorScheme: colorScheme
            )
        )
    }

    /// Progressively prepares highlighting for a Swift source document.
    ///
    /// The first 80 logical lines are prepared with user-initiated priority.
    /// The complete document then finishes at utility priority. Calling this
    /// method again with the same inputs reuses the existing result or task.
    public func prepare(
        documentID: String,
        sourceCode: String,
        colorScheme: ColorScheme
    ) async {
        let key = key(
            documentID: documentID,
            sourceCode: sourceCode,
            colorScheme: colorScheme
        )
        guard !completedKeys.contains(key) else { return }

        let highlighter = highlighter

        if snippets[key] == nil {
            let (leadingSource, remainingSource) = ProgressiveCodeHighlight
                .splitLeadingLines(sourceCode)
            let leadingText = await Task.detached(priority: .userInitiated) {
                try? await highlighter.attributedText(
                    leadingSource,
                    language: .swift,
                    colors: key.appearance.colors
                )
            }.value

            var stagedText = leadingText ?? AttributedString(leadingSource)
            stagedText.append(AttributedString(remainingSource))
            snippets[key] = stagedText
            await Task.yield()
            guard !Task.isCancelled else { return }
        }

        let task: Task<AttributedString, Never>
        if let existingTask = preparationTasks[key] {
            task = existingTask
        } else {
            task = Task.detached(priority: .utility) {
                (try? await highlighter.attributedText(
                    sourceCode,
                    language: .swift,
                    colors: key.appearance.colors
                )) ?? AttributedString(sourceCode)
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
        colorScheme: ColorScheme
    ) -> Key {
        Key(
            documentID: documentID,
            sourceCode: sourceCode,
            appearance: colorScheme == .dark ? .dark : .light
        )
    }
}
