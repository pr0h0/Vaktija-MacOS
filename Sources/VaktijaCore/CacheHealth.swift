import Foundation

public enum CacheHealth {
    public static func summary(
        cache: PrayerCache,
        locationSlug: String,
        now: Date,
        calendar: Calendar
    ) -> String {
        guard let cachedThrough = cachedThroughDate(
            cache: cache,
            locationSlug: locationSlug,
            now: now,
            calendar: calendar
        ) else {
            return "No cached times"
        }

        return "Cached through \(dateText(cachedThrough, calendar: calendar))"
    }

    private static func cachedThroughDate(
        cache: PrayerCache,
        locationSlug: String,
        now: Date,
        calendar: Calendar
    ) -> Date? {
        let start = calendar.startOfDay(for: now)
        var current = start
        var cachedThrough: Date?
        var monthCache: [MonthKey: Set<Date>] = [:]

        for _ in 0..<400 {
            let key = MonthKey(
                year: calendar.component(.year, from: current),
                month: calendar.component(.month, from: current)
            )

            if monthCache[key] == nil {
                guard let days = try? cache.load(locationSlug: locationSlug, year: key.year, month: key.month) else {
                    break
                }

                monthCache[key] = Set(days.map { calendar.startOfDay(for: $0.date) })
            }

            guard monthCache[key]?.contains(current) == true else {
                break
            }

            cachedThrough = current
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else {
                break
            }
            current = calendar.startOfDay(for: next)
        }

        return cachedThrough
    }

    private static func dateText(_ date: Date, calendar: Calendar) -> String {
        let formatter = dateFormatter
        formatter.timeZone = calendar.timeZone
        return formatter.string(from: date)
    }

    private static var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMM d"
        return formatter
    }

    private struct MonthKey: Hashable {
        let year: Int
        let month: Int
    }
}
