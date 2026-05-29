import Foundation

public enum PrayerScheduleMapperError: Error, Equatable {
    case invalidTimeZone(String)
    case invalidDate(String)
    case invalidTime(String)
}

public enum PrayerScheduleMapper {
    public static func map(
        response: AlAdhanCalendarResponse,
        locationName: String
    ) throws -> [PrayerDay] {
        try response.data.map { day in
            let timeZoneIdentifier = day.meta.timezone
            guard let timeZone = TimeZone(identifier: timeZoneIdentifier) else {
                throw PrayerScheduleMapperError.invalidTimeZone(timeZoneIdentifier)
            }

            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = timeZone

            let date = try parseDate(
                day.date.gregorian.date,
                calendar: calendar,
                timeZone: timeZone
            )

            return PrayerDay(
                date: date,
                locationName: locationName,
                timeZoneIdentifier: timeZoneIdentifier,
                times: [
                    PrayerTime(event: .fajr, time: try parseTime(day.timings.fajr)),
                    PrayerTime(event: .sunrise, time: try parseTime(day.timings.sunrise)),
                    PrayerTime(event: .dhuhr, time: try parseTime(day.timings.dhuhr)),
                    PrayerTime(event: .asr, time: try parseTime(day.timings.asr)),
                    PrayerTime(event: .maghrib, time: try parseTime(day.timings.maghrib)),
                    PrayerTime(event: .isha, time: try parseTime(day.timings.isha)),
                    PrayerTime(event: .midnight, time: try parseTime(day.timings.midnight)),
                    PrayerTime(event: .lastThird, time: try parseTime(day.timings.lastThird))
                ]
            )
        }
    }

    private static func parseDate(
        _ value: String,
        calendar: Calendar,
        timeZone: TimeZone
    ) throws -> Date {
        let parts = value.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else {
            throw PrayerScheduleMapperError.invalidDate(value)
        }

        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = timeZone
        components.day = parts[0]
        components.month = parts[1]
        components.year = parts[2]
        components.hour = 0
        components.minute = 0
        components.second = 0

        guard let date = calendar.date(from: components) else {
            throw PrayerScheduleMapperError.invalidDate(value)
        }
        return date
    }

    private static func parseTime(_ value: String) throws -> DateComponents {
        let timePart = value.split(separator: " ").first.map(String.init) ?? value
        let parts = timePart.split(separator: ":").compactMap { Int($0) }
        guard parts.count >= 2 else {
            throw PrayerScheduleMapperError.invalidTime(value)
        }

        var components = DateComponents()
        components.hour = parts[0]
        components.minute = parts[1]
        components.second = 0
        return components
    }
}
