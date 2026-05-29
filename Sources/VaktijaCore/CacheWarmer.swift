import Foundation

public struct MonthRequest: Equatable, Sendable {
    public let year: Int
    public let month: Int

    public init(year: Int, month: Int) {
        self.year = year
        self.month = month
    }
}

public struct CacheWarmer<Fetcher: PrayerCalendarFetching> {
    public let fetcher: Fetcher
    public let cache: PrayerCache
    public let calendar: Calendar

    public init(fetcher: Fetcher, cache: PrayerCache, calendar: Calendar) {
        self.fetcher = fetcher
        self.cache = cache
        self.calendar = calendar
    }

    public func warm(location: PrayerLocation, now: Date) async throws {
        for request in requests(now: now) {
            if cache.hasMonth(locationSlug: location.slug, year: request.year, month: request.month) {
                continue
            }

            let days = try await fetcher.fetchMonth(
                location: location,
                year: request.year,
                month: request.month
            )
            try cache.save(
                days: days,
                locationSlug: location.slug,
                year: request.year,
                month: request.month
            )
        }
    }

    public func requests(now: Date) -> [MonthRequest] {
        let year = calendar.component(.year, from: now)
        let month = calendar.component(.month, from: now)

        var requests = [MonthRequest(year: year, month: month)]
        requests.append(contentsOf: (1...12)
            .filter { $0 != month }
            .map { MonthRequest(year: year, month: $0) })

        if month == 12 {
            requests.append(contentsOf: (1...12).map { MonthRequest(year: year + 1, month: $0) })
        }

        return requests
    }
}
