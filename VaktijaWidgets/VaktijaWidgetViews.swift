import SwiftUI
import WidgetKit
import VaktijaCore

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
        Group {
            if entry.hasPrayerData {
                content
            } else {
                emptyState
            }
        }
        .containerBackground(.background, for: .widget)
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        default:
            largeView
        }
    }

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(entry.nextTarget?.event.rawValue ?? "Vaktija")
                .font(.headline)
                .lineLimit(1)

            if let target = entry.nextTarget {
                Text(target.date, style: .relative)
                    .font(.title3.weight(.semibold))
                    .monospacedDigit()
                    .lineLimit(1)
                Text(timeText(for: target.date))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
            Text(entry.status)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 6) {
            header
            dailyList(events: PrayerEvent.countdownEvents)
        }
    }

    private var largeView: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            dailyList(events: PrayerEvent.countdownEvents)
            Divider()
            dailyList(events: [.midnight, .lastThird])
            Spacer(minLength: 0)
            HStack(spacing: 4) {
                Text(entry.status)
                Text("•")
                Text(entry.source)
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.nextTarget?.event.rawValue ?? "Vaktija")
                    .font(.headline)
                    .lineLimit(1)

                if let target = entry.nextTarget {
                    Text(target.date, style: .relative)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 8)

            if let target = entry.nextTarget {
                Text(timeText(for: target.date))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func dailyList(events: [PrayerEvent]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(events, id: \.self) { event in
                if let time = entry.today?.time(for: event) {
                    HStack(spacing: 6) {
                        Text(event.rawValue)
                            .lineLimit(1)
                        Spacer(minLength: 8)
                        Text(timeText(for: time))
                            .monospacedDigit()
                    }
                    .font(.caption)
                    .foregroundStyle(event == entry.nextTarget?.event ? .primary : .secondary)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Vaktija")
                .font(.headline)
            Text(entry.status)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(entry.source)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
    }

    private func timeText(for date: Date) -> String {
        let components = entry.calendar.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", components.hour ?? 0, components.minute ?? 0)
    }

    private func timeText(for components: DateComponents) -> String {
        guard let hour = components.hour, let minute = components.minute else {
            return "--:--"
        }
        return String(format: "%02d:%02d", hour, minute)
    }
}
