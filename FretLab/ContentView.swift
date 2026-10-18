import SwiftUI

struct ContentView: View {
    @State private var model = FretboardViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            ScaleSummaryView(scale: model.scale)
            FretboardView(fretboard: model.fretboard, positions: model.positions, label: model.label(for:))
            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(minWidth: 820, minHeight: 380)
        .toolbar {
            ToolbarItemGroup {
                Picker("Root", selection: $model.rootSemitone) {
                    ForEach(0..<12, id: \.self) { semitone in
                        Text(model.rootName(forSemitone: semitone)).tag(semitone)
                    }
                }
                .help("Root note")

                Picker("Scale", selection: $model.scaleType) {
                    ForEach(FretboardViewModel.scaleTypeGroups, id: \.title) { group in
                        Section(group.title) {
                            ForEach(group.types, id: \.self) { type in
                                Text(type.name).tag(type)
                            }
                        }
                    }
                }
                .help("Scale type")

                Picker("Tuning", selection: $model.tuning) {
                    ForEach(Tuning.presets) { tuning in
                        Text("\(tuning.name) (\(tuning.noteNames))").tag(tuning)
                    }
                }
                .help("Tuning")

                Picker("Labels", selection: $model.labelMode) {
                    ForEach(LabelMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .help("What to show inside each note")
            }
        }
    }
}

#Preview {
    ContentView()
}

