import Observation
import SwiftUI

/// A session-scoped cache for highlighted source code.
///
/// Create one store at a stable ownership boundary and pass it to each
/// ``CodeViewer`` that should share prepared documents. Replacing the store
/// releases the cached source and progressive highlighting results.
@Observable @MainActor
public final class CodeHighlightStore {
    private struct Key: Hashable, Sendable {
        let documentID: String
        let sourceCode: String
        let language: CodeLanguage
        let appearance: CodeHighlightAppearance

        func hash(into hasher: inout Hasher) {
            hasher.combine(documentID)
            hasher.combine(sourceCode.utf16.count)
            hasher.combine(language)
            hasher.combine(appearance)
        }
    }

    private final class Entry {
        var batches: [CodeHighlightBatch] = []
        var isPrepared = false
    }

    private let highlighter: CodeSyntaxHighlighter
    @ObservationIgnored private var entries = [Key: Entry]()
    @ObservationIgnored private var preparationTasks = [Key: Task<Bool, Never>]()
    private var revision = 0

    /// Creates an empty highlighting cache using the linked grammars.
    public init(grammars: [CodeGrammar]) {
        highlighter = CodeSyntaxHighlighter(grammars: grammars)
    }

    func snapshot(
        documentID: String,
        sourceCode: String,
        language: CodeLanguage,
        colorScheme: ColorScheme
    ) -> CodeHighlightSnapshot {
        _ = revision
        let key = key(
            documentID: documentID,
            sourceCode: sourceCode,
            language: language,
            colorScheme: colorScheme
        )
        let entry = entries[key]
        return CodeHighlightSnapshot(batches: entry?.batches ?? [])
    }

    /// Returns whether all highlighting batches are cached.
    ///
    /// The document identity, source contents, language, and color scheme all
    /// participate in the cache key.
    public func isPrepared(
        documentID: String,
        sourceCode: String,
        language: CodeLanguage = .automatic,
        colorScheme: ColorScheme
    ) -> Bool {
        _ = revision
        return entries[
            key(
                documentID: documentID,
                sourceCode: sourceCode,
                language: language,
                colorScheme: colorScheme
            )
        ]?.isPrepared ?? false
    }

    /// Prepares highlighting for a source document.
    ///
    /// Tree-sitter parses the document away from the main actor, then query
    /// results are published progressively from the start of the document.
    /// Calling this method again with the same inputs reuses the existing
    /// batches and task.
    public func prepare(
        documentID: String,
        sourceCode: String,
        language: CodeLanguage = .automatic,
        colorScheme: ColorScheme
    ) async {
        let key = key(
            documentID: documentID,
            sourceCode: sourceCode,
            language: language,
            colorScheme: colorScheme
        )
        guard entries[key]?.isPrepared != true else { return }

        let highlighter = highlighter

        let task: Task<Bool, Never>
        if let existingTask = preparationTasks[key] {
            task = existingTask
        } else {
            task = Task { [weak self] in
                let stream = await highlighter.highlightedBatches(
                    sourceCode,
                    language: key.language
                )
                for await batch in stream {
                    guard !Task.isCancelled else { return false }
                    self?.record(batch, for: key)
                }
                return !Task.isCancelled
            }
            preparationTasks[key] = task
        }

        let completed = await withTaskCancellationHandler {
            await task.value
        } onCancel: {
            task.cancel()
        }
        guard completed, !Task.isCancelled else {
            preparationTasks[key] = nil
            return
        }

        let entry = entries[key] ?? Entry()
        entry.isPrepared = true
        entries[key] = entry
        revision &+= 1
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

    private func record(_ batch: CodeHighlightBatch, for key: Key) {
        let entry = entries[key] ?? Entry()
        guard batch.sequence == entry.batches.count else { return }
        entry.batches.append(batch)
        entries[key] = entry
        revision &+= 1
    }
}
