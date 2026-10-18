/// The open-string notes of a fretted instrument, lowest string first.
nonisolated struct Tuning: Hashable, Sendable, Identifiable {
    static let stringCountRange = 4...8

    let name: String
    /// Open-string notes; index 0 is the lowest-pitched string.
    let openStrings: [Note]

    /// Fails unless there are 4–8 strings.
    init?(name: String, openStrings: [Note]) {
        guard Self.stringCountRange.contains(openStrings.count) else { return nil }
        self.name = name
        self.openStrings = openStrings
    }

    /// Convenience for presets, e.g. `Tuning(name: "Drop D", "D2 A2 D3 G3 B3 E4")`.
    init?(name: String, _ notes: String) {
        let parsed = notes.split(separator: " ").map { Note(String($0)) }
        guard !parsed.contains(nil) else { return nil }
        self.init(name: name, openStrings: parsed.compactMap { $0 })
    }

    var id: String { name + ":" + openStrings.map(\.name).joined(separator: ",") }

    var stringCount: Int { openStrings.count }

    /// "E A D G B E"
    var noteNames: String { openStrings.map(\.pitchClass.name).joined(separator: " ") }

    static let standard = Tuning(name: "Standard", "E2 A2 D3 G3 B3 E4")!
    static let halfStepDown = Tuning(name: "Half-step down", "Eb2 Ab2 Db3 Gb3 Bb3 Eb4")!
    static let dropD = Tuning(name: "Drop D", "D2 A2 D3 G3 B3 E4")!
    static let dadgad = Tuning(name: "DADGAD", "D2 A2 D3 G3 A3 D4")!
    static let openG = Tuning(name: "Open G", "D2 G2 D3 G3 B3 D4")!
    static let openD = Tuning(name: "Open D", "D2 A2 D3 F#3 A3 D4")!

    static let presets: [Tuning] = [.standard, .halfStepDown, .dropD, .dadgad, .openG, .openD]
}
