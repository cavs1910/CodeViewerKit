# CodeViewerKit

[![CI](https://github.com/cavs1910/CodeViewerKit/actions/workflows/ci.yml/badge.svg)](https://github.com/cavs1910/CodeViewerKit/actions/workflows/ci.yml)
[![Swift 6](https://img.shields.io/badge/Swift-6-orange.svg)](https://swift.org)
[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)

CodeViewerKit is a minimal, read-only source-code viewer for SwiftUI on iOS,
iPadOS, and macOS. It uses TextKit 2 for native selection, scrolling, and
viewport-based layout instead of rendering a complete document as one SwiftUI
`Text` value.

## Features

- native Tree-sitter highlighting for every supported language;
- appearance-aware plain text while highlighting is prepared;
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
        from: "0.4.0"
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

### Languages

Swift is the default. Pass an explicit supported Tree-sitter language in
quotes, or use `.automatic` without quotes to detect a language from the
source contents:

```swift
CodeViewer(
    documentID: "script",
    sourceCode: pythonSource,
    highlightStore: highlights,
    language: "python"
)

CodeViewer(
    documentID: "detected-source",
    sourceCode: unknownSource,
    highlightStore: highlights,
    language: .automatic
)

CodeViewer(
    documentID: "shell-script",
    sourceCode: shellSource,
    highlightStore: highlights,
    language: "shell"
)
```

Supported language identifiers include `"swift"`, `"python"`, `"javascript"`,
`"typescript"`, `"json"`, `"html"`, `"css"`, `"bash"`, `"c"`, `"cpp"`,
`"csharp"`, `"objectivec"`, `"java"`, `"kotlin"`, `"go"`, `"rust"`,
`"ruby"`, `"php"`, `"shell"`, `"sql"`, `"markdown"`, and `"yaml"`.
Common aliases such as `"js"`, `"ts"`, `"py"`, `"rb"`, `"sh"`, and `"yml"`
are also accepted. Unknown identifiers render as plain text without loading a
second highlighting engine.

Prefer an explicit language when it is known. Automatic detection performs
additional work and can be ambiguous for short snippets.

### Line wrapping

Long lines use horizontal scrolling by default. Pass `lineWrapping: .word` to
wrap them at word boundaries instead:

```swift
CodeViewer(
    documentID: "wrapped-example",
    sourceCode: source,
    highlightStore: highlights,
    lineWrapping: .word
)
```

On macOS, each legacy scrollbar is hidden automatically when the content fits
along its axis.

The viewer is visually neutral: apply your own frame, material, or Liquid Glass
container around it. Source ranges without a syntax color use black in light
mode and white in dark mode; override that fallback with `plainTextColor`:

```swift
CodeViewer(
    documentID: "example",
    sourceCode: source,
    highlightStore: highlights,
    plainTextColor: .secondary
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

CodeViewerKit is intentionally read-only. Editing, language-server integration,
diagnostics, minimaps, and dynamically installed grammars are outside its
current scope.

## Architecture

The shared renderer core owns document updates, Menlo styling, logical line
indexing, gutter geometry, visible marker resolution, and coalesced redraws.
Small AppKit and UIKit adapters configure the native TextKit 2 views and handle
the platform-specific selection and scrolling behavior.

Highlighting is provided by
[Tree-sitter](https://github.com/tree-sitter/tree-sitter) through
[SwiftTreeSitter](https://github.com/tree-sitter/swift-tree-sitter) and the
offline grammars in
[TreeSitterLanguages](https://github.com/simonbs/TreeSitterLanguages). The
complete document is parsed away from the main actor and token colors are
applied directly to the native attributed string without JavaScript or HTML
conversion. Results are cached by document, contents, language, and appearance.
Kotlin uses the Java grammar and Objective-C uses the C grammar as lightweight
Tree-sitter approximations.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the local build and validation flow.

## License

CodeViewerKit is available under the Apache License 2.0. Dependency licenses
are listed in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
