# Contributing

Contributions and focused bug reports are welcome.

## Development requirements

- Xcode 16 or newer
- Swift 6 or newer
- macOS 15 SDK and iOS 18 SDK or newer

## Validation

Run the package tests on macOS:

```sh
swift test
```

Compile the package for iOS Simulator:

```sh
xcodebuild \
  -scheme CodeViewerKit \
  -configuration Release \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

Keep platform-specific AppKit and UIKit behavior inside their adapters. Shared
document state, gutter geometry, line indexing, and rendering decisions should
remain in the common core whenever the platform APIs permit it.

Please include tests for shared logic changes and describe any platform bug or
workaround that requires native branching.
