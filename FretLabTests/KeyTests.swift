import Testing
@testable import FretLab

func key(_ tonic: String, _ mode: Key.Mode) -> Key {
    guard let key = Key(pc(tonic), mode) else { fatalError("Bad key fixture: \(tonic) \(mode)") }
    return key
}

private let majorSignatures: [(String, Int)] = [
    ("C", 0), ("G", 1), ("D", 2), ("A", 3), ("E", 4), ("B", 5), ("F#", 6), ("C#", 7),
    ("F", -1), ("Bb", -2), ("Eb", -3), ("Ab", -4), ("Db", -5), ("Gb", -6), ("Cb", -7),
]

private let minorSignatures: [(String, Int)] = [
    ("A", 0), ("E", 1), ("B", 2), ("F#", 3), ("C#", 4), ("G#", 5), ("D#", 6), ("A#", 7),
    ("D", -1), ("G", -2), ("C", -3), ("F", -4), ("Bb", -5), ("Eb", -6), ("Ab", -7),
]

private let allKeys: [Key] =
    majorSignatures.map { key($0.0, .major) } + minorSignatures.map { key($0.0, .minor) }

@Suite("Key signatures")
struct KeySignatureTests {
    @Test(arguments: majorSignatures)
    func majorKeys(tonic: String, fifths: Int) throws {
        let key = try #require(Key(pc(tonic), .major))
        #expect(key.fifths == fifths)
        #expect(Key(fifths: fifths, mode: .major) == key)
    }

    @Test(arguments: minorSignatures)
    func minorKeys(tonic: String, fifths: Int) throws {
        let key = try #require(Key(pc(tonic), .minor))
        #expect(key.fifths == fifths)
        #expect(Key(fifths: fifths, mode: .minor) == key)
    }

    @Test(arguments: [("G#", Key.Mode.major), ("D#", .major), ("A#", .major), ("Fb", .major), ("E#", .major),
                      ("Db", .minor), ("Gb", .minor), ("Cb", .minor), ("E#", .minor)])
    func theoreticalKeysAreRejected(tonic: String, mode: Key.Mode) {
        #expect(Key(pc(tonic), mode) == nil)
    }

    @Test func fifthsOutOfRangeAreRejected() {
        #expect(Key(fifths: 8, mode: .major) == nil)
        #expect(Key(fifths: -8, mode: .minor) == nil)
    }

    @Test func accidentalsInWrittenOrder() {
        #expect(key("D", .major).signature.accidentals.map(\.name) == ["F#", "C#"])
        #expect(key("Eb", .major).signature.accidentals.map(\.name) == ["Bb", "Eb", "Ab"])
        #expect(key("C#", .major).signature.accidentals.map(\.name) == ["F#", "C#", "G#", "D#", "A#", "E#", "B#"])
        #expect(key("Cb", .major).signature.accidentals.map(\.name) == ["Bb", "Eb", "Ab", "Db", "Gb", "Cb", "Fb"])
        #expect(key("A", .minor).signature.accidentals.isEmpty)
        #expect(key("G", .minor).signature.accidentals.map(\.name) == ["Bb", "Eb"])
    }

    @Test func counts() {
        let fSharpMajor = key("F#", .major).signature
        #expect(fSharpMajor.sharpCount == 6)
        #expect(fSharpMajor.flatCount == 0)
        let fMinor = key("F", .minor).signature
        #expect(fMinor.sharpCount == 0)
        #expect(fMinor.flatCount == 4)
    }

    @Test func accidentalForLetter() {
        let signature = key("Bb", .major).signature
        #expect(signature.accidental(for: .b) == .flat)
        #expect(signature.accidental(for: .e) == .flat)
        #expect(signature.accidental(for: .a) == .natural)
    }

    @Test func summary() {
        #expect(KeySignature(fifths: 0).summary == "no sharps or flats")
        #expect(KeySignature(fifths: 1).summary == "1 sharp")
        #expect(KeySignature(fifths: 3).summary == "3 sharps")
        #expect(KeySignature(fifths: -1).summary == "1 flat")
        #expect(KeySignature(fifths: -6).summary == "6 flats")
    }

    /// The signature must name exactly the altered notes of the key's scale.
    @Test(arguments: allKeys)
    func signatureMatchesScale(key: Key) {
        let altered = key.scale.pitchClasses.filter { $0.accidental != .natural }
        #expect(Set(altered) == Set(key.signature.accidentals))
    }

    @Test func names() {
        #expect(key("Bb", .major).name == "Bb major")
        #expect(key("F#", .minor).name == "F# minor")
    }
}

@Suite("Related keys")
struct RelatedKeyTests {
    @Test(arguments: [("C", "A"), ("G", "E"), ("F", "D"), ("Eb", "C"), ("F#", "D#"), ("Gb", "Eb"), ("C#", "A#"), ("Cb", "Ab")])
    func relativeMinor(major: String, minor: String) {
        #expect(key(major, .major).relative == key(minor, .minor))
        #expect(key(minor, .minor).relative == key(major, .major))
    }

    @Test(arguments: allKeys)
    func relativeIsAnInvolutionSharingTheSignature(key: Key) {
        #expect(key.relative.relative == key)
        #expect(key.relative.signature == key.signature)
        #expect(key.relative.mode != key.mode)
    }

    @Test func parallel() {
        #expect(key("C", .major).parallel == key("C", .minor))
        #expect(key("A", .minor).parallel == key("A", .major))
        #expect(key("C#", .major).parallel == key("C#", .minor))
        #expect(key("Ab", .minor).parallel == key("Ab", .major))
        // Respelled when the literal parallel is theoretical
        #expect(key("Gb", .major).parallel == key("F#", .minor))
        #expect(key("A#", .minor).parallel == key("Bb", .major))
        #expect(key("D#", .minor).parallel == key("Eb", .major))
    }

    @Test(arguments: allKeys)
    func parallelSharesTonicPitch(key: Key) {
        #expect(key.parallel.tonic.isEnharmonic(with: key.tonic))
        #expect(key.parallel.mode != key.mode)
    }

    @Test func dominantAndSubdominant() {
        #expect(key("C", .major).dominant == key("G", .major))
        #expect(key("C", .major).subdominant == key("F", .major))
        #expect(key("F#", .major).dominant == key("C#", .major))
        #expect(key("Gb", .major).subdominant == key("Cb", .major))
        #expect(key("A", .minor).dominant == key("E", .minor))
        #expect(key("A", .minor).subdominant == key("D", .minor))
        // Wrapping past the edge of the standard keys
        #expect(key("C#", .major).dominant == key("Ab", .major))
        #expect(key("Cb", .major).subdominant == key("E", .major))
        #expect(key("A#", .minor).dominant == key("F", .minor))
    }

    @Test(arguments: allKeys)
    func dominantAndSubdominantAreInverses(key: Key) {
        #expect(key.dominant.subdominant.tonic.isEnharmonic(with: key.tonic))
        #expect(key.subdominant.dominant.tonic.isEnharmonic(with: key.tonic))
        #expect(key.dominant.tonic.isEnharmonic(with: key.tonic.transposed(by: .perfectFifth)))
        #expect(key.subdominant.tonic.isEnharmonic(with: key.tonic.transposed(by: .perfectFourth)))
    }

    @Test func neighbors() {
        #expect(key("C", .major).neighbors == [key("F", .major), key("G", .major)])
        #expect(key("E", .minor).neighbors == [key("A", .minor), key("B", .minor)])
    }

    @Test func closelyRelated() {
        #expect(Set(key("C", .major).closelyRelated) ==
                [key("F", .major), key("G", .major), key("A", .minor), key("D", .minor), key("E", .minor)])
        #expect(Set(key("A", .minor).closelyRelated) ==
                [key("D", .minor), key("E", .minor), key("C", .major), key("F", .major), key("G", .major)])
        #expect(Set(key("D", .major).closelyRelated) ==
                [key("G", .major), key("A", .major), key("B", .minor), key("E", .minor), key("F#", .minor)])
    }

    @Test func enharmonicEquivalent() {
        #expect(key("F#", .major).enharmonicEquivalent == key("Gb", .major))
        #expect(key("Gb", .major).enharmonicEquivalent == key("F#", .major))
        #expect(key("C#", .major).enharmonicEquivalent == key("Db", .major))
        #expect(key("B", .major).enharmonicEquivalent == key("Cb", .major))
        #expect(key("Eb", .minor).enharmonicEquivalent == key("D#", .minor))
        #expect(key("C", .major).enharmonicEquivalent == nil)
        #expect(key("D", .major).enharmonicEquivalent == nil)
    }
}

@Suite("Circle of fifths")
struct CircleOfFifthsTests {
    @Test func majorKeysClockwise() {
        #expect(CircleOfFifths.majorKeys.map(\.tonic.name) == ["C", "G", "D", "A", "E", "B", "F#", "Db", "Ab", "Eb", "Bb", "F"])
        #expect(CircleOfFifths.majorKeys.allSatisfy { $0.mode == .major })
    }

    @Test func minorKeysClockwise() {
        #expect(CircleOfFifths.minorKeys.map(\.tonic.name) == ["A", "E", "B", "F#", "C#", "G#", "D#", "Bb", "F", "C", "G", "D"])
        #expect(zip(CircleOfFifths.majorKeys, CircleOfFifths.minorKeys).allSatisfy { $0.relative == $1 })
    }

    @Test func positions() {
        #expect(CircleOfFifths.position(of: key("C", .major)) == 0)
        #expect(CircleOfFifths.position(of: key("A", .minor)) == 0)
        #expect(CircleOfFifths.position(of: key("F", .major)) == 11)
        #expect(CircleOfFifths.position(of: key("F#", .major)) == 6)
        #expect(CircleOfFifths.position(of: key("Gb", .major)) == 6)
        #expect(CircleOfFifths.position(of: key("Cb", .major)) == 5)
        for (index, key) in CircleOfFifths.majorKeys.enumerated() {
            #expect(CircleOfFifths.position(of: key) == index)
        }
    }

    @Test func keyAtPositionWraps() {
        #expect(CircleOfFifths.key(atPosition: 1, mode: .major) == key("G", .major))
        #expect(CircleOfFifths.key(atPosition: 13, mode: .major) == key("G", .major))
        #expect(CircleOfFifths.key(atPosition: -1, mode: .minor) == key("D", .minor))
    }

    @Test func distance() {
        #expect(CircleOfFifths.distance(from: key("C", .major), to: key("C", .major)) == 0)
        #expect(CircleOfFifths.distance(from: key("C", .major), to: key("F", .major)) == 1)
        #expect(CircleOfFifths.distance(from: key("C", .major), to: key("Bb", .major)) == 2)
        #expect(CircleOfFifths.distance(from: key("C", .major), to: key("F#", .major)) == 6)
        #expect(CircleOfFifths.distance(from: key("G", .major), to: key("Eb", .major)) == 4)
        #expect(CircleOfFifths.distance(from: key("C", .major), to: key("E", .minor)) == 1)
    }

    @Test func walkingClockwiseReturnsHome() {
        var current = key("C", .major)
        var visited: [Int] = []
        for _ in 0..<12 {
            current = current.dominant
            visited.append(CircleOfFifths.position(of: current))
        }
        #expect(current == key("C", .major))
        #expect(Set(visited).count == 12)
    }
}
