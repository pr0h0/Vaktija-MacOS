import SwiftUI

struct MenuBarContentView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Next")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Asr")
                        .font(.title2.weight(.semibold))
                }
                Spacer()
                Text("00:43:33")
                    .font(.system(.title3, design: .monospaced).weight(.medium))
            }

            Divider()

            VStack(spacing: 8) {
                PrayerRow(name: "Fajr", time: "03:27")
                PrayerRow(name: "Sunrise", time: "05:09")
                PrayerRow(name: "Dhuhr", time: "12:44")
                PrayerRow(name: "Asr", time: "16:48")
                PrayerRow(name: "Maghrib", time: "20:19")
                PrayerRow(name: "Isha", time: "22:01")
            }

            Divider()

            PrayerRow(name: "Pola noći", time: "00:44")
            PrayerRow(name: "Zadnja trećina", time: "02:12")

            Divider()

            Text("\(appState.location.name) · \(appState.sourceLabel)")
                .font(.caption)
                .foregroundStyle(.secondary)

            SettingsView()
        }
        .padding(16)
        .frame(width: 320)
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
