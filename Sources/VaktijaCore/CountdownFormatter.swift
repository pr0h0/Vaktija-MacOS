import Foundation

public enum CountdownFormatter {
    public static func full(duration: TimeInterval) -> String {
        let totalSeconds = max(0, Int(duration.rounded(.down)))
        let hours = totalSeconds / 3_600
        let minutes = (totalSeconds % 3_600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    public static func compact(event: PrayerEvent, duration: TimeInterval) -> String {
        compact(name: event.displayName, duration: duration)
    }

    public static func compact(name: String, duration: TimeInterval) -> String {
        let totalMinutes = max(0, Int(duration.rounded(.down)) / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 {
            return String(format: "%@ %dh %02dm", name, hours, minutes)
        }

        return "\(name) \(minutes)m"
    }
}
