import SwiftUI

struct ScoreDebugView: View {
    @State private var scene = ScoreScene.opening

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sample score")
                .font(.headline)
            Text("First to 500")
            if let score = scene.lastScore {
                Text("Your hand score: \(score.you)")
                Text("Computer hand score: \(score.computer)")
            }
            Text("Your match total: \(scene.match.you)")
            Text("Computer match total: \(scene.match.computer)")
            Text(scene.statusLine)
            Button("Score next hand") {
                scene = scene.scoringNextHand()
            }
            .disabled(!scene.hasAnotherHand)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
