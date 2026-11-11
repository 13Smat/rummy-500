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
        TableScreen(session: session)
            .navigationTitle("Rummy 500")
            .toolbar(.hidden, for: .navigationBar)
            .accessibilityHint("You against the computer")
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
