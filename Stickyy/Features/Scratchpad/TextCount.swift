import Foundation

enum TextCount {
    static func value(for text: String, mode: TextCountMode) -> Int {
        switch mode {
        case .words:
            var count = 0
            text.enumerateSubstrings(
                in: text.startIndex..<text.endIndex,
                options: [.byWords, .localized]
            ) { _, _, _, _ in
                count += 1
            }
            return count
        case .characters:
            return text.count
        }
    }

    static func label(for text: String, mode: TextCountMode) -> String {
        let count = value(for: text, mode: mode)
        switch mode {
        case .words:
            return count == 1 ? "1 word" : "\(count) words"
        case .characters:
            return count == 1 ? "1 character" : "\(count) characters"
        }
    }
}
