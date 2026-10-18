import SwiftUI

/// The scale name and its notes as colored chips, with each note's interval underneath.
struct ScaleSummaryView: View {
    let scale: Scale

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(scale.root.unicodeName) \(scale.type.name)")
                .font(.title2.weight(.semibold))
            HStack(spacing: 8) {
                ForEach(Array(zip(scale.pitchClasses, scale.type.intervals)), id: \.0) { pitchClass, interval in
                    VStack(spacing: 4) {
                        Text(pitchClass.unicodeName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 34, height: 34)
                            .background(Circle().fill(DegreeColors.color(for: interval)))
                        Text(FretboardViewModel.intervalLabel(interval))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }
}

#Preview {
    ScaleSummaryView(scale: Scale(root: .f, type: .major))
        .padding()
}
