import SwiftUI

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

            Toggle("Notifications", isOn: $appState.notificationsEnabled)

            Stepper(value: $appState.reminderOffsetMinutes, in: 1...180, step: 5) {
                Text("Reminder: \(appState.reminderOffsetMinutes)m before")
            }
            .disabled(!appState.notificationsEnabled)

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
