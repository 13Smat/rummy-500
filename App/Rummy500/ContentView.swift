import SwiftUI

struct ContentView: View {
    private let session: TableSession

    init(session: TableSession = TableLaunch.session()) {
        self.session = session
    }

    var body: some View {
        NavigationStack {
            TablePage(session: session)
                .toolbar(.hidden, for: .navigationBar)
        }
    }
}

struct TablePage: View {
    private let session: TableSession

    init(session: TableSession) {
        self.session = session
    }

    init(preset: TablePreset, playsLive: Bool) {
        self.init(session: TableSession(preset: preset, playsLive: playsLive))
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Rummy 500")
                        .font(.headline)
                    Text("You against the computer")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }
                Spacer()
                #if DEBUG
                NavigationLink("Debug") {
                    DealDebugView()
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .background(.background)
                        .navigationTitle("Debug")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar(.visible, for: .navigationBar)
                }
                .font(.subheadline.weight(.semibold))
                #endif
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.top, 2)
            .padding(.bottom, 4)
            TableScreen(session: session)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(TableChrome.background.ignoresSafeArea())
    }
}
