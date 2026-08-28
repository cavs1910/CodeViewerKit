/// Controls how much native text layout `CodeViewer` prepares before scrolling.
public enum CodeLayoutPreparation: Hashable, Sendable {
    /// The UTF-16 threshold used by `CodeViewer` when no explicit layout
    /// preparation policy is supplied.
    public static let defaultAutomaticMaximumUTF16Length = 64_000

    /// Lays out visible ranges on demand. This is the default and keeps very
    /// large documents responsive, but the scroll extent can be refined as
    /// previously unlaid ranges become visible.
    case progressive

    /// Lays out the complete document once the native text container has a
    /// usable width. This produces an exact initial scroll extent, but can
    /// block the main thread for large documents.
    case complete

    /// Uses complete layout when the document's UTF-16 length is at or below
    /// `maximumUTF16Length`, and progressive layout otherwise.
    ///
    /// Negative limits are treated as zero.
    case automatic(maximumUTF16Length: Int)
}

extension CodeLayoutPreparation {
    func preparesCompleteLayout(forUTF16Length length: Int) -> Bool {
        switch self {
        case .progressive:
            false
        case .complete:
            true
        case let .automatic(maximumUTF16Length):
            length <= max(0, maximumUTF16Length)
        }
    }
}
