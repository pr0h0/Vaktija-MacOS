import Foundation
import WidgetKit
import VaktijaCore

struct VaktijaWidgetEntry: TimelineEntry {
    let date: Date
    let today: PrayerDay?
    let nextTarget: CountdownTarget?
    let status: String
    let calendar: Calendar

    var hasPrayerData: Bool {
        today != nil
    }
}

struct VaktijaWidgetProvider: TimelineProvider {
    private let location = PrayerLocation.sarajevo

    func placeholder(in context: Context) -> VaktijaWidgetEntry {
        sampleEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (VaktijaWidgetEntry) -> Void) {
        if context.isPreview {
            completion(sampleEntry(date: Date()))
        } else {
            completion(cacheEntry(date: Date()))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<VaktijaWidgetEntry>) -> Void) {
        let now = Date()
        let entry = cacheEntry(date: now)
        let reload = reloadDate(for: entry, now: now)
        completion(Timeline(entries: [entry], policy: .after(reload)))
    }

    private func cacheEntry(date now: Date) -> VaktijaWidgetEntry {
        let calendar = prayerCalendar()

        guard let cache = PrayerCache(appGroupIdentifier: "group.com.abdulahproho.vaktija") else {
            return VaktijaWidgetEntry(
                date: now,
                today: nil,
                nextTarget: nil,
                status: "Cache unavailable",
                calendar: calendar
            )
        }

        let today = loadDay(containing: now, cache: cache, calendar: calendar)
        let tomorrowDate = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        let tomorrow = loadDay(containing: tomorrowDate, cache: cache, calendar: calendar)
        let days = [today, tomorrow].compactMap { $0 }
        let nextTarget = CountdownEngine.nextTarget(now: now, days: days, calendar: calendar)

        return VaktijaWidgetEntry(
            date: now,
            today: today,
            nextTarget: nextTarget,
            status: today == nil ? "No cached times" : "Sarajevo",
            calendar: calendar
        )
    }

    private func loadDay(containing date: Date, cache: PrayerCache, calendar: Calendar) -> PrayerDay? {
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        guard let days = try? cache.load(locationSlug: location.slug, year: year, month: month) else {
            return nil
        }

        return days.first { calendar.isDate($0.date, inSameDayAs: date) }
    }

    private func reloadDate(for entry: VaktijaWidgetEntry, now: Date) -> Date {
        let tomorrow = entry.calendar.date(byAdding: .day, value: 1, to: now) ?? now
        let nextMidnight = entry.calendar.startOfDay(for: tomorrow)
        let nextPrayerReload = entry.nextTarget?.date.addingTimeInterval(60)
        let fallback = entry.calendar.date(byAdding: .minute, value: 30, to: now) ?? now

        return [nextPrayerReload, nextMidnight, fallback]
            .compactMap { $0 }
            .filter { $0 > now }
            .min() ?? fallback
    }

    private func prayerCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: location.timeZoneIdentifier) ?? .current
        return calendar
    }

    private func sampleEntry(date now: Date) -> VaktijaWidgetEntry {
        let calendar = prayerCalendar()
        let day = PrayerDay(
            date: calendar.startOfDay(for: now),
            locationName: location.name,
            timeZoneIdentifier: location.timeZoneIdentifier,
            times: [
                PrayerTime(event: .fajr, time: DateComponents(hour: 3, minute: 27)),
                PrayerTime(event: .sunrise, time: DateComponents(hour: 5, minute: 9)),
                PrayerTime(event: .dhuhr, time: DateComponents(hour: 12, minute: 44)),
                PrayerTime(event: .asr, time: DateComponents(hour: 16, minute: 45)),
                PrayerTime(event: .maghrib, time: DateComponents(hour: 20, minute: 19)),
                PrayerTime(event: .isha, time: DateComponents(hour: 22, minute: 1)),
                PrayerTime(event: .midnight, time: DateComponents(hour: 0, minute: 44)),
                PrayerTime(event: .lastThird, time: DateComponents(hour: 2, minute: 12))
            ]
        )
        let nextTarget = CountdownEngine.nextTarget(now: now, days: [day], calendar: calendar)

        return VaktijaWidgetEntry(
            date: now,
            today: day,
            nextTarget: nextTarget,
            status: "Sarajevo",
            calendar: calendar
        )
    }
}
