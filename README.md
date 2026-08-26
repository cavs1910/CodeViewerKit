# CodeViewerKit

[![CI](https://github.com/cavs1910/CodeViewerKit/actions/workflows/ci.yml/badge.svg)](https://github.com/cavs1910/CodeViewerKit/actions/workflows/ci.yml)
[![Swift 6](https://img.shields.io/badge/Swift-6-orange.svg)](https://swift.org)
[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)

CodeViewerKit is a minimal, read-only Swift source viewer for SwiftUI on iOS,
iPadOS, and macOS. It uses TextKit 2 for native selection, scrolling, and
viewport-based layout instead of rendering a complete document as one SwiftUI
`Text` value.

## Features

- progressive Swift syntax highlighting with a fast plain-text first frame;
- logical line numbers that stay aligned when a source line wraps;
- Menlo with a monospaced system fallback;
- native selection and horizontal and vertical scrolling;
- Command-Plus and Command-Minus font scaling;
- background layout prewarming on iOS and iPadOS;
- shared highlighting cache for navigation-heavy apps.

## Requirements

- Swift 6.0 or newer
- Xcode 16 or newer
- iOS or iPadOS 18 or newer
- macOS 15 or newer

## Installation

In Xcode, choose **File > Add Package Dependencies** and enter:

```text
https://github.com/cavs1910/CodeViewerKit.git
```

Or add the package to `Package.swift`:

```swift
dependencies: [
    .package(
        url: "https://github.com/cavs1910/CodeViewerKit.git",
        from: "0.1.0"
    )
]
```

Then add `CodeViewerKit` to the dependencies of your app target.

## Usage

Create one `CodeHighlightStore` at a stable ownership boundary. Reusing it lets
prepared documents survive navigation and avoids repeating highlighting work.

```swift
import CodeViewerKit
import SwiftUI

struct ContentView: View {
    @State private var highlights = CodeHighlightStore()

    private let source = """
    import SwiftUI

    struct GreetingView: View {
        var body: some View {
            Text("Hello, world!")
        }
    }
    """

    var body: some View {
        CodeViewer(
            documentID: "greeting-view",
            sourceCode: source,
            highlightStore: highlights
        )
    }
}
```

`documentID` controls native view continuity. Keep it stable while updating the
same document so selection and scroll position are preserved. Change it when
showing a different document so the viewer starts at the beginning.

The viewer is visually neutral: apply your own frame, padding, material, or
Liquid Glass container around it. Indicator insets can be configured without
moving the source text:

```swift
CodeViewer(
    documentID: "example",
    sourceCode: source,
    highlightStore: highlights,
    scrollIndicatorInsets: EdgeInsets(
        top: 8,
        leading: 0,
        bottom: 8,
        trailing: 8
    )
)
```

### Font-size commands

Add `CodeViewerCommands` to the app scene to enable Command-Plus and
Command-Minus for the focused viewer:

```swift
@main
struct ExampleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            CodeViewerCommands()
        }
    }
}
```

## Scope

CodeViewerKit intentionally displays Swift source and is read-only. Editing,
language-server integration, diagnostics, minimaps, and non-Swift grammars are
outside its current scope.

## Architecture

The shared renderer core owns document updates, Menlo styling, logical line
indexing, gutter geometry, visible marker resolution, and coalesced redraws.
Small AppKit and UIKit adapters configure the native TextKit 2 views and handle
the platform-specific selection and scrolling behavior.

Highlighting is provided by
[HighlightSwift](https://github.com/appstefan/HighlightSwift). The first 80
logical lines are highlighted with user-initiated priority; the complete
document finishes at utility priority and is cached by document, contents, and
appearance.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the local build and validation flow.

## License

CodeViewerKit is available under the Apache License 2.0. HighlightSwift is an
MIT-licensed package dependency; see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
