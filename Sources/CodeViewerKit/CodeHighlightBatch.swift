import Foundation

enum CodeHighlightAppearance: Hashable, Sendable {
    case light
    case dark
}

enum CodeHighlightToken: Hashable, Sendable {
    case attribute
    case literal
    case comment
    case callable
    case keyword
    case string
    case type
    case builtinVariable

    init?(nameComponents: [String]) {
        guard let category = nameComponents.first else { return nil }

        switch category {
        case "attribute", "property":
            self = .attribute
        case "boolean", "character", "constant", "number":
            self = .literal
        case "comment":
            self = .comment
        case "constructor", "function", "method":
            self = .callable
        case "keyword", "label", "operator", "punctuation", "tag", "text":
            self = .keyword
        case "string":
            self = .string
        case "type":
            self = .type
        case "variable" where nameComponents.contains("builtin"):
            self = .builtinVariable
        default:
            return nil
        }
    }

    func colorValue(for appearance: CodeHighlightAppearance) -> UInt32 {
        switch self {
        case .attribute:
            appearance == .dark ? 0xD0A8_FF : 0x9C2F_AE
        case .literal:
            appearance == .dark ? 0xD0BF_69 : 0x272A_D8
        case .comment:
            appearance == .dark ? 0x7F8C_98 : 0x5D6C_79
        case .callable:
            appearance == .dark ? 0x67B7_A4 : 0x326D_74
        case .keyword:
            appearance == .dark ? 0xFF7A_B2 : 0xAD3D_A4
        case .string:
            appearance == .dark ? 0xFC6A_5D : 0xD12F_1B
        case .type, .builtinVariable:
            appearance == .dark ? 0xDABA_FF : 0x703D_AA
        }
    }
}

struct CodeHighlightSpan: Equatable, Sendable {
    let range: NSRange
    let token: CodeHighlightToken
}

struct CodeHighlightBatch: Equatable, Sendable {
    let sequence: Int
    let coveredRange: NSRange
    let spans: [CodeHighlightSpan]
}

struct CodeHighlightSnapshot: Equatable {
    let batches: [CodeHighlightBatch]
    let isPrepared: Bool
}

enum CodeHighlightChunker {
    static let defaultTargetUTF16Length = 128 * 1024

    static func ranges(
        in sourceCode: String,
        targetUTF16Length: Int = defaultTargetUTF16Length
    ) -> [NSRange] {
        precondition(targetUTF16Length > 0)

        let source = sourceCode as NSString
        guard source.length > 0 else { return [] }

        var ranges: [NSRange] = []
        var location = 0

        while location < source.length {
            let proposedEnd = min(location + targetUTF16Length, source.length)
            var end = proposedEnd

            if proposedEnd < source.length {
                let searchLength = min(
                    max(1, targetUTF16Length / 8),
                    source.length - proposedEnd
                )
                let newline = source.range(
                    of: "\n",
                    range: NSRange(location: proposedEnd, length: searchLength)
                )
                if newline.location != NSNotFound {
                    end = NSMaxRange(newline)
                }
            }

            ranges.append(NSRange(location: location, length: end - location))
            location = end
        }

        return ranges
    }
}
