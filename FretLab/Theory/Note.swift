import Foundation

/// A spelled pitch in a specific octave, using scientific pitch notation (C4 = middle C = MIDI 60).
///
/// The octave belongs to the *letter*: B#3 and C4 are both MIDI 60, and Cb4 is MIDI 59.
/// Equality compares spelling; ordering compares pitch, so enharmonic notes are
/// neither equal nor ordered relative to each other.
nonisolated struct Note: Hashable, Sendable {
    let pitchClass: PitchClass
    let octave: Int

    init(_ pitchClass: PitchClass, octave: Int) {
        self.pitchClass = pitchClass
        self.octave = octave
    }

    init(_ letter: NoteLetter, _ accidental: Accidental = .natural, octave: Int) {
        self.init(PitchClass(letter, accidental), octave: octave)
    }

    /// Parses names such as "C4", "Bb3", "F#-1", "Cb4".
    init?(_ text: String) {
        guard let digitStart = text.firstIndex(where: { $0.isNumber || $0 == "-" }),
              let octave = Int(text[digitStart...]),
              let pitchClass = PitchClass(String(text[..<digitStart]))
        else { return nil }
        self.init(pitchClass, octave: octave)
    }

    /// Spells a MIDI number using sharps or flats.
    init(midiNumber: Int, preferring spelling: AccidentalPreference = .sharps) {
        let pitchClass = PitchClass(semitone: midiNumber, preferring: spelling)
        // Conventional spellings never cross the B/C boundary, so the octave is just the MIDI octave.
        self.init(pitchClass, octave: Theory.floorDiv(midiNumber, 12) - 1)
    }

    /// Spells a MIDI number with a specific pitch class (e.g. MIDI 60 as B#3), or nil if they aren't enharmonic.
    init?(midiNumber: Int, spelledAs pitchClass: PitchClass) {
        guard Theory.mod(midiNumber, 12) == pitchClass.semitone else { return nil }
        let unwrapped = pitchClass.letter.naturalSemitone + pitchClass.accidental.offset
        self.init(pitchClass, octave: Theory.floorDiv(midiNumber - unwrapped, 12) - 1)
    }

    var letter: NoteLetter { pitchClass.letter }
    var accidental: Accidental { pitchClass.accidental }

    var midiNumber: Int {
        (octave + 1) * 12 + letter.naturalSemitone + accidental.offset
    }

    /// Count of diatonic letter steps above C0's octave origin; used to measure intervals.
    var diatonicIndex: Int { octave * 7 + letter.rawValue }

    var name: String { pitchClass.name + String(octave) }

    /// Frequency in Hz in twelve-tone equal temperament.
    func frequency(concertA: Double = 440) -> Double {
        concertA * pow(2, Double(midiNumber - 69) / 12)
    }

    func isEnharmonic(with other: Note) -> Bool {
        midiNumber == other.midiNumber
    }

    func transposed(by interval: Interval) -> Note {
        Note(diatonicIndex: diatonicIndex + interval.steps, midiNumber: midiNumber + interval.semitones)
    }

    func transposed(downBy interval: Interval) -> Note {
        Note(diatonicIndex: diatonicIndex - interval.steps, midiNumber: midiNumber - interval.semitones)
    }

    /// The note with the given letter position whose accidental makes it sound at `midiNumber`.
    private init(diatonicIndex: Int, midiNumber: Int) {
        let letter = NoteLetter(rawValue: Theory.mod(diatonicIndex, 7))!
        let octave = Theory.floorDiv(diatonicIndex, 7)
        let naturalMIDI = (octave + 1) * 12 + letter.naturalSemitone
        self.init(letter, Accidental(offset: midiNumber - naturalMIDI), octave: octave)
    }
}

nonisolated extension Note: Comparable {
    static func < (lhs: Note, rhs: Note) -> Bool {
        lhs.midiNumber < rhs.midiNumber
    }
}

nonisolated extension Note: CustomStringConvertible {
    var description: String { name }
}
