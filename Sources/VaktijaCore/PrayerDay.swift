import Foundation

public struct PrayerTime: Codable, Equatable, Sendable {
    public let event: PrayerEvent
    public let time: DateComponents

    public init(event: PrayerEvent, time: DateComponents) {
        self.event = event
        self.time = time
    }
}

public struct PrayerDay: Codable, Equatable, Sendable {
    public let date: Date
    public let locationName: String
    public let timeZoneIdentifier: String
    public let times: [PrayerTime]

    public init(
        date: Date,
        locationName: String,
        timeZoneIdentifier: String,
        times: [PrayerTime]
    ) {
        self.date = date
        self.locationName = locationName
        self.timeZoneIdentifier = timeZoneIdentifier
        self.times = times
    }

    public func time(for event: PrayerEvent) -> DateComponents? {
        times.first { $0.event == event }?.time
    }
}
