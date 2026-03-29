//
//  WeightFormattingTests.swift
//  personal-gym-appTests
//

import Testing
import Foundation
@testable import personal_gym_app

@Suite("Weight formatting")
struct WeightFormattingTests {

    // MARK: - formatKg

    @Test("formatKg shows integer for whole numbers")
    func formatKgWhole() {
        #expect(formatKg(60.0) == "60 kg")
        #expect(formatKg(100.0) == "100 kg")
        #expect(formatKg(0.0) == "0 kg")
    }

    @Test("formatKg shows one decimal for fractional weights")
    func formatKgFractional() {
        #expect(formatKg(22.5) == "22.5 kg")
        #expect(formatKg(1.3) == "1.3 kg")
    }

    // MARK: - parseWeight

    @Test("parseWeight parses dot decimal")
    func parseWeightDot() {
        #expect(parseWeight("22.5") == 22.5)
    }

    @Test("parseWeight parses comma decimal")
    func parseWeightComma() {
        #expect(parseWeight("22,5") == 22.5)
    }

    @Test("parseWeight parses whole number")
    func parseWeightWhole() {
        #expect(parseWeight("60") == 60.0)
    }

    @Test("parseWeight returns nil for empty string")
    func parseWeightEmpty() {
        #expect(parseWeight("") == nil)
    }

    @Test("parseWeight returns nil for non-numeric input")
    func parseWeightInvalid() {
        #expect(parseWeight("abc") == nil)
    }

    @Test("parseWeight handles whitespace")
    func parseWeightWhitespace() {
        #expect(parseWeight("  60  ") == 60.0)
        #expect(parseWeight("  ") == nil)
    }
}
