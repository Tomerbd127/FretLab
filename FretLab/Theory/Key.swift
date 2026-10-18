/// A major or minor key, limited to the 15 standard spellings of each (at most 7 sharps or flats).
nonisolated struct Key: Hashable, Sendable {
    enum Mode: Hashable, Sendable, CaseIterable {
        case major, minor

        var name: String {
            switch self {
            case .major: "major"
            case .minor: "minor"
            }
        }

        /// Offset from a major key's tonic position on the circle of fifths.
        fileprivate var fifthsOffset: Int {
            switch self {
            case .major: 0
            case .minor: -3 // A minor shares C major's signature; A is 3 fifths above C.
            }
        }
    }

    let tonic: PitchClass
    let mode: Mode

    /// Fails for theoretical keys that would need more than 7 sharps or flats (e.g. G# major, Fb major).
    init?(_ tonic: PitchClass, _ mode: Mode) {
        guard abs(tonic.fifthsFromC + mode.fifthsOffset) <= 7 else { return nil }
        self.tonic = tonic
        self.mode = mode
    }

    /// The key with the given signature: positive = sharps, negative = flats, in `-7...7`.
    init?(fifths: Int, mode: Mode) {
        guard abs(fifths) <= 7 else { return nil }
        self.tonic = PitchClass(fifthsFromC: fifths - mode.fifthsOffset)
        self.mode = mode
    }

    /// Like `init(fifths:mode:)` but folds out-of-range positions onto their enharmonic key
    /// (8 sharps → 4 flats), so moving around the circle never falls off the edge.
    private init(wrappingFifths fifths: Int, mode: Mode) {
        var folded = fifths
        while folded > 7 { folded -= 12 }
        while folded < -7 { folded += 12 }
        self.init(fifths: folded, mode: mode)!
    }

    /// Number of sharps (positive) or flats (negative) in the key signature.
    var fifths: Int { tonic.fifthsFromC + mode.fifthsOffset }

    var signature: KeySignature { KeySignature(fifths: fifths) }

    /// "Bb major", "F# minor".
    var name: String { "\(tonic.name) \(mode.name)" }

    /// Major or natural minor scale of the key.
    var scale: Scale {
        Scale(root: tonic, type: mode == .major ? .major : .naturalMinor)
    }

    /// The key sharing this signature in the other mode (C major ↔ A minor).
    var relative: Key {
        Key(fifths: fifths, mode: mode == .major ? .minor : .major)!
    }

    /// The key on the same tonic in the other mode (C major ↔ C minor).
    /// Respelled enharmonically when the literal one is theoretical (C# minor → Db major).
    var parallel: Key {
        let other: Mode = mode == .major ? .minor : .major
        return Key(tonic, other) ?? Key(wrappingFifths: fifths - mode.fifthsOffset + other.fifthsOffset, mode: other)
    }

    /// One step clockwise on the circle (one more sharp / one fewer flat).
    var dominant: Key { Key(wrappingFifths: fifths + 1, mode: mode) }

    /// One step counter-clockwise on the circle (one more flat / one fewer sharp).
    var subdominant: Key { Key(wrappingFifths: fifths - 1, mode: mode) }

    /// The two adjacent keys on the circle of fifths, counter-clockwise first.
    var neighbors: [Key] { [subdominant, dominant] }

    /// The five closely related keys: subdominant, dominant, relative, and the relatives of the neighbors.
    var closelyRelated: [Key] {
        [subdominant, dominant, relative, subdominant.relative, dominant.relative]
    }

    /// The same-sounding key with the other spelling (F# major ↔ Gb major), if both are standard.
    var enharmonicEquivalent: Key? {
        let alternative = fifths > 0 ? fifths - 12 : fifths + 12
        return Key(fifths: alternative, mode: mode)
    }
}

nonisolated extension Key: CustomStringConvertible {
    var description: String { name }
}

/// A key signature: the set of sharps or flats implied by a key.
nonisolated struct KeySignature: Hashable, Sendable {
    /// Positive = sharps, negative = flats.
    let fifths: Int

    static let sharpOrder: [NoteLetter] = [.f, .c, .g, .d, .a, .e, .b]
    static let flatOrder: [NoteLetter] = [.b, .e, .a, .d, .g, .c, .f]

    var sharpCount: Int { max(fifths, 0) }
    var flatCount: Int { max(-fifths, 0) }

    /// The altered notes in the order they are written (D major: F#, C#; Eb major: Bb, Eb, Ab).
    var accidentals: [PitchClass] {
        if fifths >= 0 {
            Self.sharpOrder.prefix(sharpCount).map { PitchClass($0, .sharp) }
        } else {
            Self.flatOrder.prefix(flatCount).map { PitchClass($0, .flat) }
        }
    }

    /// The accidental the signature applies to a letter.
    func accidental(for letter: NoteLetter) -> Accidental {
        accidentals.first { $0.letter == letter }?.accidental ?? .natural
    }

    /// "no sharps or flats", "1 sharp", "3 flats".
    var summary: String {
        switch fifths {
        case 0: "no sharps or flats"
        case 1: "1 sharp"
        case -1: "1 flat"
        case let n where n > 0: "\(n) sharps"
        default: "\(-fifths) flats"
        }
    }
}

/// The circle of fifths: the 12 key positions, clockwise from C.
nonisolated enum CircleOfFifths {
    /// Signatures used for the 12 positions; the bottom of the circle uses F# (6 sharps) and Db (5 flats).
    private static let positionFifths = [0, 1, 2, 3, 4, 5, 6, -5, -4, -3, -2, -1]

    /// C G D A E B F# Db Ab Eb Bb F
    static let majorKeys: [Key] = positionFifths.map { Key(fifths: $0, mode: .major)! }

    /// A E B F# C# G# D# Bb F C G D — the relative minor of each major position.
    static let minorKeys: [Key] = positionFifths.map { Key(fifths: $0, mode: .minor)! }

    /// Clockwise position 0–11 of a key, with C major / A minor at 0. Enharmonic keys share a position.
    static func position(of key: Key) -> Int {
        Theory.mod(key.fifths, 12)
    }

    static func key(atPosition position: Int, mode: Key.Mode) -> Key {
        (mode == .major ? majorKeys : minorKeys)[Theory.mod(position, 12)]
    }

    /// Fewest steps around the circle between two keys' signatures (0–6).
    static func distance(from a: Key, to b: Key) -> Int {
        let d = Theory.mod(position(of: b) - position(of: a), 12)
        return min(d, 12 - d)
    }
}
