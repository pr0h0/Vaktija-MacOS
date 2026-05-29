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
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.nextTarget?.event.displayName ?? "Vaktija")
                .font(.title3.weight(.semibold))
                .lineLimit(1)

            if let target = entry.nextTarget {
                Text(target.date, style: .relative)
                    .font(.title2.weight(.semibold))
                    .monospacedDigit()
                    .minimumScaleFactor(0.78)
                    .lineLimit(1)
                Text(timeText(for: target.date))
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
            Text(entry.status)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 8) {
            mediumNextRow
            Divider()
            mediumRemainingGrid
        }
    }

    private var largeView: some View {
        VStack(alignment: .leading, spacing: 10) {
            header(titleFont: .title3.weight(.semibold), detailFont: .callout.monospacedDigit())
            dailyList(events: PrayerEvent.countdownEvents, font: .body)
            Divider()
            dailyList(events: [.midnight, .lastThird], font: .callout)
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

    private func header(titleFont: Font, detailFont: Font) -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.nextTarget?.event.displayName ?? "Vaktija")
                    .font(titleFont)
                    .lineLimit(1)

                if let target = entry.nextTarget {
                    Text(target.date, style: .relative)
                        .font(detailFont)
                        .foregroundStyle(.secondary)
                        .minimumScaleFactor(0.85)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            if let target = entry.nextTarget {
                Text(timeText(for: target.date))
                    .font(detailFont)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var mediumNextRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(entry.nextTarget?.event.displayName ?? "Vaktija")
                .font(.title3.weight(.semibold))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let target = entry.nextTarget {
                Text(CountdownFormatter.full(duration: target.duration))
                    .font(.title3.weight(.semibold).monospacedDigit())
                    .minimumScaleFactor(0.82)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .center)

                Text(timeText(for: target.date))
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    private var mediumRemainingGrid: some View {
        let events = PrayerEvent.countdownEvents
        let columns = [
            GridItem(.flexible(minimum: 112), spacing: 10, alignment: .leading),
            GridItem(.flexible(minimum: 112), spacing: 10, alignment: .leading)
        ]

        return LazyVGrid(columns: columns, alignment: .leading, spacing: 5) {
            ForEach(events, id: \.self) { event in
                if let time = entry.today?.time(for: event) {
                    HStack(spacing: 6) {
                        Text(event.displayName)
                            .lineLimit(1)
                        Spacer(minLength: 4)
                        Text(timeText(for: time))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    .font(.callout)
                    .minimumScaleFactor(0.85)
                    .lineLimit(1)
                }
            }
        }
    }

    private func dailyList(events: [PrayerEvent], font: Font) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            ForEach(events, id: \.self) { event in
                if let time = entry.today?.time(for: event) {
                    HStack(spacing: 6) {
                        Text(event.displayName)
                            .lineLimit(1)
                        Spacer(minLength: 8)
                        Text(timeText(for: time))
                            .monospacedDigit()
                    }
                    .font(font)
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
