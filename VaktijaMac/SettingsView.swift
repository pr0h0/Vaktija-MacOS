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
            labeledValue("Cache", appState.cacheStatus)

            Button {
                Task { await appState.refreshFromCacheAndNetwork() }
            } label: {
                Label("Refresh Cache", systemImage: "arrow.clockwise")
            }

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
    }

    private func notificationRow(for event: PrayerEvent) -> some View {
        let preference = appState.notificationPreference(for: event)
        return HStack(spacing: 8) {
            Toggle(event.rawValue, isOn: Binding(
                get: { appState.notificationPreference(for: event).isEnabled },
                set: { appState.setNotificationEnabled($0, for: event) }
            ))
            .toggleStyle(.checkbox)
            .frame(width: 92, alignment: .leading)

            Stepper(value: Binding(
                get: { appState.notificationPreference(for: event).reminderOffsetMinutes },
                set: { appState.setReminderOffsetMinutes($0, for: event) }
            ), in: 1...180, step: 5) {
                Text("\(preference.reminderOffsetMinutes)m before")
                    .font(.caption)
                    .monospacedDigit()
                    .frame(width: 84, alignment: .trailing)
            }
            .disabled(!preference.isEnabled)
        }
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
