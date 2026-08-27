# Changelog

All notable changes to CodeViewerKit are documented in this file.

## 0.6.1 - 2026-08-27

- make grammar registration public and remove the fixed language catalog from
  the package, allowing applications to supply any current or future
  Tree-sitter grammar without a CodeViewerKit release;
- require callers to provide the selected `CodeGrammar` values when creating a
  `CodeHighlightStore`;
- use native Tree-sitter parsing and direct attributed-string styling for every
  supported language;
- remove HighlightSwift, its JavaScript runtime, HTML conversion, and the
  progressive two-stage highlighting path;
- add offline language aliases and lightweight automatic detection;

## 0.4.2 - 2026-08-27

- resolve the complete macOS toolbar overlap when the native view joins its
  window, then position a new document before its first visible frame.

## 0.4.1 - 2026-08-27

- account for automatic macOS toolbar content insets when positioning a new
  document at the beginning of its native scroll view.

## 0.3.0 - 2026-08-27

- use native text-container padding and scroll indicators on iOS and iPadOS;
- use the native legacy scroller style on macOS without custom tiling or inset
  adjustments;
- remove the `scrollIndicatorInsets` parameter from `CodeViewer`;

## 0.2.1 - 2026-08-26

- apply the initial plain-text fallback as a native TextKit foreground color
  so dark-mode source is readable before highlighting completes;

## 0.2.0 - 2026-08-26

- support explicit syntax-highlighting languages, automatic detection, and
  custom bundled Highlight.js language identifiers;

## 0.1.1 - 2026-08-26

- use an appearance-aware fallback color before progressive highlighting is
  ready and allow callers to override it with `plainTextColor`;

## 0.1.0 - 2026-08-26

Initial public release:

- read-only Swift source rendering with TextKit 2;
- progressive syntax highlighting and session caching;
- logical line numbers aligned with wrapped source;
- native selection and two-axis scrolling on iOS, iPadOS, and macOS;
- Menlo typography with a monospaced system fallback;
- focused Command-Plus and Command-Minus font scaling;
- iOS and iPadOS layout prewarming for long documents.
