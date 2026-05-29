import Foundation

public enum PrayerEvent: String, Codable, CaseIterable, Sendable {
    case fajr = "Fajr"
    case sunrise = "Sunrise"
    case dhuhr = "Dhuhr"
    case asr = "Asr"
    case maghrib = "Maghrib"
    case isha = "Isha"
    case midnight = "Pola noći"
    case lastThird = "Zadnja trećina"

    public static let countdownEvents: [PrayerEvent] = [
        .fajr, .sunrise, .dhuhr, .asr, .maghrib, .isha
    ]
}
