import SwiftUI

struct ComputerDebugView: View {
    @State private var seedText = "0"
    @State private var scene = ComputerScene.load(seed: 0)
    @State private var entryError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Computer match")
                .font(.headline)
            HStack {
                TextField("Seed", text: $seedText)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button("Deal") {
                    let (next, error) = ComputerScene.load(seedText: seedText, keeping: scene)
                    scene = next
                    entryError = error
                }
            }
            if let message = entryError {
                Text(message)
                    .foregroundStyle(.red)
            }
            Text(scene.matchStatus)
            Text("Your match total: \(scene.yourMatchTotal)")
            Text("Computer match total: \(scene.computerMatchTotal)")
            Text(scene.status)
            Text(scene.lastPlay)
            Text("Stock: \(scene.stockCount)")
            Text("Discard, bottom to top")
                .font(.headline)
            lines(scene.discard)
            Text("Your hand")
                .font(.headline)
            lines(scene.yourHand)
            Text("Computer hand")
                .font(.headline)
            lines(scene.computerHand)
            Text("Table")
                .font(.headline)
            lines(scene.melds)
            if let yourScore = scene.yourHandScore, let computerScore = scene.computerHandScore {
                Text("Your hand score: \(yourScore)")
                Text("Computer hand score: \(computerScore)")
            }
            Text("This hand")
                .font(.headline)
            lines(scene.plays)
            Button("Next move") {
                scene = scene.steppingForward()
            }
            .disabled(!scene.canStep)
            Button("Auto-play") {
                scene = scene.autoplaying()
            }
            .disabled(!scene.canStep)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func lines(_ names: [String]) -> some View {
        Group {
            if names.isEmpty {
                Text("None")
            } else {
                ForEach(Array(names.enumerated()), id: \.offset) { _, name in
                    Text(name)
                }
            }
        }
    }
}
