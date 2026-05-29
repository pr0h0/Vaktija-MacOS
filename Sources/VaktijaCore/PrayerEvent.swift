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

    public var displayName: String {
        switch self {
        case .fajr: "Sabah"
        case .sunrise: "Izlazak"
        case .dhuhr: "Podne"
        case .asr: "Ikindija"
        case .maghrib: "Akšam"
        case .isha: "Jacija"
        case .midnight: "Pola noći"
        case .lastThird: "Zadnja trećina"
        }
    }
}
