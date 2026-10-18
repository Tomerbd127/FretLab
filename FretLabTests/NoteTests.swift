import Testing
@testable import FretLab

/// Parses a pitch class in test tables; a typo in a fixture should crash loudly.
func pc(_ name: String) -> PitchClass {
    guard let pitchClass = PitchClass(name) else { fatalError("Bad pitch class fixture: \(name)") }
    return pitchClass
}

func note(_ name: String) -> Note {
    guard let note = Note(name) else { fatalError("Bad note fixture: \(name)") }
    return note
}

@Suite("Accidental")
struct AccidentalTests {
    @Test(arguments: [(-2, "bb", "𝄫"), (-1, "b", "♭"), (0, "", ""), (1, "#", "♯"), (2, "##", "𝄪"), (3, "###", "𝄪♯")])
    func symbols(offset: Int, ascii: String, unicode: String) {
        let accidental = Accidental(offset: offset)
        #expect(accidental.symbol == ascii)
        #expect(accidental.unicodeSymbol == unicode)
    }

    @Test(arguments: [("", 0), ("#", 1), ("##", 2), ("x", 2), ("b", -1), ("bb", -2), ("♯", 1), ("♭", -1), ("𝄪", 2), ("𝄫", -2), ("♮", 0)])
    func parsing(text: String, offset: Int) throws {
        let accidental = try #require(Accidental(Substring(text)))
        #expect(accidental.offset == offset)
    }

    @Test func rejectsGarbage() {
        #expect(Accidental("$") == nil)
        #expect(Accidental("#q") == nil)
    }
}

@Suite("PitchClass")
struct PitchClassTests {
    @Test(arguments: [
        ("C", 0), ("C#", 1), ("Db", 1), ("D", 2), ("Eb", 3), ("E", 4), ("F", 5), ("F#", 6), ("Gb", 6),
        ("G", 7), ("Ab", 8), ("A", 9), ("A#", 10), ("Bb", 10), ("B", 11),
        ("B#", 0), ("Cb", 11), ("E#", 5), ("Fb", 4), ("C##", 2), ("Dbb", 0), ("Bbb", 9),
    ])
    func semitone(name: String, semitone: Int) throws {
        let pitchClass = try #require(PitchClass(name))
        #expect(pitchClass.semitone == semitone)
    }

    @Test(arguments: ["C", "F#", "Bb", "Ebb", "G##", "Cb", "E#"])
    func nameRoundTrip(name: String) throws {
        #expect(try #require(PitchClass(name)).name == name)
    }

    @Test func parsingIsLenient() {
        #expect(PitchClass("f#") == PitchClass(.f, .sharp))
        #expect(PitchClass("bb") == PitchClass(.b, .flat))
        #expect(PitchClass("B♭") == PitchClass(.b, .flat))
        #expect(PitchClass("Fx") == PitchClass(.f, .doubleSharp))
    }

    @Test(arguments: ["", "H", "C$", "#", "b#x?"])
    func parsingRejectsInvalid(text: String) {
        #expect(PitchClass(text) == nil)
    }

    @Test func unicodeName() {
        #expect(pc("Bb").unicodeName == "B♭")
        #expect(pc("F##").unicodeName == "F𝄪")
        #expect(pc("C").unicodeName == "C")
    }

    @Test func spellingIsPreservedButEnharmonicsAreDetected() {
        #expect(pc("Bb") != pc("A#"))
        #expect(pc("Bb").isEnharmonic(with: pc("A#")))
        #expect(pc("B#").isEnharmonic(with: .c))
        #expect(!pc("Bb").isEnharmonic(with: .b))
    }

    @Test(arguments: [("C", 0), ("G", 1), ("D", 2), ("F", -1), ("Bb", -2), ("F#", 6), ("C#", 7), ("Gb", -6), ("Cb", -7), ("G#", 8), ("Fb", -8)])
    func lineOfFifths(name: String, fifths: Int) {
        #expect(pc(name).fifthsFromC == fifths)
        #expect(PitchClass(fifthsFromC: fifths) == pc(name))
    }

    @Test func lineOfFifthsRoundTrips() {
        for fifths in -21...21 {
            #expect(PitchClass(fifthsFromC: fifths).fifthsFromC == fifths)
        }
    }

    @Test func spellingFromSemitone() {
        let sharps = (0..<12).map { PitchClass(semitone: $0, preferring: .sharps).name }
        let flats = (0..<12).map { PitchClass(semitone: $0, preferring: .flats).name }
        #expect(sharps == ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"])
        #expect(flats == ["C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"])
        #expect(PitchClass(semitone: -1) == .b)
        #expect(PitchClass(semitone: 13) == pc("C#"))
    }

    @Test(arguments: [
        ("F", Interval.perfectFourth, "Bb"), ("E", .minorSecond, "F"), ("B", .minorSecond, "C"),
        ("Cb", .majorThird, "Eb"), ("D#", .majorThird, "F##"), ("C", .augmentedFourth, "F#"),
        ("C", .diminishedFifth, "Gb"), ("A", .minorThird, "C"), ("G", .majorSeventh, "F#"),
    ])
    func transposition(root: String, interval: Interval, expected: String) {
        #expect(pc(root).transposed(by: interval) == pc(expected))
        #expect(pc(expected).transposed(downBy: interval) == pc(root))
    }
}

@Suite("Note")
struct NoteTests {
    @Test(arguments: [
        ("C4", 60), ("A4", 69), ("C-1", 0), ("G9", 127), ("E2", 40), ("E4", 64),
        ("B#3", 60), ("Cb4", 59), ("E#4", 65), ("Fb4", 64), ("Bbb3", 57), ("C##4", 62), ("Bb3", 58),
    ])
    func midiNumber(name: String, midi: Int) throws {
        #expect(try #require(Note(name)).midiNumber == midi)
    }

    @Test(arguments: ["C4", "Bb3", "F#-1", "Cb4", "B#3", "G##7"])
    func nameRoundTrip(name: String) throws {
        #expect(try #require(Note(name)).name == name)
    }

    @Test(arguments: ["", "C", "4", "H4", "Cq4", "C4.5"])
    func parsingRejectsInvalid(text: String) {
        #expect(Note(text) == nil)
    }

    @Test func octaveBelongsToTheLetter() {
        let bSharp3 = note("B#3")
        #expect(bSharp3.octave == 3)
        #expect(bSharp3.isEnharmonic(with: note("C4")))
        #expect(bSharp3 != note("C4"))
    }

    @Test func spellingFromMIDI() {
        #expect(Note(midiNumber: 61) == note("C#4"))
        #expect(Note(midiNumber: 61, preferring: .flats) == note("Db4"))
        #expect(Note(midiNumber: 70, preferring: .flats) == note("Bb4"))
        #expect(Note(midiNumber: 0) == note("C-1"))
        #expect(Note(midiNumber: 59) == note("B3"))
    }

    @Test(arguments: [AccidentalPreference.sharps, .flats])
    func midiRoundTrip(preference: AccidentalPreference) {
        for midi in 0...127 {
            #expect(Note(midiNumber: midi, preferring: preference).midiNumber == midi)
        }
    }

    @Test func frequency() {
        #expect(note("A4").frequency() == 440)
        #expect(note("A5").frequency() == 880)
        #expect(note("A4").frequency(concertA: 432) == 432)
        #expect(abs(note("C4").frequency() - 261.6256) < 0.001)
    }

    @Test(arguments: [
        ("C4", Interval.perfectFifth, "G4"), ("B3", .minorSecond, "C4"), ("E4", .augmentedFourth, "A#4"),
        ("B4", .majorSecond, "C#5"), ("C4", .perfectOctave, "C5"), ("Bb3", .majorThird, "D4"),
        ("G4", .perfectFourth, "C5"), ("C4", Interval(.major, 9)!, "D5"), ("E2", Interval(.perfect, 11)!, "A3"),
    ])
    func transposition(start: String, interval: Interval, expected: String) {
        #expect(note(start).transposed(by: interval) == note(expected))
        #expect(note(expected).transposed(downBy: interval) == note(start))
    }

    @Test func sortsByPitch() {
        let sorted = [note("E4"), note("Cb4"), note("C4"), note("A3")].sorted()
        #expect(sorted.map(\.name) == ["A3", "Cb4", "C4", "E4"])
        #expect(note("Cb4") < note("C4"))
    }
}
