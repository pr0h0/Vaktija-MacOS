import Foundation

public struct PrayerLocation: Codable, Equatable, Sendable {
    public let slug: String
    public let name: String
    public let latitude: Double
    public let longitude: Double
    public let timeZoneIdentifier: String

    public init(
        slug: String,
        name: String,
        latitude: Double,
        longitude: Double,
        timeZoneIdentifier: String
    ) {
        self.slug = slug
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.timeZoneIdentifier = timeZoneIdentifier
    }

    public static let sarajevo = PrayerLocation(
        slug: "sarajevo",
        name: "Sarajevo",
        latitude: 43.84864,
        longitude: 18.35644,
        timeZoneIdentifier: "Europe/Sarajevo"
    )
}
