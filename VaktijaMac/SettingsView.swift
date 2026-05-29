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

            Toggle("Notifications", isOn: $appState.notificationsEnabled)

            Stepper(value: $appState.reminderOffsetMinutes, in: 1...180, step: 5) {
                Text("Reminder: \(appState.reminderOffsetMinutes)m before")
            }
            .disabled(!appState.notificationsEnabled)

            Text("Permission: \(appState.notificationPermissionStatus)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
