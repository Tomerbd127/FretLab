/// A chromatic alteration applied to a note letter, measured in semitones
/// (−1 = flat, +1 = sharp, ±2 = double). Any offset is representable so that
/// transposition never fails, but real music stays within ±2.
nonisolated struct Accidental: Hashable, Comparable, Sendable {
    let offset: Int

    init(offset: Int) {
        self.offset = offset
    }

    static let doubleFlat = Accidental(offset: -2)
    static let flat = Accidental(offset: -1)
    static let natural = Accidental(offset: 0)
    static let sharp = Accidental(offset: 1)
    static let doubleSharp = Accidental(offset: 2)

    /// ASCII spelling: "", "#", "##", "b", "bb".
    var symbol: String {
        offset >= 0
            ? String(repeating: "#", count: offset)
            : String(repeating: "b", count: -offset)
    }

    /// Typographic spelling: "", "♯", "𝄪", "♭", "𝄫" (higher offsets repeat).
    var unicodeSymbol: String {
        let doubles = abs(offset) / 2
        let single = abs(offset) % 2
        if offset >= 0 {
            return String(repeating: "𝄪", count: doubles) + String(repeating: "♯", count: single)
        } else {
            return String(repeating: "𝄫", count: doubles) + String(repeating: "♭", count: single)
        }
    }

    /// Parses accidental text such as "#", "bb", "x", "♭", "𝄪" or "♮". Empty text is natural.
    init?(_ text: Substring) {
        var total = 0
        for character in text {
            switch character {
            case "#", "♯": total += 1
            case "b", "♭": total -= 1
            case "x", "𝄪": total += 2
            case "𝄫": total -= 2
            case "♮": break
            default: return nil
            }
        }
        self.init(offset: total)
    }

    static func < (lhs: Accidental, rhs: Accidental) -> Bool {
        lhs.offset < rhs.offset
    }
}
