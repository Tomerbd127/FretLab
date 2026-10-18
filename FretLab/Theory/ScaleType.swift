/// A scale defined as a pattern of intervals above its root.
nonisolated enum ScaleType: CaseIterable, Hashable, Sendable {
    case major
    case naturalMinor
    case harmonicMinor
    /// Ascending ("jazz") melodic minor.
    case melodicMinor

    case ionian
    case dorian
    case phrygian
    case lydian
    case mixolydian
    case aeolian
    case locrian

    case majorPentatonic
    case minorPentatonic
    /// Minor pentatonic plus the flat-five "blue note".
    case blues

    static let modes: [ScaleType] = [.ionian, .dorian, .phrygian, .lydian, .mixolydian, .aeolian, .locrian]

    var name: String {
        switch self {
        case .major: "Major"
        case .naturalMinor: "Natural Minor"
        case .harmonicMinor: "Harmonic Minor"
        case .melodicMinor: "Melodic Minor"
        case .ionian: "Ionian"
        case .dorian: "Dorian"
        case .phrygian: "Phrygian"
        case .lydian: "Lydian"
        case .mixolydian: "Mixolydian"
        case .aeolian: "Aeolian"
        case .locrian: "Locrian"
        case .majorPentatonic: "Major Pentatonic"
        case .minorPentatonic: "Minor Pentatonic"
        case .blues: "Blues"
        }
    }

    /// Intervals above the root, ascending, starting with the unison.
    var intervals: [Interval] {
        switch self {
        case .major, .ionian:
            [.perfectUnison, .majorSecond, .majorThird, .perfectFourth, .perfectFifth, .majorSixth, .majorSeventh]
        case .dorian:
            [.perfectUnison, .majorSecond, .minorThird, .perfectFourth, .perfectFifth, .majorSixth, .minorSeventh]
        case .phrygian:
            [.perfectUnison, .minorSecond, .minorThird, .perfectFourth, .perfectFifth, .minorSixth, .minorSeventh]
        case .lydian:
            [.perfectUnison, .majorSecond, .majorThird, .augmentedFourth, .perfectFifth, .majorSixth, .majorSeventh]
        case .mixolydian:
            [.perfectUnison, .majorSecond, .majorThird, .perfectFourth, .perfectFifth, .majorSixth, .minorSeventh]
        case .naturalMinor, .aeolian:
            [.perfectUnison, .majorSecond, .minorThird, .perfectFourth, .perfectFifth, .minorSixth, .minorSeventh]
        case .locrian:
            [.perfectUnison, .minorSecond, .minorThird, .perfectFourth, .diminishedFifth, .minorSixth, .minorSeventh]
        case .harmonicMinor:
            [.perfectUnison, .majorSecond, .minorThird, .perfectFourth, .perfectFifth, .minorSixth, .majorSeventh]
        case .melodicMinor:
            [.perfectUnison, .majorSecond, .minorThird, .perfectFourth, .perfectFifth, .majorSixth, .majorSeventh]
        case .majorPentatonic:
            [.perfectUnison, .majorSecond, .majorThird, .perfectFifth, .majorSixth]
        case .minorPentatonic:
            [.perfectUnison, .minorThird, .perfectFourth, .perfectFifth, .minorSeventh]
        case .blues:
            [.perfectUnison, .minorThird, .perfectFourth, .diminishedFifth, .perfectFifth, .minorSeventh]
        }
    }

    /// Semitone distances between consecutive degrees, including the step back to the octave
    /// (major: 2 2 1 2 2 2 1).
    var stepPattern: [Int] {
        let semitones = intervals.map(\.semitones) + [12]
        return zip(semitones, semitones.dropFirst()).map { $1 - $0 }
    }
}
