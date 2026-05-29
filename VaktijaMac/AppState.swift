import Foundation
import VaktijaCore

enum MenuBarDisplayMode: String, CaseIterable, Identifiable {
    case iconOnly
    case fullCountdown
    case compactCountdown

    var id: String { rawValue }

    var title: String {
        switch self {
        case .iconOnly: "Icon Only"
        case .fullCountdown: "Full Countdown"
        case .compactCountdown: "Compact Countdown"
        }
    }
}

@MainActor
final class AppState: ObservableObject {
    @Published var menuBarDisplayMode: MenuBarDisplayMode = .iconOnly
    @Published var notificationsEnabled = false
    @Published var reminderOffsetMinutes = 45
    @Published var notificationPermissionStatus = "Not Requested"

    var fullMenuBarTitle: String {
        "Asr: 00:43:33"
    }

    var compactMenuBarTitle: String {
        "Asr 43m"
    }

    let location = PrayerLocation.sarajevo
    let sourceLabel = "AlAdhan 14.6°"
}
