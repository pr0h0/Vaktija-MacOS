import SwiftUI
import VaktijaCore

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("Menu Bar", selection: $appState.menuBarDisplayMode) {
                ForEach(MenuBarDisplayMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }

            Divider()

            labeledValue("Location", appState.location.name)
            labeledValue("Source", appState.sourceLabel)
            cacheStatusRow

            Divider()

            Text("Notifications")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(PrayerEvent.countdownEvents, id: \.self) { event in
                    notificationRow(for: event)
                }
            }

            Text("Permission: \(appState.notificationPermissionStatus)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Schedule: \(appState.notificationScheduleStatus)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button {
                appState.openNotificationSettings()
            } label: {
                Label("Open Notification Settings", systemImage: "gear")
            }

            Button {
                appState.sendTestNotification()
            } label: {
                Label("Send Test Notification", systemImage: "bell.badge")
            }
        }
        .frame(width: 320, alignment: .leading)
    }

    private var cacheStatusRow: some View {
        HStack {
            Text("Cache")
                .foregroundStyle(.secondary)
            Spacer(minLength: 12)
            Text(appState.cacheStatus)
                .multilineTextAlignment(.trailing)
            Button {
                Task { await appState.refreshFromCacheAndNetwork() }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
            .help("Refresh Cache")
            .accessibilityLabel("Refresh Cache")
        }
        .font(.caption)
    }

    private func notificationRow(for event: PrayerEvent) -> some View {
        let preference = appState.notificationPreference(for: event)
        return HStack(spacing: 8) {
            Toggle(event.rawValue, isOn: Binding(
                get: { appState.notificationPreference(for: event).isEnabled },
                set: { appState.setNotificationEnabled($0, for: event) }
            ))
            .toggleStyle(.checkbox)
            .frame(minWidth: 92, alignment: .leading)

            Spacer(minLength: 12)

            Stepper(value: Binding(
                get: { appState.notificationPreference(for: event).reminderOffsetMinutes },
                set: { appState.setReminderOffsetMinutes(Self.roundedReminderOffset($0), for: event) }
            ), in: 1...180, step: 5) {
                Text("\(preference.reminderOffsetMinutes)m before")
                    .font(.caption)
                    .monospacedDigit()
                    .frame(width: 96, alignment: .trailing)
            }
            .disabled(!preference.isEnabled)
        }
        .frame(maxWidth: .infinity)
    }

    private static func roundedReminderOffset(_ minutes: Int) -> Int {
        if minutes <= 3 {
            return 1
        }

        return min(180, max(5, ((minutes + 2) / 5) * 5))
    }

    private func labeledValue(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer(minLength: 12)
            Text(value)
                .multilineTextAlignment(.trailing)
        }
        .font(.caption)
    }
}
