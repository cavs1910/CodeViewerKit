import SwiftUI

/// A read-only source-code viewer backed by native TextKit views.
///
/// `CodeViewer` provides syntax highlighting, logical line numbers, selection,
/// native scrolling, and configurable layout preparation on iOS, iPadOS, and
/// macOS. The view does not provide its own background or outer decoration, so
/// it can be embedded in the container that fits your app.
public struct CodeViewer: View {
    private struct HighlightRequest: Hashable {
        let documentID: String
        let sourceCode: String
        let language: CodeLanguage
        let usesDarkColors: Bool
    }

    private let documentID: String
    private let sourceCode: String
    private let highlightStore: CodeHighlightStore
    private let language: CodeLanguage
    private let lineWrapping: CodeLineWrapping
    private let layoutPreparation: CodeLayoutPreparation
    private let plainTextColor: Color?

    @Environment(\.colorScheme) private var colorScheme

    /// Creates a read-only source-code viewer.
    ///
    /// - Parameters:
    ///   - documentID: A stable identity for the document. Changing it resets
    ///     the native selection and scroll position; updating the source with
    ///     the same identity preserves them when possible.
    ///   - sourceCode: The complete source code to display.
    ///   - highlightStore: A session-scoped store shared by viewers that
    ///     should reuse prepared highlighting.
    ///   - language: The language used for syntax highlighting. Swift is the
    ///     default; pass ``CodeLanguage/automatic`` to detect it from the
    ///     source contents.
    ///   - lineWrapping: How lines that exceed the viewer width are laid out.
    ///     The default keeps logical lines intact and allows horizontal
    ///     scrolling.
    ///   - layoutPreparation: How much native text layout is prepared before
    ///     scrolling. The default prepares complete layout up to
    ///     ``CodeLayoutPreparation/defaultAutomaticMaximumUTF16Length`` and
    ///     remains progressive above that threshold.
    ///   - plainTextColor: The color used for source ranges that do not yet
    ///     have a syntax color. Pass `nil` to use black in light mode and
    ///     white in dark mode.
    public init(
        documentID: String,
        sourceCode: String,
        highlightStore: CodeHighlightStore,
        language: CodeLanguage = .automatic,
        lineWrapping: CodeLineWrapping = .none,
        layoutPreparation: CodeLayoutPreparation = .automatic(
            maximumUTF16Length: CodeLayoutPreparation
                .defaultAutomaticMaximumUTF16Length
        ),
        plainTextColor: Color? = nil
    ) {
        self.documentID = documentID
        self.sourceCode = sourceCode
        self.highlightStore = highlightStore
        self.language = language
        self.lineWrapping = lineWrapping
        self.layoutPreparation = layoutPreparation
        self.plainTextColor = plainTextColor
    }

    public var body: some View {
        let snapshot = highlightStore.snapshot(
            documentID: documentID,
            sourceCode: sourceCode,
            language: language,
            colorScheme: colorScheme
        )

        CodeTextView(
            documentID: documentID,
            text: sourceCode,
            plainTextColor: CodePlainTextStyle.resolve(
                configuredColor: plainTextColor,
                colorScheme: colorScheme
            ),
            lineWrapping: lineWrapping,
            layoutPreparation: layoutPreparation,
            highlightLanguage: language,
            highlightAppearance: colorScheme == .dark ? .dark : .light,
            highlightBatches: snapshot.batches
        )
        .task(id: highlightRequest) {
            await highlightStore.prepare(
                documentID: documentID,
                sourceCode: sourceCode,
                language: language,
                colorScheme: colorScheme
            )
        }
    }

    private var highlightRequest: HighlightRequest {
        HighlightRequest(
            documentID: documentID,
            sourceCode: sourceCode,
            language: language,
            usesDarkColors: colorScheme == .dark
        )
    }
}

enum CodePlainTextStyle {
    static func resolve(
        configuredColor: Color?,
        colorScheme: ColorScheme
    ) -> Color {
        configuredColor ?? (colorScheme == .dark ? .white : .black)
    }
}
