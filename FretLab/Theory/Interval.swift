/// A musical interval described by quality and number (M3, P5, d7, …).
///
/// The number fixes how many letters the interval spans; the quality fixes the
/// exact semitone size. Keeping both is what makes correct spelling possible:
/// an augmented 2nd and a minor 3rd are both 3 semitones but land on different letters.
nonisolated struct Interval: Hashable, Sendable {
    enum Quality: Hashable, Sendable, CaseIterable {
        case diminished, minor, perfect, major, augmented

        var abbreviation: String {
            switch self {
            case .diminished: "d"
            case .minor: "m"
            case .perfect: "P"
            case .major: "M"
            case .augmented: "A"
            }
        }

        var name: String {
            switch self {
            case .diminished: "diminished"
            case .minor: "minor"
            case .perfect: "perfect"
            case .major: "major"
            case .augmented: "augmented"
            }
        }
    }

    let quality: Quality
    /// 1 = unison, 2 = second, … 8 = octave, 9 = ninth, …
    let number: Int

    /// Fails for impossible combinations such as a "major fifth" or a "perfect third".
    init?(_ quality: Quality, _ number: Int) {
        guard number >= 1 else { return nil }
        let perfectType = Self.isPerfectType(number)
        switch quality {
        case .perfect: guard perfectType else { return nil }
        case .major, .minor: guard !perfectType else { return nil }
        case .diminished: guard number > 1 else { return nil } // a diminished unison would be negative
        case .augmented: break
        }
        self.quality = quality
        self.number = number
    }

    /// Builds the interval spanning `steps` letters and `semitones` semitones, if one has a standard quality.
    init?(steps: Int, semitones: Int) {
        guard steps >= 0 else { return nil }
        let number = steps + 1
        let difference = semitones - Self.referenceSemitones(steps: steps)
        let quality: Quality
        if Self.isPerfectType(number) {
            switch difference {
            case -1: quality = .diminished
            case 0: quality = .perfect
            case 1: quality = .augmented
            default: return nil
            }
        } else {
            switch difference {
            case -2: quality = .diminished
            case -1: quality = .minor
            case 0: quality = .major
            case 1: quality = .augmented
            default: return nil
            }
        }
        self.init(quality, number)
    }

    /// The interval from `lower` up to `upper`, or nil if `upper` is spelled below `lower`
    /// or the interval has no standard quality (e.g. doubly augmented).
    static func between(_ lower: Note, _ upper: Note) -> Interval? {
        Interval(steps: upper.diatonicIndex - lower.diatonicIndex,
                 semitones: upper.midiNumber - lower.midiNumber)
    }

    /// The ascending interval (within one octave) from one pitch class up to the next occurrence of another.
    static func between(_ lower: PitchClass, _ upper: PitchClass) -> Interval? {
        let lowerNote = Note(lower, octave: 4)
        let upperOctave = upper.letter.rawValue < lower.letter.rawValue ? 5 : 4
        return between(lowerNote, Note(upper, octave: upperOctave))
    }

    /// Letter steps spanned (number − 1).
    var steps: Int { number - 1 }

    var semitones: Int {
        let adjustment: Int = switch quality {
        case .perfect, .major: 0
        case .minor: -1
        case .augmented: 1
        case .diminished: Self.isPerfectType(number) ? -1 : -2
        }
        return Self.referenceSemitones(steps: steps) + adjustment
    }

    var isCompound: Bool { number > 8 }

    /// "M3", "P5", "d7", "A4".
    var shortName: String { quality.abbreviation + String(number) }

    /// Guitarist-style degree relative to the major scale: "1", "b3", "#4", "b5", "bb7", "9".
    var degreeName: String {
        let offset = semitones - Self.referenceSemitones(steps: steps)
        return Accidental(offset: offset).symbol + String(number)
    }

    /// "major third", "perfect fifth".
    var name: String { "\(quality.name) \(Self.ordinal(number))" }

    // MARK: - Helpers

    private static func isPerfectType(_ number: Int) -> Bool {
        [0, 3, 4].contains((number - 1) % 7)
    }

    /// Semitones of the major or perfect interval spanning `steps` letters.
    private static func referenceSemitones(steps: Int) -> Int {
        let simple = [0, 2, 4, 5, 7, 9, 11]
        return simple[steps % 7] + 12 * (steps / 7)
    }

    private static func ordinal(_ number: Int) -> String {
        let names = [
            1: "unison", 2: "second", 3: "third", 4: "fourth", 5: "fifth", 6: "sixth", 7: "seventh",
            8: "octave", 9: "ninth", 10: "tenth", 11: "eleventh", 12: "twelfth", 13: "thirteenth",
            14: "fourteenth", 15: "double octave",
        ]
        return names[number] ?? "\(number)th"
    }
}

nonisolated extension Interval: CustomStringConvertible {
    var description: String { shortName }
}

nonisolated extension Interval {
    static let perfectUnison = Interval(.perfect, 1)!
    static let augmentedUnison = Interval(.augmented, 1)!
    static let minorSecond = Interval(.minor, 2)!
    static let majorSecond = Interval(.major, 2)!
    static let augmentedSecond = Interval(.augmented, 2)!
    static let minorThird = Interval(.minor, 3)!
    static let majorThird = Interval(.major, 3)!
    static let perfectFourth = Interval(.perfect, 4)!
    static let augmentedFourth = Interval(.augmented, 4)!
    static let diminishedFifth = Interval(.diminished, 5)!
    static let perfectFifth = Interval(.perfect, 5)!
    static let augmentedFifth = Interval(.augmented, 5)!
    static let minorSixth = Interval(.minor, 6)!
    static let majorSixth = Interval(.major, 6)!
    static let diminishedSeventh = Interval(.diminished, 7)!
    static let minorSeventh = Interval(.minor, 7)!
    static let majorSeventh = Interval(.major, 7)!
    static let perfectOctave = Interval(.perfect, 8)!
}
