import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Rummy 500")
                .font(.largeTitle)
            Text("You against the computer")
                .foregroundStyle(.secondary)
            #if DEBUG
            DealDebugView()
            #endif
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
