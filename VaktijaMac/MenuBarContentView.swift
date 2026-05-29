import SwiftUI
import VaktijaCore

struct MenuBarContentView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Next")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(appState.nextTarget?.event.rawValue ?? "Unavailable")
                        .font(.title2.weight(.semibold))
                }
                Spacer()
                Text(appState.nextTarget.map { CountdownFormatter.full(duration: $0.duration) } ?? "--:--:--")
                    .font(.system(.title3, design: .monospaced).weight(.medium))
            }

            Divider()

            VStack(spacing: 8) {
                ForEach(PrayerEvent.countdownEvents, id: \.self) { event in
                    PrayerRow(name: event.rawValue, time: appState.displayTime(appState.today?.time(for: event)))
                }
            }

            Divider()

            PrayerRow(name: "Pola noći", time: appState.displayTime(appState.today?.time(for: .midnight)))
            PrayerRow(name: "Zadnja trećina", time: appState.displayTime(appState.today?.time(for: .lastThird)))

            Divider()

            SettingsView()
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
