import Foundation

enum MorseSymbol: Equatable {
    case dot
    case dash
    case letterGap
    case wordGap
}

struct TorchSegment: Equatable {
    let isOn: Bool
    let durationMs: Int
}

enum MorseCodec {
    private static let table: [Character: String] = [
        "A": ".-", "B": "-...", "C": "-.-.", "D": "-..", "E": ".", "F": "..-.",
        "G": "--.", "H": "....", "I": "..", "J": ".---", "K": "-.-", "L": ".-..",
        "M": "--", "N": "-.", "O": "---", "P": ".--.", "Q": "--.-", "R": ".-.",
        "S": "...", "T": "-", "U": "..-", "V": "...-", "W": ".--", "X": "-..-",
        "Y": "-.--", "Z": "--..",
        "0": "-----", "1": ".----", "2": "..---", "3": "...--", "4": "....-",
        "5": ".....", "6": "-....", "7": "--...", "8": "---..", "9": "----."
    ]

    private static let reverseTable: [String: Character] = {
        Dictionary(uniqueKeysWithValues: table.map { ($1, $0) })
    }()

    static let maxMessageLength = 40

    static func sanitizeInput(_ text: String) -> String {
        let uppercased = text.uppercased()
        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 ")
        let filtered = uppercased.unicodeScalars.filter { allowed.contains($0) }
        return String(String.UnicodeScalarView(filtered)).prefix(maxMessageLength).description
    }

    static func encodePattern(_ text: String) -> String {
        let sanitized = sanitizeInput(text)
        var parts: [String] = []
        var isStartOfWord = true

        for character in sanitized {
            if character == " " {
                isStartOfWord = true
                continue
            }

            guard let pattern = table[character] else { continue }

            if !isStartOfWord {
                parts.append("/")
            }
            parts.append(pattern)
            isStartOfWord = false
        }

        return parts.joined(separator: " ")
    }

    static func encodeSymbols(_ text: String) -> [MorseSymbol] {
        let sanitized = sanitizeInput(text)
        var symbols: [MorseSymbol] = []
        let words = sanitized.split(separator: " ", omittingEmptySubsequences: false)

        for (wordIndex, word) in words.enumerated() {
            for (characterIndex, character) in word.enumerated() {
                if characterIndex > 0 {
                    symbols.append(.letterGap)
                }

                guard let pattern = table[character] else { continue }

                for element in pattern {
                    switch element {
                    case ".":
                        symbols.append(.dot)
                    case "-":
                        symbols.append(.dash)
                    default:
                        break
                    }
                }
            }

            if wordIndex < words.count - 1 {
                symbols.append(.wordGap)
            }
        }

        return symbols
    }

    static func encodeSegments(_ text: String) -> [TorchSegment] {
        let symbols = encodeSymbols(text)
        var segments: [TorchSegment] = []

        for (index, symbol) in symbols.enumerated() {
            switch symbol {
            case .dot:
                segments.append(TorchSegment(isOn: true, durationMs: MorseTiming.dotDurationMs))
            case .dash:
                segments.append(TorchSegment(isOn: true, durationMs: MorseTiming.dashDurationMs))
            case .letterGap:
                segments.append(TorchSegment(isOn: false, durationMs: MorseTiming.letterGapMs))
            case .wordGap:
                segments.append(TorchSegment(isOn: false, durationMs: MorseTiming.wordGapMs))
            }

            let isLast = index == symbols.count - 1
            if !isLast {
                let next = symbols[index + 1]
                if (symbol == .dot || symbol == .dash),
                   (next == .dot || next == .dash) {
                    segments.append(TorchSegment(isOn: false, durationMs: MorseTiming.elementGapMs))
                }
            }
        }

        return segments
    }

    static func decodeSymbols(_ symbols: [MorseSymbol]) -> String {
        var result = ""
        var currentPattern = ""

        func flushLetter() {
            guard !currentPattern.isEmpty else { return }
            if let character = reverseTable[currentPattern] {
                result.append(character)
            } else {
                result.append("?")
            }
            currentPattern = ""
        }

        for symbol in symbols {
            switch symbol {
            case .dot:
                currentPattern.append(".")
            case .dash:
                currentPattern.append("-")
            case .letterGap:
                flushLetter()
            case .wordGap:
                flushLetter()
                result.append(" ")
            }
        }

        flushLetter()
        return result
    }

    static func decodePattern(_ pattern: String) -> String {
        let words = pattern.split(separator: " ", omittingEmptySubsequences: false)
        var decodedWords: [String] = []

        for word in words {
            let letters = word.split(separator: "/", omittingEmptySubsequences: false)
            let decodedLetters = letters.map { letter -> String in
                reverseTable[String(letter)].map(String.init) ?? "?"
            }
            decodedWords.append(decodedLetters.joined())
        }

        return decodedWords.joined(separator: " ")
    }

    static func classifyOnPulse(durationMs: Int) -> MorseSymbol? {
        guard durationMs > MorseTiming.dotDurationMs / 3 else { return nil }
        return durationMs < MorseTiming.dotPulseMaxMs ? .dot : .dash
    }

    static func classifyOffGap(durationMs: Int) -> MorseSymbol? {
        guard durationMs >= MorseTiming.elementGapMs / 2 else { return nil }
        if durationMs >= MorseTiming.wordGapMinMs {
            return .wordGap
        }
        if durationMs >= MorseTiming.letterGapMinMs {
            return .letterGap
        }
        return nil
    }
}
