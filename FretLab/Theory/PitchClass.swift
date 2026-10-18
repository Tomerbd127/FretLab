/// A spelled pitch class with no octave, such as Bb or F#.
///
/// Spelling is preserved: Bb and A# are different values that are *enharmonic*
/// (they share a `semitone`).
nonisolated struct PitchClass: Hashable, Sendable {
    let letter: NoteLetter
    let accidental: Accidental

    init(_ letter: NoteLetter, _ accidental: Accidental = .natural) {
        self.letter = letter
        self.accidental = accidental
    }

    /// Parses names such as "C", "Bb", "f#", "Ebb", "Fx", "B♭".
    init?(_ text: String) {
        guard let first = text.first,
              let letter = NoteLetter(first),
              let accidental = Accidental(text.dropFirst())
        else { return nil }
        self.init(letter, accidental)
    }

    /// Semitones above C, in `0..<12`.
    var semitone: Int {
        Theory.mod(letter.naturalSemitone + accidental.offset, 12)
    }

    /// ASCII name, e.g. "Bb", "F#", "C##".
    var name: String { letter.name + accidental.symbol }

    /// Typographic name, e.g. "B♭", "F♯".
    var unicodeName: String { letter.name + accidental.unicodeSymbol }

    /// True when both pitch classes sound the same (Bb and A#), including identical ones.
    func isEnharmonic(with other: PitchClass) -> Bool {
        semitone == other.semitone
    }

    func transposed(by interval: Interval) -> PitchClass {
        Note(self, octave: 4).transposed(by: interval).pitchClass
    }

    func transposed(downBy interval: Interval) -> PitchClass {
        Note(self, octave: 4).transposed(downBy: interval).pitchClass
    }

    /// Position on the line of fifths relative to C (F = −1, G = 1, F# = 6, Bb = −2, …).
    var fifthsFromC: Int {
        // Letters in fifths order F C G D A E B sit at −1 … 5.
        let letterFifths: Int = switch letter {
        case .f: -1
        case .c: 0
        case .g: 1
        case .d: 2
        case .a: 3
        case .e: 4
        case .b: 5
        }
        return letterFifths + 7 * accidental.offset
    }

    /// The pitch class at a given position on the line of fifths (inverse of `fifthsFromC`).
    init(fifthsFromC fifths: Int) {
        let order: [NoteLetter] = [.f, .c, .g, .d, .a, .e, .b]
        self.init(order[Theory.mod(fifths + 1, 7)],
                  Accidental(offset: Theory.floorDiv(fifths + 1, 7)))
    }

    /// The conventional spelling of a semitone (0–11) using sharps or flats.
    init(semitone: Int, preferring spelling: AccidentalPreference = .sharps) {
        let sharps: [(NoteLetter, Accidental)] = [
            (.c, .natural), (.c, .sharp), (.d, .natural), (.d, .sharp), (.e, .natural), (.f, .natural),
            (.f, .sharp), (.g, .natural), (.g, .sharp), (.a, .natural), (.a, .sharp), (.b, .natural),
        ]
        let flats: [(NoteLetter, Accidental)] = [
            (.c, .natural), (.d, .flat), (.d, .natural), (.e, .flat), (.e, .natural), (.f, .natural),
            (.g, .flat), (.g, .natural), (.a, .flat), (.a, .natural), (.b, .flat), (.b, .natural),
        ]
        let (letter, accidental) = (spelling == .sharps ? sharps : flats)[Theory.mod(semitone, 12)]
        self.init(letter, accidental)
    }
}

/// Which accidental to use when spelling a pitch that has no musical context.
nonisolated enum AccidentalPreference: Hashable, Sendable {
    case sharps, flats
}

nonisolated extension PitchClass: CustomStringConvertible {
    var description: String { name }
}

nonisolated extension PitchClass {
    static let c = PitchClass(.c)
    static let d = PitchClass(.d)
    static let e = PitchClass(.e)
    static let f = PitchClass(.f)
    static let g = PitchClass(.g)
    static let a = PitchClass(.a)
    static let b = PitchClass(.b)
}
