import XCTest
@testable import MorseTexter

final class MorseCodecTests: XCTestCase {
    func testSanitizeInputKeepsAllowedCharacters() {
        XCTAssertEqual(MorseCodec.sanitizeInput("Hi 123!"), "HI 123")
    }

    func testSanitizeInputEnforcesLengthLimit() {
        let long = String(repeating: "A", count: 50)
        XCTAssertEqual(MorseCodec.sanitizeInput(long).count, MorseCodec.maxMessageLength)
    }

    func testEncodePatternSOS() {
        XCTAssertEqual(MorseCodec.encodePattern("SOS"), "... --- ...")
    }

    func testEncodePatternHelloWorld() {
        XCTAssertEqual(
            MorseCodec.encodePattern("HELLO WORLD"),
            ".... . .-.. .-.. --- / .-- --- .-. .-.. -.."
        )
    }

    func testEncodePatternDigits() {
        XCTAssertEqual(MorseCodec.encodePattern("123"), ".---- ..--- ...--")
    }

    func testDecodePatternSOS() {
        XCTAssertEqual(MorseCodec.decodePattern("... --- ..."), "SOS")
    }

    func testDecodePatternHelloWorld() {
        XCTAssertEqual(
            MorseCodec.decodePattern(".... . .-.. .-.. --- / .-- --- .-. .-.. -.."),
            "HELLO WORLD"
        )
    }

    func testRoundTripHI() {
        let encoded = MorseCodec.encodePattern("HI")
        XCTAssertEqual(MorseCodec.decodePattern(encoded), "HI")
    }

    func testRoundTripTest123() {
        let encoded = MorseCodec.encodePattern("TEST 123")
        XCTAssertEqual(MorseCodec.decodePattern(encoded), "TEST 123")
    }

    func testDecodeSymbolsFromPulseSequence() {
        let symbols: [MorseSymbol] = [.dot, .dot, .dot, .letterGap, .dash, .dash, .dash, .letterGap, .dot, .dot, .dot]
        XCTAssertEqual(MorseCodec.decodeSymbols(symbols), "SOS")
    }

    func testClassifyOnPulse() {
        XCTAssertEqual(MorseCodec.classifyOnPulse(durationMs: MorseTiming.dotDurationMs), .dot)
        XCTAssertEqual(MorseCodec.classifyOnPulse(durationMs: MorseTiming.dashDurationMs), .dash)
    }

    func testClassifyOffGap() {
        XCTAssertNil(MorseCodec.classifyOffGap(durationMs: 20))
        XCTAssertEqual(MorseCodec.classifyOffGap(durationMs: MorseTiming.letterGapMs), .letterGap)
        XCTAssertEqual(MorseCodec.classifyOffGap(durationMs: MorseTiming.wordGapMs), .wordGap)
    }

    func testEncodeSegmentsStartsWithOnPulse() {
        let segments = MorseCodec.encodeSegments("E")
        XCTAssertEqual(segments.first?.isOn, true)
        XCTAssertEqual(segments.first?.durationMs, MorseTiming.dotDurationMs)
    }
}
