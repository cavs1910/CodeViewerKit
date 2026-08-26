import SwiftUI

/// A read-only Swift source viewer backed by TextKit 2.
///
/// `CodeViewer` provides progressive syntax highlighting, logical line
/// numbers, selection, native scrolling, and viewport-based layout on iOS,
/// iPadOS, and macOS. The view does not provide its own background or outer
/// decoration, so it can be embedded in the container that fits your app.
public struct CodeViewer: View {
    private struct HighlightRequest: Hashable {
        let documentID: String
        let sourceCode: String
        let usesDarkColors: Bool
    }

    private let documentID: String
    private let sourceCode: String
    private let highlightStore: CodeHighlightStore
    private let scrollIndicatorInsets: EdgeInsets

    @Environment(\.colorScheme) private var colorScheme

    /// Creates a read-only Swift source viewer.
    ///
    /// - Parameters:
    ///   - documentID: A stable identity for the document. Changing it resets
    ///     the native selection and scroll position; updating the source with
    ///     the same identity preserves them when possible.
    ///   - sourceCode: The complete Swift source to display.
    ///   - highlightStore: A session-scoped store shared by viewers that
    ///     should reuse prepared highlighting.
    ///   - scrollIndicatorInsets: Insets applied only to the native vertical
    ///     and horizontal scroll indicators.
    public init(
        documentID: String,
        sourceCode: String,
        highlightStore: CodeHighlightStore,
        scrollIndicatorInsets: EdgeInsets = EdgeInsets()
    ) {
        self.documentID = documentID
        self.sourceCode = sourceCode
        self.highlightStore = highlightStore
        self.scrollIndicatorInsets = scrollIndicatorInsets
    }

    public var body: some View {
        CodeTextView(
            documentID: documentID,
            text: highlightStore.displayedCode(
                documentID: documentID,
                sourceCode: sourceCode,
                colorScheme: colorScheme
            ),
            prewarmsLayout: highlightStore.isPrepared(
                documentID: documentID,
                sourceCode: sourceCode,
                colorScheme: colorScheme
            ),
            scrollIndicatorInsets: scrollIndicatorInsets
        )
        .task(id: highlightRequest) {
            await highlightStore.prepare(
                documentID: documentID,
                sourceCode: sourceCode,
                colorScheme: colorScheme
            )
        }
    }

    private var highlightRequest: HighlightRequest {
        HighlightRequest(
            documentID: documentID,
            sourceCode: sourceCode,
            usesDarkColors: colorScheme == .dark
        )
    }
}
