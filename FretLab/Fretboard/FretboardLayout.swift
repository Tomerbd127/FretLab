import Foundation

/// Geometry for drawing a fretboard: where fret wires, strings and note markers go.
///
/// Fret wires follow the equal-temperament rule (each fret is 2^(-1/12) the width of the previous one),
/// scaled so the last fret wire lands at the trailing edge. The highest string is drawn on top, as in tab.
nonisolated struct FretboardLayout {
    static let stringSpacing: CGFloat = 40
    static let markerDiameter: CGFloat = 28
    static let minimumFretWidth: CGFloat = 36
    /// Space left of the nut where open-string markers sit.
    static let openStringZone: CGFloat = 44
    static let leadingMargin: CGFloat = 8
    /// Wood drawn past the last fret wire.
    static let neckOverhang: CGFloat = 14
    static let trailingMargin: CGFloat = 16 + neckOverhang
    static let topMargin: CGFloat = 24
    /// Room under the neck for fret numbers.
    static let bottomMargin: CGFloat = 36

    static let singleInlayFrets: Set<Int> = [3, 5, 7, 9, 15, 17, 19, 21]
    static let doubleInlayFrets: Set<Int> = [12, 24]

    let fretCount: Int
    let stringCount: Int
    let width: CGFloat

    var nutX: CGFloat { Self.leadingMargin + Self.openStringZone }
    var neckEndX: CGFloat { width - Self.trailingMargin }

    /// The wood extends half a string spacing beyond the outer strings.
    var neckTop: CGFloat { stringY(stringCount - 1) - Self.stringSpacing / 2 }
    var neckBottom: CGFloat { stringY(0) + Self.stringSpacing / 2 }

    var height: CGFloat {
        Self.topMargin + CGFloat(stringCount - 1) * Self.stringSpacing + Self.bottomMargin
    }

    /// x of fret wire `n`; wire 0 is the nut.
    func fretWireX(_ n: Int) -> CGFloat {
        nutX + (neckEndX - nutX) * Self.distanceRatio(n) / Self.distanceRatio(fretCount)
    }

    /// Width of the space for fret `n` (between wires n−1 and n), n ≥ 1.
    func fretWidth(_ n: Int) -> CGFloat {
        fretWireX(n) - fretWireX(n - 1)
    }

    /// Center x of a note marker: in the open-string zone for fret 0, otherwise mid-fret.
    func markerX(fret: Int) -> CGFloat {
        fret == 0 ? nutX - Self.openStringZone / 2 : (fretWireX(fret - 1) + fretWireX(fret)) / 2
    }

    /// y of a string; string 0 (lowest pitch) is at the bottom.
    func stringY(_ string: Int) -> CGFloat {
        Self.topMargin + CGFloat(stringCount - 1 - string) * Self.stringSpacing
    }

    /// Narrowest width that keeps the highest fret at least `minimumFretWidth` wide.
    static func minimumWidth(fretCount: Int) -> CGFloat {
        let lastFretRatio = distanceRatio(fretCount) - distanceRatio(fretCount - 1)
        let neckLength = minimumFretWidth * distanceRatio(fretCount) / lastFretRatio
        return (leadingMargin + openStringZone + neckLength + trailingMargin).rounded(.up)
    }

    /// Distance from the nut to fret wire n, as a fraction of the scale length.
    private static func distanceRatio(_ n: Int) -> CGFloat {
        1 - pow(2, -CGFloat(n) / 12)
    }
}
