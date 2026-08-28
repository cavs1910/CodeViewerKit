import Foundation
import SwiftTreeSitter

actor CodeSyntaxHighlighter {
    private let specifications: [String: TreeSitterLanguageSpecification]
    private let detectedSpecifications: [TreeSitterLanguageSpecification]
    private var highlighters = [String: TreeSitterCodeHighlighter]()
    private var failedLanguages = Set<String>()

    init(grammars: [CodeGrammar]) {
        var specifications = [String: TreeSitterLanguageSpecification]()
        var detectedSpecifications = [TreeSitterLanguageSpecification]()

        for grammar in grammars {
            let specification = TreeSitterLanguageSpecification(
                identifier: grammar.identifier,
                language: grammar.language,
                queryURLs: grammar.queryURLs,
                detectsSource: grammar.detectsSource
            )
            for identifier in [grammar.identifier] + grammar.aliases {
                specifications[Self.normalized(identifier)] = specification
            }
            if grammar.detectsSource != nil {
                detectedSpecifications.append(specification)
            }
        }

        self.specifications = specifications
        self.detectedSpecifications = detectedSpecifications
    }

    func highlightedBatches(
        _ sourceCode: String,
        language: CodeLanguage
    ) -> AsyncStream<CodeHighlightBatch> {
        let specification: TreeSitterLanguageSpecification?
        if let identifier = language.identifier {
            specification = specifications[Self.normalized(identifier)]
        } else {
            specification = detectedSpecifications.first {
                $0.detectsSource?(sourceCode) == true
            }
        }
        guard let specification else {
            return Self.finishedStream()
        }
        guard let highlighter = preparedHighlighter(for: specification) else {
            return Self.finishedStream()
        }

        return AsyncStream { continuation in
            let producer = Task {
                defer { continuation.finish() }
                try? await highlighter.emitBatches(
                    for: sourceCode,
                    continuation: continuation
                )
            }
            continuation.onTermination = { _ in
                producer.cancel()
            }
        }
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

    private static func finishedStream() -> AsyncStream<CodeHighlightBatch> {
        AsyncStream { $0.finish() }
    }
}

actor TreeSitterCodeHighlighter {
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

    func emitBatches(
        for sourceCode: String,
        continuation: AsyncStream<CodeHighlightBatch>.Continuation
    ) async throws {
        guard let tree = parser.parse(sourceCode) else {
            throw TreeSitterHighlightError.parsingFailed
        }

        for (sequence, range) in CodeHighlightChunker.ranges(
            in: sourceCode
        ).enumerated() {
            guard !Task.isCancelled else { return }

            let cursor = highlightQuery.execute(in: tree)
            cursor.setRange(range)
            let spans = cursor
                .resolve(with: .init(string: sourceCode))
                .highlights()
                .compactMap { highlight -> CodeHighlightSpan? in
                    guard let token = CodeHighlightToken(
                        nameComponents: highlight.nameComponents
                    ) else { return nil }
                    return CodeHighlightSpan(
                        range: highlight.range,
                        token: token
                    )
                }

            continuation.yield(
                CodeHighlightBatch(
                    sequence: sequence,
                    coveredRange: range,
                    spans: spans
                )
            )
            await Task.yield()
        }
    }
}

struct TreeSitterLanguageSpecification: @unchecked Sendable {
    let identifier: String
    let language: OpaquePointer
    let queryURLs: [URL]
    let detectsSource: (@Sendable (String) -> Bool)?
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
