import Testing
@testable import FretLab

@Suite("Scale")
struct ScaleTests {
    @Test(arguments: [
        // Major — sharp, flat, and extreme keys
        ("C", ScaleType.major, "C D E F G A B"),
        ("F", .major, "F G A Bb C D E"),
        ("G", .major, "G A B C D E F#"),
        ("Bb", .major, "Bb C D Eb F G A"),
        ("E", .major, "E F# G# A B C# D#"),
        ("Ab", .major, "Ab Bb C Db Eb F G"),
        ("F#", .major, "F# G# A# B C# D# E#"),
        ("Gb", .major, "Gb Ab Bb Cb Db Eb F"),
        ("C#", .major, "C# D# E# F# G# A# B#"),
        ("Cb", .major, "Cb Db Eb Fb Gb Ab Bb"),
        // Minors
        ("A", .naturalMinor, "A B C D E F G"),
        ("E", .naturalMinor, "E F# G A B C D"),
        ("D", .naturalMinor, "D E F G A Bb C"),
        ("Eb", .naturalMinor, "Eb F Gb Ab Bb Cb Db"),
        ("A", .harmonicMinor, "A B C D E F G#"),
        ("C", .harmonicMinor, "C D Eb F G Ab B"),
        ("G#", .harmonicMinor, "G# A# B C# D# E F##"),
        ("D#", .harmonicMinor, "D# E# F# G# A# B C##"),
        ("A", .melodicMinor, "A B C D E F# G#"),
        ("C", .melodicMinor, "C D Eb F G A B"),
        ("Bb", .melodicMinor, "Bb C Db Eb F G A"),
        // Modes on their white-key roots
        ("C", .ionian, "C D E F G A B"),
        ("D", .dorian, "D E F G A B C"),
        ("E", .phrygian, "E F G A B C D"),
        ("F", .lydian, "F G A B C D E"),
        ("G", .mixolydian, "G A B C D E F"),
        ("A", .aeolian, "A B C D E F G"),
        ("B", .locrian, "B C D E F G A"),
        // Modes on C
        ("C", .dorian, "C D Eb F G A Bb"),
        ("C", .phrygian, "C Db Eb F G Ab Bb"),
        ("C", .lydian, "C D E F# G A B"),
        ("C", .mixolydian, "C D E F G A Bb"),
        ("C", .locrian, "C Db Eb F Gb Ab Bb"),
        // Modes on other roots
        ("F#", .dorian, "F# G# A B C# D# E"),
        ("Eb", .lydian, "Eb F G A Bb C D"),
        ("Bb", .mixolydian, "Bb C D Eb F G Ab"),
        ("C#", .phrygian, "C# D E F# G# A B"),
        // Pentatonics
        ("C", .majorPentatonic, "C D E G A"),
        ("G", .majorPentatonic, "G A B D E"),
        ("Bb", .majorPentatonic, "Bb C D F G"),
        ("A", .minorPentatonic, "A C D E G"),
        ("E", .minorPentatonic, "E G A B D"),
        ("F#", .minorPentatonic, "F# A B C# E"),
        // Blues — the blue note is spelled as a flat five
        ("A", .blues, "A C D Eb E G"),
        ("E", .blues, "E G A Bb B D"),
        ("C", .blues, "C Eb F Gb G Bb"),
        ("F#", .blues, "F# A B C C# E"),
    ])
    func spelling(root: String, type: ScaleType, expected: String) {
        let scale = Scale(root: pc(root), type: type)
        #expect(scale.noteNames.joined(separator: " ") == expected)
    }

    @Test(arguments: ScaleType.allCases)
    func everyPatternSpansOneOctave(type: ScaleType) {
        #expect(type.stepPattern.reduce(0, +) == 12)
        #expect(type.stepPattern.allSatisfy { $0 > 0 })
        #expect(type.intervals.first == .perfectUnison)
    }

    @Test func stepPatterns() {
        #expect(ScaleType.major.stepPattern == [2, 2, 1, 2, 2, 2, 1])
        #expect(ScaleType.naturalMinor.stepPattern == [2, 1, 2, 2, 1, 2, 2])
        #expect(ScaleType.harmonicMinor.stepPattern == [2, 1, 2, 2, 1, 3, 1])
        #expect(ScaleType.melodicMinor.stepPattern == [2, 1, 2, 2, 2, 2, 1])
        #expect(ScaleType.majorPentatonic.stepPattern == [2, 2, 3, 2, 3])
        #expect(ScaleType.minorPentatonic.stepPattern == [3, 2, 2, 3, 2])
        #expect(ScaleType.blues.stepPattern == [3, 2, 1, 1, 3, 2])
    }

    @Test func aliasesMatch() {
        #expect(ScaleType.major.intervals == ScaleType.ionian.intervals)
        #expect(ScaleType.naturalMinor.intervals == ScaleType.aeolian.intervals)
    }

    /// Each mode is the parent major scale started from a different degree.
    @Test(arguments: ["C", "G", "Bb", "F#", "Eb", "Db"])
    func modesAreRotationsOfMajor(parent: String) {
        let major = Scale(root: pc(parent), type: .major).pitchClasses
        for (degree, mode) in ScaleType.modes.enumerated() {
            let rotated = Array(major[degree...] + major[..<degree])
            #expect(Scale(root: major[degree], type: mode).pitchClasses == rotated, "\(mode.name) of \(parent)")
        }
    }

    /// The core spelling invariant: a 7-note scale uses every letter exactly once, in order.
    @Test(arguments: ScaleType.allCases.filter { $0.intervals.count == 7 })
    func heptatonicScalesUseEachLetterOnce(type: ScaleType) {
        let roots = ["C", "G", "D", "A", "E", "B", "F#", "C#", "F", "Bb", "Eb", "Ab", "Db", "Gb", "Cb", "G#", "D#", "A#"]
        for root in roots {
            let letters = Scale(root: pc(root), type: type).pitchClasses.map(\.letter)
            let expected = (0..<7).map { pc(root).letter.advanced(by: $0) }
            #expect(letters == expected, "\(root) \(type.name)")
        }
    }

    @Test func pentatonicsAreSubsetsOfTheirParentScales() {
        for root in ["C", "A", "F#", "Bb"].map(pc) {
            let majorPentatonic = Set(Scale(root: root, type: .majorPentatonic).pitchClasses)
            #expect(majorPentatonic.isSubset(of: Scale(root: root, type: .major).pitchClasses))
            let minorPentatonic = Set(Scale(root: root, type: .minorPentatonic).pitchClasses)
            #expect(minorPentatonic.isSubset(of: Scale(root: root, type: .naturalMinor).pitchClasses))
        }
    }

    @Test func membershipIgnoresSpelling() {
        let fMajor = Scale(root: .f, type: .major)
        #expect(fMajor.contains(pc("Bb")))
        #expect(fMajor.contains(pc("A#")))
        #expect(!fMajor.contains(.b))
        #expect(fMajor.spelling(of: pc("A#")) == pc("Bb"))
        #expect(fMajor.spelling(of: .b) == nil)
        #expect(fMajor.degree(of: .f) == 1)
        #expect(fMajor.degree(of: pc("Bb")) == 4)
        #expect(fMajor.degree(of: .e) == 7)
        #expect(fMajor.degree(of: pc("F#")) == nil)
    }

    @Test func membershipByMIDINumber() {
        let fMajor = Scale(root: .f, type: .major)
        #expect(fMajor.contains(midiNumber: 70)) // Bb4
        #expect(fMajor.contains(midiNumber: 22)) // Bb0
        #expect(!fMajor.contains(midiNumber: 66)) // F#4
    }

    @Test func notesInOctave() {
        let aMinor = Scale(root: .a, type: .naturalMinor).notes(startingAt: 3)
        #expect(aMinor.map(\.name) == ["A3", "B3", "C4", "D4", "E4", "F4", "G4"])
        let bMajor = Scale(root: .b, type: .major).notes(startingAt: 2)
        #expect(bMajor.map(\.name) == ["B2", "C#3", "D#3", "E3", "F#3", "G#3", "A#3"])
        #expect(bMajor.map(\.midiNumber) == [47, 49, 51, 52, 54, 56, 58])
    }

    @Test func name() {
        #expect(Scale(root: .f, type: .major).name == "F Major")
        #expect(Scale(root: pc("C#"), type: .harmonicMinor).name == "C# Harmonic Minor")
    }
}
