//
//  MyDayWidget.swift
//  MyDayWidget
//
//  Created by Josblais on 2025-04-24.
//  Enhanced by Assistant on 2026-01-26
//

import WidgetKit
import SwiftUI
import Intents

struct SimpleEntry: TimelineEntry {
    let date: Date
    let title: String
    let eventTime: String?
    let remainingTime: String?
    let upcomingCount: Int
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            title: "Aujourd'hui",
            eventTime: nil,
            remainingTime: nil,
            upcomingCount: 0
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        let entry = SimpleEntry(
            date: Date(),
            title: "Snapshot",
            eventTime: "14:30",
            remainingTime: "Dans 2h",
            upcomingCount: 3
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let defaults = UserDefaults(suiteName: "group.com.josblais.myday")
        let data = defaults?.dictionary(forKey: "nextItem") as? [String: String]
        
        let title = data?["title"] ?? localized("defaultTitle")
        let eventTime = data?["time"]
        let remainingTime = data?["remaining"]
        let upcomingCount = defaults?.integer(forKey: "upcomingCount") ?? 0
        
        let entry = SimpleEntry(
            date: Date(),
            title: title,
            eventTime: eventTime,
            remainingTime: remainingTime,
            upcomingCount: upcomingCount
        )
        
        // Mettre à jour le widget plus fréquemment (toutes les 5 minutes)
        let nextUpdate = Date().addingTimeInterval(300)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}
func localized(_ key: String) -> String {
    let lang = Locale.preferredLanguages.first ?? "en"
    let isFrench = lang.hasPrefix("fr")

    switch key {
    case "nextItem":
        return isFrench ? "Prochain rappel" : "Next reminder"
    case "defaultTitle":
        return isFrench ? "Aucun rappel" : "No reminder"
    case "widgetName":
        return isFrench ? "MyDay – Prochain rappel" : "MyDay – Next reminder"
    case "widgetDesc":
        return isFrench ? "Affiche votre prochain rappel ou événement." : "Shows your next reminder or event."
    default:
        return key
    }
}


struct MyDayWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {

        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("📅 MyDay")
                        .font(.caption2)
                        .foregroundColor(.accentColor)
                    
                    if entry.upcomingCount > 1 {
                        Spacer()
                        Text("+\(entry.upcomingCount - 1)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(entry.title)
                    .font(.body)
                    .lineLimit(1)
                
                if let remainingTime = entry.remainingTime {
                    Text(remainingTime)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .containerBackground(for: .widget) {
                Color.clear
            }

        case .accessoryInline:
            Group {
                if let eventTime = entry.eventTime {
                    Text("\(eventTime) • \(entry.title)")
                        .lineLimit(1)
                } else {
                    Text("MyDay: \(entry.title)")
                        .lineLimit(1)
                }
            }
            .containerBackground(for: .widget) {
                Color.clear
            }

        case .accessoryCircular:
            ZStack {
                Circle()
                    .stroke(lineWidth: 2)
                    .foregroundColor(.accentColor)
                
                VStack(spacing: 2) {
                    Text("📅")
                        .font(.caption2)
                    
                    if entry.upcomingCount > 0 {
                        Text("\(entry.upcomingCount)")
                            .font(.caption.bold())
                    }
                }
            }
            .containerBackground(for: .widget) {
                Color.clear
            }

        case .systemSmall:
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("📅")
                        .font(.title2)
                    
                    Spacer()
                    
                    if entry.upcomingCount > 0 {
                        Text("\(entry.upcomingCount)")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor)
                            .clipShape(Capsule())
                    }
                }
                
                if let eventTime = entry.eventTime {
                    Text(eventTime)
                        .font(.caption)
                        .foregroundColor(.accentColor)
                        .fontWeight(.semibold)
                }
                
                Text(entry.title)
                    .font(.caption)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if let remainingTime = entry.remainingTime {
                    Spacer()
                    Text(remainingTime)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .containerBackground(for: .widget) {
                Color(.systemBackground)
            }

        case .systemMedium:
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(localized("nextItem"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if entry.upcomingCount > 1 {
                            Text("(+\(entry.upcomingCount - 1))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Text(entry.title)
                        .font(.headline)
                        .lineLimit(2)
                    
                    HStack(spacing: 8) {
                        if let eventTime = entry.eventTime {
                            Label(eventTime, systemImage: "clock")
                                .font(.caption2)
                                .foregroundColor(.accentColor)
                        }
                        
                        if let remainingTime = entry.remainingTime {
                            Text(remainingTime)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "calendar.badge.clock")
                    .font(.largeTitle)
                    .foregroundColor(.accentColor.opacity(0.3))
            }
            .padding()
            .containerBackground(for: .widget) {
                Color(.systemBackground)
            }

        default:
            VStack {
                Text(entry.title)
            }
            .containerBackground(for: .widget) {
                Color.clear
            }
        }
    }
}

@main
struct MyDayWidget: Widget {
    let kind: String = "MyDayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            MyDayWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(localized("widgetName"))
        .description(localized("widgetDesc"))
            .supportedFamilies([
            .accessoryRectangular,
            .accessoryInline,
            .accessoryCircular,
            .systemSmall,
            .systemMedium
        ])
    }
}

struct MyDayWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MyDayWidgetEntryView(entry: SimpleEntry(
                date: Date(),
                title: "Dentiste 15h",
                eventTime: "15:00",
                remainingTime: "Dans 2h",
                upcomingCount: 3
            ))
                .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
                .previewDisplayName("Lock Screen – Rectangular")

            MyDayWidgetEntryView(entry: SimpleEntry(
                date: Date(),
                title: "Appeler maman",
                eventTime: nil,
                remainingTime: "Aujourd'hui",
                upcomingCount: 1
            ))
                .previewContext(WidgetPreviewContext(family: .accessoryInline))
                .previewDisplayName("Lock Screen – Inline")

            MyDayWidgetEntryView(entry: SimpleEntry(
                date: Date(),
                title: "Rdv 17h",
                eventTime: "17:00",
                remainingTime: nil,
                upcomingCount: 2
            ))
                .previewContext(WidgetPreviewContext(family: .accessoryCircular))
                .previewDisplayName("Lock Screen – Circular")

            MyDayWidgetEntryView(entry: SimpleEntry(
                date: Date(),
                title: "Faire les courses avant 17h",
                eventTime: "17:00",
                remainingTime: "Dans 4h",
                upcomingCount: 4
            ))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Home Screen – Small")

            MyDayWidgetEntryView(entry: SimpleEntry(
                date: Date(),
                title: "Présentation 10h30 • Salle 202",
                eventTime: "10:30",
                remainingTime: "Dans 1h 15min",
                upcomingCount: 5
            ))
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Home Screen – Medium")
        }
    }
}
