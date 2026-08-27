import Foundation
import SwiftUI

#if os(macOS)
import AppKit
private typealias CodePlatformColor = NSColor
private typealias CodePlatformFont = NSFont
#else
import UIKit
private typealias CodePlatformColor = UIColor
private typealias CodePlatformFont = UIFont
#endif

struct CodeTextView: View {
    static let minimumFontSize: CGFloat = 9
    static let maximumFontSize: CGFloat = 28
    static let fontSizeStep: CGFloat = 1

    let documentID: String
    let text: AttributedString
    let plainTextColor: Color
    let lineWrapping: CodeLineWrapping
    let prewarmsLayout: Bool

    @State private var fontSize = PlatformCodeTextView.defaultFontSize

    var body: some View {
        PlatformCodeTextView(
            request: CodeTextRenderRequest(
                documentID: documentID,
                text: text,
                plainTextColor: plainTextColor,
                fontSize: fontSize,
                lineWrapping: lineWrapping,
                prewarmsLayout: prewarmsLayout
            )
        )
        .focusedSceneValue(\.codeTextFontSize, $fontSize)
    }
}

private struct CodeTextFontSizeKey: FocusedValueKey {
    typealias Value = Binding<CGFloat>
}

extension FocusedValues {
    fileprivate var codeTextFontSize: Binding<CGFloat>? {
        get { self[CodeTextFontSizeKey.self] }
        set { self[CodeTextFontSizeKey.self] = newValue }
    }
}

/// Menu commands that resize the currently focused ``CodeViewer``.
///
/// Add this command set to an app scene to enable Command-Plus and
/// Command-Minus while a code viewer is focused.
public struct CodeViewerCommands: Commands {
    @FocusedValue(\.codeTextFontSize) private var fontSize

    public init() {}

    public var body: some Commands {
        CommandGroup(after: .toolbar) {
            Button("Increase Code Text Size") {
                adjustFontSize(by: CodeTextView.fontSizeStep)
            }
            .keyboardShortcut("+", modifiers: .command)
            .disabled(!canIncreaseFontSize)

            Button("Decrease Code Text Size") {
                adjustFontSize(by: -CodeTextView.fontSizeStep)
            }
            .keyboardShortcut("-", modifiers: .command)
            .disabled(!canDecreaseFontSize)
        }
    }

    private var canIncreaseFontSize: Bool {
        guard let fontSize else { return false }
        return fontSize.wrappedValue < CodeTextView.maximumFontSize
    }

    private var canDecreaseFontSize: Bool {
        guard let fontSize else { return false }
        return fontSize.wrappedValue > CodeTextView.minimumFontSize
    }

    private func adjustFontSize(by change: CGFloat) {
        guard let fontSize else { return }
        fontSize.wrappedValue = min(
            max(fontSize.wrappedValue + change, CodeTextView.minimumFontSize),
            CodeTextView.maximumFontSize
        )
    }
}

private struct CodeTextRenderRequest {
    let documentID: String
    let text: AttributedString
    let plainTextColor: Color
    let fontSize: CGFloat
    let lineWrapping: CodeLineWrapping
    let prewarmsLayout: Bool
}

struct CodeTextDocumentChange: Equatable {
    let isNewDocument: Bool
}

struct CodeTextDocumentState {
    private(set) var documentID: String?
    private(set) var content: AttributedString?
    private(set) var plainTextColor: Color?
    private(set) var fontSize: CGFloat?
    private(set) var lineIndex = CodeLineIndex(text: "")

    func change(
        documentID: String,
        text: AttributedString,
        plainTextColor: Color,
        fontSize: CGFloat
    ) -> CodeTextDocumentChange? {
        guard self.documentID != documentID
                || content != text
                || self.plainTextColor != plainTextColor
                || self.fontSize != fontSize
        else { return nil }
        return CodeTextDocumentChange(isNewDocument: self.documentID != documentID)
    }

    mutating func apply(
        documentID: String,
        text: AttributedString,
        plainTextColor: Color,
        fontSize: CGFloat,
        plainText: String
    ) {
        self.documentID = documentID
        content = text
        self.plainTextColor = plainTextColor
        self.fontSize = fontSize
        lineIndex = CodeLineIndex(text: plainText)
    }
}

enum CodeGutterMetrics {
    static let horizontalInset: CGFloat = 8
    static let lineNumberOffset: CGFloat = 4

    static func digitSample(lineCount: Int) -> NSString {
        let digits = max(2, String(lineCount).count)
        return String(repeating: "0", count: digits) as NSString
    }

    static func requiredWidth(measuredLabelWidth: CGFloat) -> CGFloat {
        ceil(measuredLabelWidth + horizontalInset * 2)
    }

    static func lineNumberOriginX(
        containerWidth: CGFloat,
        labelWidth: CGFloat
    ) -> CGFloat {
        containerWidth - horizontalInset - lineNumberOffset - labelWidth
    }

    static func frames(
        in bounds: CGRect,
        gutterWidth: CGFloat
    ) -> (gutter: CGRect, text: CGRect) {
        (
            gutter: CGRect(
                x: 0,
                y: 0,
                width: gutterWidth,
                height: bounds.height
            ),
            text: CGRect(
                x: gutterWidth,
                y: 0,
                width: max(0, bounds.width - gutterWidth),
                height: bounds.height
            )
        )
    }
}

private struct CodeGutterRenderer {
    var markers: [CodeLineMarker] = []
    var font: CodePlatformFont
    var lineCount = 1

    var requiredWidth: CGFloat {
        let sample = CodeGutterMetrics.digitSample(lineCount: lineCount)
        return CodeGutterMetrics.requiredWidth(
            measuredLabelWidth: sample.size(withAttributes: [.font: font]).width
        )
    }

    mutating func updateMetrics(
        lineCount: Int,
        font: CodePlatformFont
    ) -> Bool {
        let oldWidth = requiredWidth
        self.lineCount = lineCount
        self.font = font
        return requiredWidth != oldWidth
    }

    mutating func updateMarkers(_ markers: [CodeLineMarker]) -> Bool {
        guard self.markers != markers else { return false }
        self.markers = markers
        return true
    }

    func draw(in bounds: CGRect, color: CodePlatformColor) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        for marker in markers {
            let label = String(marker.number) as NSString
            let size = label.size(withAttributes: attributes)
            label.draw(
                at: CGPoint(
                    x: CodeGutterMetrics.lineNumberOriginX(
                        containerWidth: bounds.maxX,
                        labelWidth: size.width
                    ),
                    y: marker.verticalPosition
                ),
                withAttributes: attributes
            )
        }
    }
}

@MainActor
private final class CodeGutterUpdateCoordinator {
    private var updateScheduled = false
    private var isUpdating = false

    func schedule(_ update: @escaping @MainActor () -> Void) {
        guard !updateScheduled else { return }
        updateScheduled = true

        Task { @MainActor [weak self] in
            guard let self else { return }
            updateScheduled = false
            update()
        }
    }

    func perform(_ update: () -> Void) {
        guard !isUpdating else { return }
        isUpdating = true
        defer { isUpdating = false }
        update()
    }
}

private enum CodeTextStyle {
    static func font(ofSize size: CGFloat) -> CodePlatformFont {
        CodePlatformFont(name: "Menlo-Regular", size: size)
            ?? CodePlatformFont.monospacedSystemFont(ofSize: size, weight: .regular)
    }

    static func attributedText(
        _ text: AttributedString,
        font: CodePlatformFont,
        plainTextColor: Color
    ) -> NSAttributedString {
        let result = NSMutableAttributedString(attributedString: NSAttributedString(text))
        result.addAttribute(
            .font,
            value: font,
            range: NSRange(location: 0, length: result.length)
        )
        CodeNativeTextColor.applyFallback(plainTextColor, to: result)
        return result
    }
}

/// Applies the fallback through TextKit's native attribute scope. A SwiftUI
/// `Color` stored directly in `AttributedString` bridges as
/// `SwiftUI.ForegroundColor`, which `NSTextView` and `UITextView` ignore.
enum CodeNativeTextColor {
    static func applyFallback(
        _ color: Color,
        to text: NSMutableAttributedString
    ) {
        let fullRange = NSRange(location: 0, length: text.length)
        guard fullRange.length > 0 else { return }

        var rangesWithoutColor: [NSRange] = []
        text.enumerateAttribute(.foregroundColor, in: fullRange) { value, range, _ in
            if value == nil {
                rangesWithoutColor.append(range)
            }
        }

        let platformColor = CodePlatformColor(color)
        for range in rangesWithoutColor {
            text.addAttribute(.foregroundColor, value: platformColor, range: range)
        }
    }
}

private struct CodeTextPreparedUpdate {
    let change: CodeTextDocumentChange
    let attributedText: NSAttributedString
    let font: CodePlatformFont
    let lineCount: Int
}

private extension CodeTextDocumentState {
    mutating func prepareUpdate(
        for request: CodeTextRenderRequest
    ) -> CodeTextPreparedUpdate? {
        guard let change = change(
            documentID: request.documentID,
            text: request.text,
            plainTextColor: request.plainTextColor,
            fontSize: request.fontSize
        ) else { return nil }

        let font = CodeTextStyle.font(ofSize: request.fontSize)
        let attributedText = CodeTextStyle.attributedText(
            request.text,
            font: font,
            plainTextColor: request.plainTextColor
        )
        apply(
            documentID: request.documentID,
            text: request.text,
            plainTextColor: request.plainTextColor,
            fontSize: request.fontSize,
            plainText: attributedText.string
        )
        return CodeTextPreparedUpdate(
            change: change,
            attributedText: attributedText,
            font: font,
            lineCount: lineIndex.count
        )
    }
}

#if os(macOS)

enum MacCodeScrollPosition {
    static func leadingOrigin(contentInsets: NSEdgeInsets) -> CGPoint {
        CGPoint(x: 0, y: -contentInsets.top)
    }
}

private struct PlatformCodeTextView: NSViewRepresentable {
    static let defaultFontSize = NSFont.systemFontSize(for: .small)

    let request: CodeTextRenderRequest

    func makeNSView(context: Context) -> MacCodeTextContainer {
        MacCodeTextContainer()
    }

    func updateNSView(_ container: MacCodeTextContainer, context: Context) {
        container.update(request)
    }
}

@MainActor
private final class MacCodeTextContainer: NSView {
    private let gutterView = MacCodeGutterView()
    private let scrollView: NSScrollView
    private let textView: NSTextView
    private var documentState = CodeTextDocumentState()
    private let gutterUpdates = CodeGutterUpdateCoordinator()
    private var lineWrapping: CodeLineWrapping?
    private var needsInitialScrollPosition = false

    override var isFlipped: Bool { true }

    override init(frame frameRect: NSRect) {
        let scrollView = NSScrollView()
        let textView = NSTextView(frame: .zero)
        guard textView.textLayoutManager != nil else {
            preconditionFailure("CodeTextView requires TextKit 2")
        }

        self.scrollView = scrollView
        self.textView = textView
        super.init(frame: frameRect)

        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.scrollerStyle = .legacy
        scrollView.documentView = textView

        textView.drawsBackground = false
        textView.isEditable = false
        textView.isSelectable = true
        textView.isRichText = false
        textView.usesInspectorBar = false
        textView.usesRuler = false
        textView.isVerticallyResizable = true
        textView.maxSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )

        addSubview(gutterView)
        addSubview(scrollView)

        scrollView.contentView.postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clipViewBoundsDidChange),
            name: NSView.boundsDidChangeNotification,
            object: scrollView.contentView
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func layout() {
        super.layout()

        let frames = CodeGutterMetrics.frames(
            in: bounds,
            gutterWidth: gutterView.requiredWidth
        )
        gutterView.frame = frames.gutter
        scrollView.frame = frames.text
        synchronizeToolbarInset()
        if needsInitialScrollPosition, window != nil {
            needsInitialScrollPosition = false
            scrollView.contentView.scroll(
                to: MacCodeScrollPosition.leadingOrigin(
                    contentInsets: scrollView.contentInsets
                )
            )
            scrollView.reflectScrolledClipView(scrollView.contentView)
        }
        scheduleGutterUpdate()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        needsLayout = true
        layoutSubtreeIfNeeded()
    }

    func update(_ request: CodeTextRenderRequest) {
        updateLineWrapping(request.lineWrapping)

        guard let update = documentState.prepareUpdate(for: request) else {
            scheduleGutterUpdate()
            return
        }

        let visibleOrigin = scrollView.contentView.bounds.origin
        let selectedRanges = textView.selectedRanges

        textView.textStorage?.setAttributedString(update.attributedText)
        gutterView.updateMetrics(
            lineCount: update.lineCount,
            font: update.font
        )

        if !update.change.isNewDocument {
            textView.selectedRanges = selectedRanges
        } else {
            needsInitialScrollPosition = true
            needsLayout = true
        }

        layoutSubtreeIfNeeded()
        let destination = update.change.isNewDocument
            ? MacCodeScrollPosition.leadingOrigin(
                contentInsets: scrollView.contentInsets
            )
            : visibleOrigin
        scrollView.contentView.scroll(to: destination)
        scrollView.reflectScrolledClipView(scrollView.contentView)
        scheduleGutterUpdate()
    }

    private func synchronizeToolbarInset() {
        guard let window else { return }

        let frameInWindow = convert(bounds, to: nil)
        let topInset = max(
            0,
            frameInWindow.maxY - window.contentLayoutRect.maxY
        )
        guard abs(scrollView.contentInsets.top - topInset) > 0.5 else { return }

        scrollView.automaticallyAdjustsContentInsets = false
        scrollView.contentInsets.top = topInset
    }

    private func updateLineWrapping(_ lineWrapping: CodeLineWrapping) {
        guard self.lineWrapping != lineWrapping,
              let textContainer = textView.textContainer
        else { return }

        self.lineWrapping = lineWrapping
        textContainer.lineBreakMode = .byWordWrapping

        switch lineWrapping {
        case .none:
            textView.isHorizontallyResizable = true
            textView.autoresizingMask.remove(.width)
            textContainer.widthTracksTextView = false
            textContainer.size = NSSize(
                width: CGFloat.greatestFiniteMagnitude,
                height: CGFloat.greatestFiniteMagnitude
            )
        case .word:
            textView.isHorizontallyResizable = false
            textView.autoresizingMask.insert(.width)
            textContainer.widthTracksTextView = true
        }

        textView.needsLayout = true
    }

    @objc private func clipViewBoundsDidChange() {
        scheduleGutterUpdate()
    }

    private func scheduleGutterUpdate() {
        gutterUpdates.schedule { [weak self] in
            self?.updateGutter()
        }
    }

    private func updateGutter() {
        gutterUpdates.perform { [self] in
            guard let textLayoutManager = textView.textLayoutManager else { return }

            textLayoutManager.textViewportLayoutController.layoutViewport()
            gutterView.updateMarkers(
                CodeLineLayout.visibleMarkers(
                    textLayoutManager: textLayoutManager,
                    visibleBounds: scrollView.contentView.bounds,
                    textContainerTopInset: textView.textContainerInset.height,
                    lineIndex: documentState.lineIndex
                )
            )
        }
    }
}

@MainActor
private final class MacCodeGutterView: NSView {
    private var renderer = CodeGutterRenderer(
        font: CodeTextStyle.font(ofSize: NSFont.smallSystemFontSize)
    )

    override var isFlipped: Bool { true }

    var requiredWidth: CGFloat {
        renderer.requiredWidth
    }

    func updateMetrics(lineCount: Int, font: NSFont) {
        if renderer.updateMetrics(lineCount: lineCount, font: font) {
            superview?.needsLayout = true
        }
        needsDisplay = true
    }

    func updateMarkers(_ markers: [CodeLineMarker]) {
        guard renderer.updateMarkers(markers) else { return }
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        renderer.draw(in: bounds, color: .secondaryLabelColor)
    }
}

#else

private struct PlatformCodeTextView: UIViewRepresentable {
    static let defaultFontSize = UIFont.preferredFont(forTextStyle: .footnote).pointSize

    let request: CodeTextRenderRequest

    func makeUIView(context: Context) -> MobileCodeTextContainer {
        MobileCodeTextContainer()
    }

    func updateUIView(_ container: MobileCodeTextContainer, context: Context) {
        container.update(request)
    }
}

@MainActor
private final class MobileCodeTextContainer: UIView, UITextViewDelegate {
    private let gutterView = MobileCodeGutterView()
    private let textView = UITextView(usingTextLayoutManager: true)
    private var documentState = CodeTextDocumentState()
    private let gutterUpdates = CodeGutterUpdateCoordinator()
    private var layoutPrewarmingTask: Task<Void, Never>?
    private var prewarmedContent: AttributedString?
    private var lineWrapping: CodeLineWrapping?

    override init(frame: CGRect) {
        super.init(frame: frame)

        textView.backgroundColor = .clear
        textView.isEditable = false
        textView.isSelectable = true
        textView.allowsEditingTextAttributes = false
        textView.isScrollEnabled = true
        let layoutQueue = OperationQueue()
        layoutQueue.name = "CodeTextView.TextLayout"
        layoutQueue.maxConcurrentOperationCount = 1
        layoutQueue.qualityOfService = .utility
        textView.textLayoutManager?.layoutQueue = layoutQueue
        textView.delegate = self

        addSubview(gutterView)
        addSubview(textView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let frames = CodeGutterMetrics.frames(
            in: bounds,
            gutterWidth: gutterView.requiredWidth
        )
        gutterView.frame = frames.gutter
        textView.frame = frames.text
        scheduleGutterUpdate()
    }

    func update(_ request: CodeTextRenderRequest) {
        updateLineWrapping(request.lineWrapping)

        let fontSizeChanged = documentState.fontSize != request.fontSize
        let needsLayoutPrewarming = request.prewarmsLayout
            && (prewarmedContent != request.text || fontSizeChanged)
        guard let update = documentState.prepareUpdate(for: request) else {
            if needsLayoutPrewarming {
                scheduleLayoutPrewarming(
                    for: request.text,
                    fontSize: request.fontSize
                )
            }
            scheduleGutterUpdate()
            return
        }

        layoutPrewarmingTask?.cancel()
        prewarmedContent = nil
        let contentOffset = textView.contentOffset
        let selectedRange = textView.selectedRange

        textView.textStorage.setAttributedString(update.attributedText)
        gutterView.updateMetrics(
            lineCount: update.lineCount,
            font: update.font
        )

        if !update.change.isNewDocument {
            textView.selectedRange = selectedRange
        }

        layoutIfNeeded()
        textView.setContentOffset(
            update.change.isNewDocument ? .zero : contentOffset,
            animated: false
        )
        scheduleGutterUpdate()
        if request.prewarmsLayout {
            scheduleLayoutPrewarming(
                for: request.text,
                fontSize: request.fontSize
            )
        }
    }

    private func updateLineWrapping(_ lineWrapping: CodeLineWrapping) {
        guard self.lineWrapping != lineWrapping else { return }

        self.lineWrapping = lineWrapping
        textView.textContainer.lineBreakMode = .byWordWrapping
        textView.textContainer.widthTracksTextView = lineWrapping == .word

        if lineWrapping == .none {
            textView.textContainer.size = CGSize(
                width: CGFloat.greatestFiniteMagnitude,
                height: CGFloat.greatestFiniteMagnitude
            )
        }

        textView.setNeedsLayout()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scheduleGutterUpdate()
    }

    private func scheduleGutterUpdate() {
        gutterUpdates.schedule { [weak self] in
            self?.updateGutter()
        }
    }

    private func updateGutter() {
        gutterUpdates.perform { [self] in
            guard let textLayoutManager = textView.textLayoutManager else { return }

            textLayoutManager.textViewportLayoutController.layoutViewport()
            gutterView.updateMarkers(
                CodeLineLayout.visibleMarkers(
                    textLayoutManager: textLayoutManager,
                    visibleBounds: textView.bounds,
                    textContainerTopInset: textView.textContainerInset.top,
                    lineIndex: documentState.lineIndex
                )
            )
        }
    }

    private func scheduleLayoutPrewarming(
        for text: AttributedString,
        fontSize: CGFloat
    ) {
        guard prewarmedContent != text else { return }

        layoutPrewarmingTask?.cancel()
        prewarmedContent = text
        layoutPrewarmingTask = Task { @MainActor [weak self] in
            await Task.yield()
            guard let self, !Task.isCancelled else { return }
            await prewarmTextLayout(fontSize: fontSize)
        }
    }

    private func prewarmTextLayout(fontSize: CGFloat) async {
        guard let textLayoutManager = textView.textLayoutManager else { return }

        let font = CodeTextStyle.font(ofSize: fontSize)
        let viewportHeight = max(textView.bounds.height, font.lineHeight)
        let estimatedDocumentHeight = CGFloat(documentState.lineIndex.count) * font.lineHeight
        let documentHeight = max(textView.contentSize.height, estimatedDocumentHeight)
        let chunkHeight = viewportHeight * 2
        var verticalPosition: CGFloat = 0

        while verticalPosition < documentHeight, !Task.isCancelled {
            textLayoutManager.ensureLayout(
                for: CGRect(
                    x: 0,
                    y: verticalPosition,
                    width: max(1, textView.bounds.width),
                    height: min(chunkHeight, documentHeight - verticalPosition)
                )
            )
            verticalPosition += chunkHeight
            await Task.yield()
        }
    }

}

@MainActor
private final class MobileCodeGutterView: UIView {
    private var renderer = CodeGutterRenderer(
        font: CodeTextStyle.font(
            ofSize: UIFont.preferredFont(forTextStyle: .footnote).pointSize
        )
    )

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        isOpaque = false
        backgroundColor = .clear
        clearsContextBeforeDrawing = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var requiredWidth: CGFloat {
        renderer.requiredWidth
    }

    func updateMetrics(lineCount: Int, font: UIFont) {
        if renderer.updateMetrics(lineCount: lineCount, font: font) {
            superview?.setNeedsLayout()
        }
        setNeedsDisplay()
    }

    func updateMarkers(_ markers: [CodeLineMarker]) {
        guard renderer.updateMarkers(markers) else { return }
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        UIGraphicsGetCurrentContext()?.clear(bounds)
        renderer.draw(in: bounds, color: .secondaryLabel)
    }
}
#endif

private struct CodeLineMarker: Equatable {
    let number: Int
    let verticalPosition: CGFloat
}

struct CodeLineIndex {
    private let starts: [Int]

    init(text: String) {
        let text = text as NSString
        var starts = [0]
        starts.reserveCapacity(max(1, text.length / 32))

        for offset in 0..<text.length where text.character(at: offset) == 0x0A {
            starts.append(offset + 1)
        }
        self.starts = starts
    }

    var count: Int { starts.count }

    func lineNumber(containing offset: Int) -> Int {
        var lowerBound = 0
        var upperBound = starts.count

        while lowerBound < upperBound {
            let middle = lowerBound + (upperBound - lowerBound) / 2
            if starts[middle] <= offset {
                lowerBound = middle + 1
            } else {
                upperBound = middle
            }
        }
        return max(1, lowerBound)
    }
}

@MainActor
private enum CodeLineLayout {
    static func visibleMarkers(
        textLayoutManager: NSTextLayoutManager,
        visibleBounds: CGRect,
        textContainerTopInset: CGFloat,
        lineIndex: CodeLineIndex
    ) -> [CodeLineMarker] {
        guard let contentManager = textLayoutManager.textContentManager else {
            return []
        }

        if textLayoutManager.documentRange.isEmpty {
            return [CodeLineMarker(number: 1, verticalPosition: textContainerTopInset)]
        }

        let layoutBounds = CGRect(
            x: 0,
            y: max(0, visibleBounds.minY - textContainerTopInset),
            width: max(1, visibleBounds.width),
            height: visibleBounds.height + textContainerTopInset
        )
        textLayoutManager.ensureLayout(for: layoutBounds)

        let startFragment = textLayoutManager.textLayoutFragment(
            for: CGPoint(x: layoutBounds.minX, y: layoutBounds.minY)
        )
        let startLocation = startFragment?.rangeInElement.location
        let documentEndOffset = contentManager.offset(
            from: contentManager.documentRange.location,
            to: contentManager.documentRange.endLocation
        )

        var markers: [CodeLineMarker] = []
        textLayoutManager.enumerateTextLayoutFragments(
            from: startLocation,
            options: [.ensuresLayout, .ensuresExtraLineFragment]
        ) { fragment in
            let fragmentFrame = fragment.layoutFragmentFrame
            if fragmentFrame.minY > layoutBounds.maxY {
                return false
            }
            guard fragmentFrame.maxY >= layoutBounds.minY,
                  let firstLineFragment = fragment.textLineFragments.first
            else {
                return true
            }

            appendMarker(
                for: firstLineFragment,
                in: fragment,
                fragmentFrame: fragmentFrame,
                contentManager: contentManager,
                documentEndOffset: documentEndOffset,
                visibleBounds: visibleBounds,
                textContainerTopInset: textContainerTopInset,
                lineIndex: lineIndex,
                to: &markers
            )

            for lineFragment in fragment.textLineFragments.dropFirst()
            where lineFragment.characterRange.length == 0 {
                appendMarker(
                    for: lineFragment,
                    in: fragment,
                    fragmentFrame: fragmentFrame,
                    contentManager: contentManager,
                    documentEndOffset: documentEndOffset,
                    visibleBounds: visibleBounds,
                    textContainerTopInset: textContainerTopInset,
                    lineIndex: lineIndex,
                    to: &markers
                )
            }
            return true
        }

        return markers
    }

    private static func appendMarker(
        for lineFragment: NSTextLineFragment,
        in layoutFragment: NSTextLayoutFragment,
        fragmentFrame: CGRect,
        contentManager: NSTextContentManager,
        documentEndOffset: Int,
        visibleBounds: CGRect,
        textContainerTopInset: CGFloat,
        lineIndex: CodeLineIndex,
        to markers: inout [CodeLineMarker]
    ) {
        let fragmentOffset = contentManager.offset(
            from: contentManager.documentRange.location,
            to: layoutFragment.rangeInElement.location
        )
        let lineOffset = lineFragment.characterRange.length == 0
            ? documentEndOffset
            : fragmentOffset + lineFragment.characterRange.location
        let verticalPosition = textContainerTopInset
            + fragmentFrame.minY
            + lineFragment.typographicBounds.minY
            - visibleBounds.minY

        guard verticalPosition >= -lineFragment.typographicBounds.height,
              verticalPosition <= visibleBounds.height
        else { return }

        markers.append(
            CodeLineMarker(
                number: lineIndex.lineNumber(containing: lineOffset),
                verticalPosition: verticalPosition
            )
        )
    }
}
