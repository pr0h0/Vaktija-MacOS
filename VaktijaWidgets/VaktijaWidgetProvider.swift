import WidgetKit
import SwiftUI

struct VaktijaWidgetEntry: TimelineEntry {
    let date: Date
    let nextName: String
    let nextTime: String
    let relativeCountdown: String
}

struct VaktijaWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> VaktijaWidgetEntry {
        VaktijaWidgetEntry(date: Date(), nextName: "Asr", nextTime: "16:45", relativeCountdown: "in 45m")
    }

    func getSnapshot(in context: Context, completion: @escaping (VaktijaWidgetEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<VaktijaWidgetEntry>) -> Void) {
        let entry = placeholder(in: context)
        let reload = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(reload)))
    }
}
