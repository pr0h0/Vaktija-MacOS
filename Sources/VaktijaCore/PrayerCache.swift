import Foundation

public struct PrayerCache: Sendable {
    public let baseDirectory: URL

    public init(baseDirectory: URL) {
        self.baseDirectory = baseDirectory
    }

    public init?(appGroupIdentifier: String, fileManager: FileManager = .default) {
        guard let url = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
            return nil
        }
        self.baseDirectory = url.appendingPathComponent("PrayerCache", isDirectory: true)
    }

    public func save(
        days: [PrayerDay],
        locationSlug: String,
        year: Int,
        month: Int
    ) throws {
        let url = fileURL(locationSlug: locationSlug, year: year, month: month)
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(days)
        try data.write(to: url, options: [.atomic])
    }

    public func load(locationSlug: String, year: Int, month: Int) throws -> [PrayerDay] {
        let data = try Data(contentsOf: fileURL(locationSlug: locationSlug, year: year, month: month))
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([PrayerDay].self, from: data)
    }

    public func hasMonth(locationSlug: String, year: Int, month: Int) -> Bool {
        FileManager.default.fileExists(atPath: fileURL(locationSlug: locationSlug, year: year, month: month).path)
    }

    public func fileURL(locationSlug: String, year: Int, month: Int) -> URL {
        baseDirectory
            .appendingPathComponent("locations", isDirectory: true)
            .appendingPathComponent(locationSlug, isDirectory: true)
            .appendingPathComponent(String(year), isDirectory: true)
            .appendingPathComponent(String(format: "%02d.json", month), isDirectory: false)
    }
}
