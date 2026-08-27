# Changelog

All notable changes to CodeViewerKit are documented in this file.

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
