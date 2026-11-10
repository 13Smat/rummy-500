import SwiftUI

struct DealDebugView: View {
    @State private var seedText = "0"
    @State private var scene = DealScene.load(seed: 0)
    @State private var entryError: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    TextField("Seed", text: $seedText)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Button("Deal") {
                        let (next, error) = DealScene.load(seedText: seedText, keeping: scene)
                        scene = next
                        entryError = error
                    }
                }
                if let message = entryError {
                    Text(message)
                        .foregroundStyle(.red)
                }
                Text("Dealer: \(scene.dealerName)")
                Text("First turn: \(scene.leaderName)")
                Text("Your hand")
                    .font(.headline)
                cardList(scene.yourHand)
                Text("Largest legal melds")
                    .font(.headline)
                if scene.yourMelds.isEmpty {
                    Text("None")
                } else {
                    cardList(scene.yourMelds)
                }
                Text("Computer hand")
                    .font(.headline)
                cardList(scene.computerHand)
                Text("Largest legal melds")
                    .font(.headline)
                if scene.computerMelds.isEmpty {
                    Text("None")
                } else {
                    cardList(scene.computerMelds)
                }
                Text("Stock: \(scene.stockCount)")
                Text("Discard")
                    .font(.headline)
                cardList(scene.discard)
                ScoreDebugView()
                    .padding(.top, 12)
                TurnDebugView()
                    .padding(.top, 12)
                ComputerDebugView()
                    .padding(.top, 12)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func cardList(_ names: [String]) -> some View {
        ForEach(Array(names.enumerated()), id: \.offset) { _, name in
            Text(name)
        }
    }
}
