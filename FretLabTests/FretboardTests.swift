import Foundation
import Testing
@testable import FretLab

@Suite("Tuning")
struct TuningTests {
    @Test func standard() {
        #expect(Tuning.standard.openStrings.map(\.name) == ["E2", "A2", "D3", "G3", "B3", "E4"])
        #expect(Tuning.standard.openStrings.map(\.midiNumber) == [40, 45, 50, 55, 59, 64])
        #expect(Tuning.standard.noteNames == "E A D G B E")
    }

    @Test(arguments: Tuning.presets)
    func presetsAreSixStringsAndUnique(tuning: Tuning) {
        #expect(tuning.stringCount == 6)
        #expect(Tuning.presets.filter { $0.id == tuning.id }.count == 1)
        // Every open string is within six-string guitar range (C2–G4).
        #expect(tuning.openStrings.allSatisfy { (36...67).contains($0.midiNumber) })
    }

    @Test func presetNotes() {
        #expect(Tuning.dropD.noteNames == "D A D G B E")
        #expect(Tuning.dadgad.noteNames == "D A D G A D")
        #expect(Tuning.openG.noteNames == "D G D G B D")
        #expect(Tuning.openD.noteNames == "D A D F# A D")
        #expect(Tuning.halfStepDown.noteNames == "Eb Ab Db Gb Bb Eb")
        #expect(zip(Tuning.halfStepDown.openStrings, Tuning.standard.openStrings).allSatisfy {
            $0.midiNumber == $1.midiNumber - 1
        })
    }

    @Test func dropDOnlyChangesTheLowString() {
        let changed = zip(Tuning.dropD.openStrings, Tuning.standard.openStrings).enumerated()
            .filter { $0.element.0 != $0.element.1 }
            .map(\.offset)
        #expect(changed == [0])
        #expect(Tuning.dropD.openStrings[0].midiNumber == 38)
    }

    @Test func stringCountLimits() {
        #expect(Tuning(name: "Bass", "E1 A1 D2 G2")?.stringCount == 4)
        #expect(Tuning(name: "Seven", "B1 E2 A2 D3 G3 B3 E4")?.stringCount == 7)
        #expect(Tuning(name: "Too few", "E2 A2 D3") == nil)
        #expect(Tuning(name: "Too many", "E1 A1 D2 G2 C3 F3 B3 E4 A4") == nil)
        #expect(Tuning(name: "Typo", "E2 A2 D3 G3 B3 H4") == nil)
    }
}

@Suite("Fretboard")
struct FretboardTests {
    let board = Fretboard()

    @Test func midiNumbers() {
        #expect(board.midiNumber(at: FretPosition(string: 0, fret: 0)) == 40)
        #expect(board.note(at: FretPosition(string: 0, fret: 5)) == note("A2"))
        #expect(board.note(at: FretPosition(string: 0, fret: 1)) == note("F2"))
        #expect(board.note(at: FretPosition(string: 5, fret: 0)) == note("E4"))
        #expect(board.note(at: FretPosition(string: 4, fret: 1)) == note("C4"))
        #expect(board.note(at: FretPosition(string: 0, fret: 6), preferring: .flats) == note("Bb2"))
        #expect(board.note(at: FretPosition(string: 5, fret: 22)) == note("D6"))
    }

    @Test func twelfthFretIsAnOctave() {
        for string in 0..<board.stringCount {
            let open = board.midiNumber(at: FretPosition(string: string, fret: 0))
            #expect(board.midiNumber(at: FretPosition(string: string, fret: 12)) == open + 12)
        }
    }

    /// The fifth fret matches the next open string, except the G string's fourth fret matches B.
    @Test func standardTuningUnisons() {
        for string in 0..<5 {
            let fret = string == 3 ? 4 : 5
            #expect(board.midiNumber(at: FretPosition(string: string, fret: fret)) ==
                    board.midiNumber(at: FretPosition(string: string + 1, fret: 0)))
        }
    }

    @Test func bounds() {
        #expect(board.allPositions.count == 6 * 23)
        #expect(board.contains(FretPosition(string: 5, fret: 22)))
        #expect(!board.contains(FretPosition(string: 6, fret: 0)))
        #expect(!board.contains(FretPosition(string: 0, fret: 23)))
        #expect(!board.contains(FretPosition(string: -1, fret: 0)))
    }

    @Test func everyC() {
        let frets = board.positions(of: .c).map { "\($0.string):\($0.fret)" }
        #expect(frets == ["0:8", "0:20", "1:3", "1:15", "2:10", "2:22", "3:5", "3:17", "4:1", "4:13", "5:8", "5:20"])
    }

    @Test func positionsOfIgnoreSpelling() {
        #expect(board.positions(of: pc("Bb")) == board.positions(of: pc("A#")))
        #expect(board.positions(of: pc("B#")) == board.positions(of: .c))
    }

    @Test func everyPositionHasExactlyOnePitchClass() {
        let total = (0..<12).map { board.positions(of: PitchClass(semitone: $0)).count }.reduce(0, +)
        #expect(total == board.allPositions.count)
    }

    @Test func fMajorIsSpelledWithBFlat() {
        let positions = board.positions(in: Scale(root: .f, type: .major))
        let names = Set(positions.map(\.note.pitchClass.name))
        #expect(names == ["F", "G", "A", "Bb", "C", "D", "E"])
        #expect(!names.contains("A#"))
        let aString6th = positions.first { $0.position == FretPosition(string: 1, fret: 1) }
        #expect(aString6th?.note == note("Bb2"))
        #expect(aString6th?.degree == 4)
    }

    @Test func octavesFollowTheSpelling() throws {
        // Low E, 8th fret is MIDI 48; in C# major it is B#2, not C3.
        let positions = board.positions(in: Scale(root: pc("C#"), type: .major))
        let position = try #require(positions.first { $0.position == FretPosition(string: 0, fret: 8) })
        #expect(position.note == note("B#2"))
        #expect(position.note.midiNumber == 48)
        #expect(position.degree == 7)
    }

    @Test(arguments: [ScaleType.major, .naturalMinor, .harmonicMinor, .dorian, .majorPentatonic, .minorPentatonic, .blues])
    func scalePositionsAreConsistent(type: ScaleType) {
        for root in ["E", "G", "Bb", "F#"].map(pc) {
            let scale = Scale(root: root, type: type)
            let positions = board.positions(in: scale)
            #expect(positions.count == board.allPositions.filter { scale.contains(midiNumber: board.midiNumber(at: $0)) }.count)
            for position in positions {
                #expect(position.note.midiNumber == board.midiNumber(at: position.position))
                #expect(position.note.pitchClass == scale.pitchClasses[position.degree - 1])
                #expect(position.interval == type.intervals[position.degree - 1])
                #expect(position.isRoot == (position.note.pitchClass == root))
            }
        }
    }

    @Test func pentatonicIntervals() throws {
        let positions = Fretboard().positions(in: Scale(root: .a, type: .minorPentatonic))
        let c = try #require(positions.first { $0.position == FretPosition(string: 1, fret: 3) })
        #expect(c.note == note("C3"))
        #expect(c.degree == 2)
        #expect(c.interval == .minorThird)
        #expect(positions.filter(\.isRoot).count == board.positions(of: .a).count)
    }

    @Test func alternateTuning() {
        let dropD = Fretboard(tuning: .dropD, fretCount: 12)
        #expect(dropD.note(at: FretPosition(string: 0, fret: 0)) == note("D2"))
        #expect(dropD.note(at: FretPosition(string: 0, fret: 2)) == note("E2"))
        #expect(dropD.allPositions.count == 6 * 13)
        let bass = Fretboard(tuning: Tuning(name: "Bass", "E1 A1 D2 G2")!, fretCount: 20)
        // E string: frets 0, 12 · A: 7, 19 · D: 2, 14 · G: 9 (21 is off the neck)
        #expect(bass.positions(of: .e).map(\.fret) == [0, 12, 7, 19, 2, 14, 9])
    }
}

@Suite("Conventional roots")
struct ConventionalRootTests {
    @Test(arguments: [
        (1, ScaleType.major, "Db"), (6, .major, "F#"), (8, .major, "Ab"), (10, .major, "Bb"), (11, .major, "B"),
        (1, .naturalMinor, "C#"), (3, .naturalMinor, "Eb"), (6, .naturalMinor, "F#"), (8, .naturalMinor, "G#"),
        (10, .naturalMinor, "Bb"), (1, .dorian, "C#"), (0, .blues, "C"), (4, .minorPentatonic, "E"),
    ])
    func picksTheSimplestSpelling(semitone: Int, type: ScaleType, expected: String) {
        #expect(Scale.conventionalRoot(forSemitone: semitone, type: type) == pc(expected))
    }

    @Test(arguments: ScaleType.allCases)
    func neverWorseThanTheCommonSpelling(type: ScaleType) {
        for semitone in 0..<12 {
            let chosen = Scale(root: Scale.conventionalRoot(forSemitone: semitone, type: type), type: type)
            let common = Scale(root: Scale.commonRoots[semitone], type: type)
            #expect(chosen.root.semitone == semitone)
            #expect(chosen.accidentalWeight <= common.accidentalWeight)
        }
    }

    @Test func degreeNames() {
        let names = [Interval.perfectUnison, .minorSecond, .majorThird, .minorThird, .augmentedFourth,
                     .diminishedFifth, .perfectFifth, .minorSixth, .diminishedSeventh, .minorSeventh,
                     .majorSeventh, Interval(.major, 9)!].map(\.degreeName)
        #expect(names == ["1", "b2", "3", "b3", "#4", "b5", "5", "b6", "bb7", "b7", "7", "9"])
    }
}

@Suite("Fretboard layout")
struct FretboardLayoutTests {
    let layout = FretboardLayout(fretCount: 22, stringCount: 6, width: 1500)

    @Test func endpoints() {
        #expect(layout.fretWireX(0) == layout.nutX)
        #expect(abs(layout.fretWireX(22) - layout.neckEndX) < 0.001)
    }

    @Test func fretsGetNarrowerFollowingTheTwelfthRootOfTwo() {
        for n in 2...22 {
            let ratio = layout.fretWidth(n) / layout.fretWidth(n - 1)
            #expect(abs(ratio - pow(2, -1.0 / 12)) < 1e-9)
        }
    }

    @Test func twelfthFretIsHalfTheScaleLength() {
        // Fret 24 would be 3/4 of the scale; fret 12 is half of the scale, i.e. 2/3 of the way to fret 24.
        let wide = FretboardLayout(fretCount: 24, stringCount: 6, width: 2000)
        let toTwelve = wide.fretWireX(12) - wide.nutX
        let toTwentyFour = wide.fretWireX(24) - wide.nutX
        #expect(abs(toTwelve / toTwentyFour - 2.0 / 3) < 1e-9)
    }

    @Test func markersSitBetweenWires() {
        #expect(layout.markerX(fret: 0) < layout.nutX)
        for fret in 1...22 {
            #expect(layout.markerX(fret: fret) > layout.fretWireX(fret - 1))
            #expect(layout.markerX(fret: fret) < layout.fretWireX(fret))
        }
    }

    @Test func highStringOnTop() {
        #expect(layout.stringY(5) < layout.stringY(0))
        #expect(layout.stringY(5) - layout.neckTop == FretboardLayout.stringSpacing / 2)
        #expect(layout.neckTop >= 0)
        #expect(layout.neckBottom < layout.height)
    }

    @Test func minimumWidthKeepsHighFretsPlayable() {
        let width = FretboardLayout.minimumWidth(fretCount: 22)
        let narrow = FretboardLayout(fretCount: 22, stringCount: 6, width: width)
        #expect(narrow.fretWidth(22) >= FretboardLayout.minimumFretWidth - 0.001)
        #expect(narrow.fretWidth(22) - FretboardLayout.minimumFretWidth < 1)
    }
}
