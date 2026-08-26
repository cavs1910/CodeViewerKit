import Foundation

enum ProgressiveCodeHighlight {
    private static let leadingLineCount = 80

    static func splitLeadingLines(_ sourceCode: String) -> (String, String) {
        var lineCount = 1
        var endIndex = sourceCode.startIndex

        while endIndex < sourceCode.endIndex {
            if sourceCode[endIndex] == "\n" {
                if lineCount == leadingLineCount {
                    let nextIndex = sourceCode.index(after: endIndex)
                    return (
                        String(sourceCode[..<nextIndex]),
                        String(sourceCode[nextIndex...])
                    )
                }
                lineCount += 1
            }
            sourceCode.formIndex(after: &endIndex)
        }

        return (sourceCode, "")
    }
}
