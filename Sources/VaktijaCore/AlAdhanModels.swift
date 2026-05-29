import Foundation

public struct AlAdhanCalendarResponse: Decodable, Sendable {
    public let code: Int
    public let status: String
    public let data: [AlAdhanDay]
}

public struct AlAdhanDay: Decodable, Sendable {
    public let timings: AlAdhanTimings
    public let date: AlAdhanDate
    public let meta: AlAdhanMeta
}

public struct AlAdhanTimings: Decodable, Sendable {
    public let fajr: String
    public let sunrise: String
    public let dhuhr: String
    public let asr: String
    public let maghrib: String
    public let isha: String
    public let midnight: String
    public let lastThird: String

    private enum CodingKeys: String, CodingKey {
        case fajr = "Fajr"
        case sunrise = "Sunrise"
        case dhuhr = "Dhuhr"
        case asr = "Asr"
        case maghrib = "Maghrib"
        case isha = "Isha"
        case midnight = "Midnight"
        case lastThird = "Lastthird"
    }
}

public struct AlAdhanDate: Decodable, Sendable {
    public let gregorian: AlAdhanGregorianDate
}

public struct AlAdhanGregorianDate: Decodable, Sendable {
    public let date: String
    public let day: String
    public let month: AlAdhanGregorianMonth
    public let year: String
}

public struct AlAdhanGregorianMonth: Decodable, Sendable {
    public let number: Int
}

public struct AlAdhanMeta: Decodable, Sendable {
    public let timezone: String
}
