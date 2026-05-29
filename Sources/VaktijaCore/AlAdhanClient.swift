import Foundation

public protocol PrayerCalendarFetching {
    func fetchMonth(location: PrayerLocation, year: Int, month: Int) async throws -> [PrayerDay]
}

public struct AlAdhanClient: PrayerCalendarFetching, Sendable {
    public let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func fetchMonth(location: PrayerLocation, year: Int, month: Int) async throws -> [PrayerDay] {
        let url = try calendarURL(location: location, year: year, month: month)
        let (data, _) = try await session.data(from: url)
        let response = try JSONDecoder().decode(AlAdhanCalendarResponse.self, from: data)
        return try PrayerScheduleMapper.map(response: response, locationName: location.name)
    }

    public func calendarURL(location: PrayerLocation, year: Int, month: Int) throws -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.aladhan.com"
        components.path = "/v1/calendar/\(year)/\(month)"
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(location.latitude)),
            URLQueryItem(name: "longitude", value: String(location.longitude)),
            URLQueryItem(name: "method", value: "99"),
            URLQueryItem(name: "methodSettings", value: "14.6,null,14.6"),
            URLQueryItem(name: "school", value: "0"),
            URLQueryItem(name: "timezonestring", value: location.timeZoneIdentifier)
        ]

        guard let url = components.url else {
            throw URLError(.badURL)
        }
        return url
    }
}
