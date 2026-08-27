/// Controls how `CodeViewer` lays out source lines that exceed its width.
public enum CodeLineWrapping: Hashable, Sendable {
    /// Keeps each logical source line on one visual line and allows horizontal
    /// scrolling when needed.
    case none

    /// Wraps long source lines at word boundaries to fit the viewer width.
    case word
}
