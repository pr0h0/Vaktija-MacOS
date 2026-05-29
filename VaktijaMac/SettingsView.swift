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

            labeledValue("Shortcut", "⌘⌥P")

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

            Divider()

            Text("System")
                .font(.headline)

            launchAtLoginRow
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var cacheStatusRow: some View {
        HStack {
            Text("Cache")
                .foregroundStyle(.secondary)
            Spacer(minLength: 12)
            VStack(alignment: .trailing, spacing: 2) {
                Text(appState.cacheStatus)
                    .multilineTextAlignment(.trailing)
                Text(appState.cacheHealth)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
            }
            Button {
                Task { await appState.refreshFromCacheAndNetwork() }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .help("Refresh Cache")
            .accessibilityLabel("Refresh Cache")
        }
        .font(.caption)
    }

    private var launchAtLoginRow: some View {
        HStack {
            Toggle("Launch at Login", isOn: Binding(
                get: { appState.launchAtLoginEnabled },
                set: { appState.setLaunchAtLoginEnabled($0) }
            ))
            .toggleStyle(.checkbox)

            Spacer(minLength: 12)

            Text(appState.launchAtLoginStatus)
                .font(.caption)
                .foregroundStyle(.secondary)

            if appState.launchAtLoginStatus == "Needs approval" {
                Button {
                    appState.openLoginItemsSettings()
                } label: {
                    Image(systemName: "gear")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Open Login Items Settings")
                .accessibilityLabel("Open Login Items Settings")
            }
        }
    }

    private func notificationRow(for event: PrayerEvent) -> some View {
        let preference = appState.notificationPreference(for: event)
        return HStack(spacing: 8) {
            Toggle(appState.displayName(for: event), isOn: Binding(
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
