import SwiftUI
import WidgetKit

struct VaktijaWidget: Widget {
    let kind = "VaktijaWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: VaktijaWidgetProvider()) { entry in
            VaktijaWidgetView(entry: entry)
        }
        .configurationDisplayName("Vaktija")
        .description("Shows the next prayer time and daily vaktija.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct VaktijaWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: VaktijaWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.nextName)
                    .font(.headline)
                Text(entry.relativeCountdown)
                    .font(.title3.weight(.semibold))
                Text(entry.nextTime)
                    .font(.caption.monospacedDigit())
            }
            .containerBackground(.background, for: .widget)
        case .systemMedium:
            dailyList
                .containerBackground(.background, for: .widget)
        default:
            VStack(alignment: .leading, spacing: 10) {
                dailyList
                Divider()
                HStack {
                    Text("Pola noći")
                    Spacer()
                    Text("00:44")
                }
                HStack {
                    Text("Zadnja trećina")
                    Spacer()
                    Text("02:12")
                }
            }
            .containerBackground(.background, for: .widget)
        }
    }

    private var dailyList: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("\(entry.nextName) \(entry.relativeCountdown)")
                    .font(.headline)
                Spacer()
                Text(entry.nextTime)
                    .font(.caption.monospacedDigit())
            }
            ForEach([
                ("Fajr", "03:27"),
                ("Sunrise", "05:09"),
                ("Dhuhr", "12:44"),
                ("Asr", "16:45"),
                ("Maghrib", "20:19"),
                ("Isha", "22:01")
            ], id: \.0) { name, time in
                HStack {
                    Text(name)
                    Spacer()
                    Text(time)
                        .monospacedDigit()
                }
                .font(.caption)
            }
        }
    }
}
