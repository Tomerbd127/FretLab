/// One of the seven natural note letters. Raw values are diatonic indices (C = 0 … B = 6).
nonisolated enum NoteLetter: Int, CaseIterable, Hashable, Sendable {
    case c, d, e, f, g, a, b

    /// Semitones above C of the natural (unaltered) letter.
    var naturalSemitone: Int {
        switch self {
        case .c: 0
        case .d: 2
        case .e: 4
        case .f: 5
        case .g: 7
        case .a: 9
        case .b: 11
        }
    }

    /// The letter `steps` diatonic steps away, wrapping around the octave. Negative steps go down.
    func advanced(by steps: Int) -> NoteLetter {
        NoteLetter(rawValue: Theory.mod(rawValue + steps, 7))!
    }

    var name: String {
        switch self {
        case .c: "C"
        case .d: "D"
        case .e: "E"
        case .f: "F"
        case .g: "G"
        case .a: "A"
        case .b: "B"
        }
    }

    init?(_ character: Character) {
        switch character.uppercased() {
        case "C": self = .c
        case "D": self = .d
        case "E": self = .e
        case "F": self = .f
        case "G": self = .g
        case "A": self = .a
        case "B": self = .b
        default: return nil
        }
    }
}

/// Small integer helpers shared by the theory types.
nonisolated enum Theory {
    /// Mathematical modulo: the result is always in `0..<n`, even for negative `a`.
    static func mod(_ a: Int, _ n: Int) -> Int {
        let r = a % n
        return r < 0 ? r + n : r
    }

    /// Floor division (rounds toward negative infinity).
    static func floorDiv(_ a: Int, _ n: Int) -> Int {
        let q = a / n
        return (a % n != 0 && (a < 0) != (n < 0)) ? q - 1 : q
    }
}
