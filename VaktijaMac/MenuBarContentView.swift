import SwiftUI
import VaktijaCore
import AppKit

struct MenuBarContentView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Next")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(appState.nextTarget.map { appState.displayName(for: $0.event, on: $0.date) } ?? "Unavailable")
                        .font(.title2.weight(.semibold))
                }
                Spacer()
                Text(appState.nextTarget.map { CountdownFormatter.full(duration: $0.duration) } ?? "--:--:--")
                    .font(.system(.title3, design: .monospaced).weight(.medium))
            }

            Divider()

            VStack(spacing: 8) {
                ForEach(PrayerEvent.countdownEvents, id: \.self) { event in
                    PrayerRow(name: appState.displayName(for: event), time: appState.displayTime(appState.today?.time(for: event)))
                }
            }

            Divider()

            PrayerRow(name: "Pola noći", time: appState.displayTime(appState.today?.time(for: .midnight)))
            PrayerRow(name: "Zadnja trećina", time: appState.displayTime(appState.today?.time(for: .lastThird)))

            Divider()

            SettingsView()

            Divider()

            Button {
                NSApp.terminate(nil)
            } label: {
                Label("Quit Vaktija", systemImage: "power")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
        }
        .padding(20)
        .frame(width: 360)
    }
}

private struct PrayerRow: View {
    let name: String
    let time: String

    var body: some View {
        HStack {
            Text(name)
            Spacer()
            Text(time)
                .font(.system(.body, design: .monospaced))
        }
    }
}
