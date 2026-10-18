import Foundation
import Observation

/// What to print inside each note marker.
enum LabelMode: String, CaseIterable, Identifiable {
    case noteNames = "Notes"
    case degrees = "Degrees"
    case intervals = "Intervals"

    var id: Self { self }
}

/// The scale/tuning selection behind the fretboard screen.
@Observable
final class FretboardViewModel {
    /// Root pitch 0–11; its spelling adapts to the scale type (C# minor, but Db major).
    var rootSemitone = 9
    var scaleType: ScaleType = .minorPentatonic
    var tuning: Tuning = .standard
    var labelMode: LabelMode = .noteNames
    let fretCount = 22

    var root: PitchClass { Scale.conventionalRoot(forSemitone: rootSemitone, type: scaleType) }
    var scale: Scale { Scale(root: root, type: scaleType) }
    var fretboard: Fretboard { Fretboard(tuning: tuning, fretCount: fretCount) }
    var positions: [ScalePosition] { fretboard.positions(in: scale) }

    /// Root names for the picker, spelled for the current scale type.
    func rootName(forSemitone semitone: Int) -> String {
        Scale.conventionalRoot(forSemitone: semitone, type: scaleType).unicodeName
    }

    func label(for position: ScalePosition) -> String {
        switch labelMode {
        case .noteNames: position.note.pitchClass.unicodeName
        case .degrees: String(position.degree)
        case .intervals: Self.intervalLabel(position.interval)
        }
    }

    /// "R", "♭3", "♯4", "5".
    static func intervalLabel(_ interval: Interval) -> String {
        interval == .perfectUnison
            ? "R"
            : interval.degreeName.replacingOccurrences(of: "b", with: "♭").replacingOccurrences(of: "#", with: "♯")
    }

    static let scaleTypeGroups: [(title: String, types: [ScaleType])] = [
        ("Major & Minor", [.major, .naturalMinor, .harmonicMinor, .melodicMinor]),
        ("Modes", ScaleType.modes),
        ("Pentatonic & Blues", [.majorPentatonic, .minorPentatonic, .blues]),
    ]
}
