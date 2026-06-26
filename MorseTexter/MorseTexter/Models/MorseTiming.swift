import Foundation

enum MorseTiming {
    static let wordsPerMinute: Double = 12

    static var dotDurationMs: Int {
        Int(1200.0 / wordsPerMinute)
    }

    static var dashDurationMs: Int {
        dotDurationMs * 3
    }

    static var elementGapMs: Int {
        dotDurationMs
    }

    static var letterGapMs: Int {
        dotDurationMs * 3
    }

    static var wordGapMs: Int {
        dotDurationMs * 7
    }

    /// Lower bound for classifying an ON pulse as a dot (ms).
    static var dotPulseMaxMs: Int {
        (dotDurationMs + dashDurationMs) / 2
    }

    /// Lower bound for classifying an OFF gap as a letter boundary (ms).
    static var letterGapMinMs: Int {
        (elementGapMs + letterGapMs) / 2
    }

    /// Lower bound for classifying an OFF gap as a word boundary (ms).
    static var wordGapMinMs: Int {
        (letterGapMs + wordGapMs) / 2
    }
}
