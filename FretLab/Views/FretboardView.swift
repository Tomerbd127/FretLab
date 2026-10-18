import SwiftUI

/// A drawn guitar neck with scale tones marked on it. Scrolls horizontally when the window is narrow.
struct FretboardView: View {
    let fretboard: Fretboard
    let positions: [ScalePosition]
    let label: (ScalePosition) -> String

    var body: some View {
        GeometryReader { geometry in
            ScrollView(.horizontal) {
                FretboardCanvas(
                    fretboard: fretboard, positions: positions, label: label,
                    width: max(geometry.size.width, FretboardLayout.minimumWidth(fretCount: fretboard.fretCount))
                )
            }
        }
        .frame(height: FretboardCanvas.height(for: fretboard))
    }
}

/// The neck drawing at a fixed width.
struct FretboardCanvas: View {
    let fretboard: Fretboard
    let positions: [ScalePosition]
    let label: (ScalePosition) -> String
    let width: CGFloat

    static func height(for fretboard: Fretboard) -> CGFloat {
        FretboardLayout(fretCount: fretboard.fretCount, stringCount: fretboard.stringCount, width: 0).height
    }

    var body: some View {
        Canvas { context, size in
            let layout = FretboardLayout(fretCount: fretboard.fretCount,
                                         stringCount: fretboard.stringCount,
                                         width: size.width)
            drawNeck(in: &context, layout: layout)
            drawMarkers(in: &context, layout: layout)
        }
        .frame(width: width, height: Self.height(for: fretboard))
        .accessibilityElement()
        .accessibilityLabel("Fretboard")
        .accessibilityValue(positions.isEmpty ? "No notes" : "\(positions.count) scale tones marked")
    }

    // MARK: - Drawing

    private static let wood = Color(red: 0.33, green: 0.21, blue: 0.14)
    private static let fretWire = Color(white: 0.78)
    private static let nut = Color(red: 0.94, green: 0.91, blue: 0.83)
    private static let inlay = Color(white: 0.92, opacity: 0.85)
    private static let string = Color(red: 0.86, green: 0.83, blue: 0.74)

    private func drawNeck(in context: inout GraphicsContext, layout: FretboardLayout) {
        // The wood runs a little past the last fret, as on a real neck.
        let neck = CGRect(x: layout.nutX, y: layout.neckTop,
                          width: layout.neckEndX - layout.nutX + FretboardLayout.neckOverhang,
                          height: layout.neckBottom - layout.neckTop)
        context.fill(Path(roundedRect: neck, cornerRadius: 3), with: .color(Self.wood))

        // Inlays: single dots in the middle, double dots one string spacing either side (between strings).
        let midY = (layout.neckTop + layout.neckBottom) / 2
        for fret in 1...fretboard.fretCount {
            let x = layout.markerX(fret: fret)
            if FretboardLayout.singleInlayFrets.contains(fret) {
                context.fill(Self.dot(at: CGPoint(x: x, y: midY), diameter: 12), with: .color(Self.inlay))
            } else if FretboardLayout.doubleInlayFrets.contains(fret) {
                for y in [midY - FretboardLayout.stringSpacing, midY + FretboardLayout.stringSpacing] {
                    context.fill(Self.dot(at: CGPoint(x: x, y: y), diameter: 12), with: .color(Self.inlay))
                }
            }
        }

        // Fret wires and nut
        for fret in 1...fretboard.fretCount {
            let x = layout.fretWireX(fret)
            context.stroke(Self.line(x: x, from: layout.neckTop, to: layout.neckBottom),
                           with: .color(Self.fretWire), lineWidth: 2)
        }
        context.fill(Path(CGRect(x: layout.nutX - 3, y: layout.neckTop, width: 6, height: neck.height)),
                     with: .color(Self.nut))

        // Strings: thicker toward the bass, extending into the open-string zone.
        let count = fretboard.stringCount
        for string in 0..<count {
            let y = layout.stringY(string)
            let thickness = 1 + 2.2 * CGFloat(count - 1 - string) / CGFloat(max(count - 1, 1))
            var path = Path()
            path.move(to: CGPoint(x: FretboardLayout.leadingMargin, y: y))
            path.addLine(to: CGPoint(x: layout.neckEndX + FretboardLayout.neckOverhang, y: y))
            context.stroke(path, with: .color(Self.string), lineWidth: thickness)
        }

        // Fret numbers under the inlays
        let numbered = FretboardLayout.singleInlayFrets.union(FretboardLayout.doubleInlayFrets)
        for fret in numbered where fret <= fretboard.fretCount {
            let text = Text("\(fret)").font(.caption).foregroundStyle(.secondary)
            context.draw(text, at: CGPoint(x: layout.markerX(fret: fret), y: layout.neckBottom + 14))
        }
    }

    private func drawMarkers(in context: inout GraphicsContext, layout: FretboardLayout) {
        for position in positions {
            let center = CGPoint(x: layout.markerX(fret: position.position.fret),
                                 y: layout.stringY(position.position.string))
            let circle = Self.dot(at: center, diameter: FretboardLayout.markerDiameter)
            context.fill(circle, with: .color(DegreeColors.color(for: position.interval)))
            context.stroke(circle, with: .color(.white.opacity(position.isRoot ? 1 : 0.7)),
                           lineWidth: position.isRoot ? 2.5 : 1.5)
            let text = Text(label(position))
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
            context.draw(text, at: center)
        }
    }

    private static func dot(at center: CGPoint, diameter: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: center.x - diameter / 2, y: center.y - diameter / 2,
                               width: diameter, height: diameter))
    }

    private static func line(x: CGFloat, from top: CGFloat, to bottom: CGFloat) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: x, y: top))
        path.addLine(to: CGPoint(x: x, y: bottom))
        return path
    }
}

#Preview {
    let board = Fretboard()
    FretboardView(fretboard: board, positions: board.positions(in: Scale(root: .a, type: .minorPentatonic))) {
        $0.note.pitchClass.unicodeName
    }
    .padding()
}
