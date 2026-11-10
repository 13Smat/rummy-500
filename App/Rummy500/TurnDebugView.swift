import SwiftUI

struct TurnDebugView: View {
    @State private var scene = TurnScene.opening

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Scripted hand")
                .font(.headline)
            Text(scene.status)
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
            if let yourScore = scene.yourScore, let computerScore = scene.computerScore {
                Text("Your hand score: \(yourScore)")
                Text("Computer hand score: \(computerScore)")
            }
            if let yourTotal = scene.yourMatchTotal, let computerTotal = scene.computerMatchTotal {
                Text("Your match total: \(yourTotal)")
                Text("Computer match total: \(computerTotal)")
            }
            Button("Next") {
                scene = scene.steppingForward()
            }
            .disabled(!scene.hasAnotherStep)
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
