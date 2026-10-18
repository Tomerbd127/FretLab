/// A spot on the neck. String 0 is the lowest-pitched string; fret 0 is the open string.
nonisolated struct FretPosition: Hashable, Sendable {
    let string: Int
    let fret: Int
}

/// A scale tone found on the neck, spelled the way the scale spells it.
nonisolated struct ScalePosition: Hashable, Sendable, Identifiable {
    let position: FretPosition
    let note: Note
    /// 1-based scale degree.
    let degree: Int
    /// Interval of this tone above the scale root.
    let interval: Interval

    var id: FretPosition { position }
    var isRoot: Bool { degree == 1 }
}

/// A tuned neck with a fixed number of frets.
nonisolated struct Fretboard: Hashable, Sendable {
    let tuning: Tuning
    let fretCount: Int

    init(tuning: Tuning = .standard, fretCount: Int = 22) {
        precondition(fretCount >= 1, "A fretboard needs at least one fret")
        self.tuning = tuning
        self.fretCount = fretCount
    }

    var stringCount: Int { tuning.stringCount }

    func contains(_ position: FretPosition) -> Bool {
        (0..<stringCount).contains(position.string) && (0...fretCount).contains(position.fret)
    }

    /// Every position, string by string from the lowest, frets ascending.
    var allPositions: [FretPosition] {
        (0..<stringCount).flatMap { string in
            (0...fretCount).map { FretPosition(string: string, fret: $0) }
        }
    }

    func midiNumber(at position: FretPosition) -> Int {
        precondition(contains(position), "\(position) is off the neck")
        return tuning.openStrings[position.string].midiNumber + position.fret
    }

    /// The note at a position, spelled without musical context.
    func note(at position: FretPosition, preferring spelling: AccidentalPreference = .sharps) -> Note {
        Note(midiNumber: midiNumber(at: position), preferring: spelling)
    }

    /// Every position sounding this pitch class, in any octave and spelling.
    func positions(of pitchClass: PitchClass) -> [FretPosition] {
        allPositions.filter { Theory.mod(midiNumber(at: $0), 12) == pitchClass.semitone }
    }

    /// Every position that belongs to the scale, with the scale's spelling, degree and interval.
    func positions(in scale: Scale) -> [ScalePosition] {
        let pitchClasses = scale.pitchClasses
        let intervals = scale.type.intervals
        return allPositions.compactMap { position in
            let midi = midiNumber(at: position)
            guard let index = pitchClasses.firstIndex(where: { $0.semitone == Theory.mod(midi, 12) }),
                  let note = Note(midiNumber: midi, spelledAs: pitchClasses[index])
            else { return nil }
            return ScalePosition(position: position, note: note, degree: index + 1, interval: intervals[index])
        }
    }
}
