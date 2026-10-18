/// A scale type built on a specific root, spelled correctly for that root.
nonisolated struct Scale: Hashable, Sendable {
    let root: PitchClass
    let type: ScaleType

    init(root: PitchClass, type: ScaleType) {
        self.root = root
        self.type = type
    }

    /// The scale's pitch classes in ascending order from the root (F major: F G A Bb C D E).
    var pitchClasses: [PitchClass] {
        type.intervals.map { root.transposed(by: $0) }
    }

    var noteNames: [String] { pitchClasses.map(\.name) }

    /// One ascending octave of notes starting from the root in `octave`.
    func notes(startingAt octave: Int) -> [Note] {
        let rootNote = Note(root, octave: octave)
        return type.intervals.map { rootNote.transposed(by: $0) }
    }

    /// "F Major", "A Blues".
    var name: String { "\(root.name) \(type.name)" }

    /// Whether the scale contains this pitch, ignoring spelling (A# counts for a scale containing Bb).
    func contains(_ pitchClass: PitchClass) -> Bool {
        degree(of: pitchClass) != nil
    }

    /// Whether the scale contains this MIDI pitch in any octave — handy for fretboard lookups.
    func contains(midiNumber: Int) -> Bool {
        pitchClasses.contains { $0.semitone == Theory.mod(midiNumber, 12) }
    }

    /// 1-based scale degree of a pitch, ignoring spelling; nil if the pitch is not in the scale.
    func degree(of pitchClass: PitchClass) -> Int? {
        pitchClasses.firstIndex { $0.isEnharmonic(with: pitchClass) }.map { $0 + 1 }
    }

    /// How this scale spells the given pitch (A# in F major → Bb), or nil if it is not in the scale.
    func spelling(of pitchClass: PitchClass) -> PitchClass? {
        pitchClasses.first { $0.isEnharmonic(with: pitchClass) }
    }

    /// Total accidentals across the scale's spelling (a double sharp counts as 2).
    var accidentalWeight: Int {
        pitchClasses.reduce(0) { $0 + abs($1.accidental.offset) }
    }

    /// The usual root names for the 12 pitches when there is no other context.
    static let commonRoots: [PitchClass] = ["C", "Db", "D", "Eb", "E", "F", "F#", "G", "Ab", "A", "Bb", "B"]
        .map { PitchClass($0)! }

    /// The spelling of a root pitch (0–11) that gives the simplest scale of this type:
    /// C# minor rather than Db minor, Db major rather than C# major. Ties go to `commonRoots`.
    static func conventionalRoot(forSemitone semitone: Int, type: ScaleType) -> PitchClass {
        let common = commonRoots[Theory.mod(semitone, 12)]
        let candidates = [common, PitchClass(semitone: semitone, preferring: .sharps),
                          PitchClass(semitone: semitone, preferring: .flats)]
        // min(by:) returns the first minimum, so the common spelling wins ties.
        return candidates.min { Scale(root: $0, type: type).accidentalWeight < Scale(root: $1, type: type).accidentalWeight }!
    }
}
