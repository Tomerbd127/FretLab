import Testing
@testable import FretLab

@Suite("Interval")
struct IntervalTests {
    @Test(arguments: [
        (Interval.perfectUnison, 0), (.augmentedUnison, 1), (.minorSecond, 1), (.majorSecond, 2),
        (.augmentedSecond, 3), (.minorThird, 3), (.majorThird, 4), (.perfectFourth, 5),
        (.augmentedFourth, 6), (.diminishedFifth, 6), (.perfectFifth, 7), (.augmentedFifth, 8),
        (.minorSixth, 8), (.majorSixth, 9), (.diminishedSeventh, 9), (.minorSeventh, 10),
        (.majorSeventh, 11), (.perfectOctave, 12),
        (Interval(.minor, 9)!, 13), (Interval(.major, 9)!, 14), (Interval(.minor, 10)!, 15),
        (Interval(.perfect, 11)!, 17), (Interval(.augmented, 11)!, 18), (Interval(.major, 13)!, 21),
        (Interval(.perfect, 15)!, 24),
    ])
    func semitones(interval: Interval, semitones: Int) {
        #expect(interval.semitones == semitones)
    }

    @Test(arguments: [
        (Interval.Quality.major, 5), (.minor, 4), (.perfect, 3), (.perfect, 2), (.major, 1),
        (.minor, 8), (.perfect, 0), (.major, -3), (.diminished, 1), (.major, 12),
    ])
    func rejectsImpossibleIntervals(quality: Interval.Quality, number: Int) {
        #expect(Interval(quality, number) == nil)
    }

    @Test func names() {
        #expect(Interval.majorThird.shortName == "M3")
        #expect(Interval.perfectFifth.shortName == "P5")
        #expect(Interval.diminishedSeventh.shortName == "d7")
        #expect(Interval.augmentedFourth.shortName == "A4")
        #expect(Interval.majorThird.name == "major third")
        #expect(Interval.perfectOctave.name == "perfect octave")
        #expect(Interval(.major, 9)!.name == "major ninth")
        #expect(Interval.perfectUnison.name == "perfect unison")
    }

    @Test func compound() {
        #expect(!Interval.perfectOctave.isCompound)
        #expect(Interval(.minor, 9)!.isCompound)
    }

    @Test(arguments: [
        ("C4", "E4", "M3"), ("C4", "Eb4", "m3"), ("C4", "D#4", "A2"), ("E4", "Bb4", "d5"),
        ("F4", "B4", "A4"), ("B3", "C4", "m2"), ("C4", "C5", "P8"), ("C4", "D5", "M9"),
        ("C#4", "Bb4", "d7"), ("C4", "C4", "P1"), ("C4", "C#4", "A1"), ("B#3", "C4", "d2"),
        ("E2", "E4", "P15"), ("A3", "G4", "m7"),
    ])
    func betweenNotes(lower: String, upper: String, expected: String) throws {
        let interval = try #require(Interval.between(note(lower), note(upper)))
        #expect(interval.shortName == expected)
        #expect(interval.semitones == note(upper).midiNumber - note(lower).midiNumber)
    }

    @Test func betweenNotesFailsWhenUndefined() {
        #expect(Interval.between(note("G4"), note("C4")) == nil, "descending")
        #expect(Interval.between(note("C4"), note("F##4")) == nil, "doubly augmented")
        #expect(Interval.between(note("C4"), note("Cb4")) == nil, "diminished unison")
    }

    @Test(arguments: [
        ("B", "C", "m2"), ("A", "C", "m3"), ("F", "B", "A4"), ("C", "B#", "A7"), ("B", "Cb", "d2"),
        ("D", "D", "P1"), ("G", "F", "m7"), ("E", "C", "m6"), ("Bb", "Ab", "m7"),
    ])
    func betweenPitchClasses(lower: String, upper: String, expected: String) throws {
        let interval = try #require(Interval.between(pc(lower), pc(upper)))
        #expect(interval.shortName == expected)
    }

    @Test(arguments: ["C", "Eb", "F#", "Bb", "G#", "Cb"])
    func transposeThenMeasureRoundTrips(root: String) {
        let intervals: [Interval] = [
            .perfectUnison, .minorSecond, .majorSecond, .augmentedSecond, .minorThird, .majorThird,
            .perfectFourth, .augmentedFourth, .diminishedFifth, .perfectFifth, .augmentedFifth,
            .minorSixth, .majorSixth, .diminishedSeventh, .minorSeventh, .majorSeventh, .perfectOctave,
            Interval(.major, 9)!, Interval(.perfect, 11)!, Interval(.major, 13)!,
        ]
        let start = Note(pc(root), octave: 3)
        for interval in intervals {
            #expect(Interval.between(start, start.transposed(by: interval)) == interval)
        }
    }

    @Test func stepsFromSemitonesConstruction() {
        #expect(Interval(steps: 2, semitones: 4) == .majorThird)
        #expect(Interval(steps: 1, semitones: 3) == .augmentedSecond)
        #expect(Interval(steps: 4, semitones: 6) == .diminishedFifth)
        #expect(Interval(steps: 3, semitones: 6) == .augmentedFourth)
        #expect(Interval(steps: 2, semitones: 7) == nil)
        #expect(Interval(steps: -1, semitones: 0) == nil)
    }
}
