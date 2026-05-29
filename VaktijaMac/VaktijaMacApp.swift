import SwiftUI

@main
struct VaktijaMacApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView()
                .environmentObject(appState)
        } label: {
            switch appState.menuBarDisplayMode {
            case .iconOnly:
                Image(systemName: "moon.stars")
            case .fullCountdown:
                Text(appState.fullMenuBarTitle)
            case .compactCountdown:
                Text(appState.compactMenuBarTitle)
            }
        }
        .menuBarExtraStyle(.window)
    }
}
