//
//  HamStudyDdayWidget.swift
//  HamStudyWidget
//

import WidgetKit
import SwiftUI

// MARK: - Data Model

struct DdayItem: Identifiable {
    let id = UUID()
    let title: String
    let dday: String
}

func loadDdayData() -> [DdayItem] {
    guard
        let defaults = UserDefaults(suiteName: "group.hamstudy"),
        let json = defaults.string(forKey: "widget_ddayList"),
        let data = json.data(using: .utf8),
        let array = try? JSONSerialization.jsonObject(with: data) as? [[String: String]]
    else { return [] }

    return array.compactMap { dict in
        guard let title = dict["title"], let dday = dict["dday"] else { return nil }
        return DdayItem(title: title, dday: dday)
    }
}

// MARK: - Timeline Entry

struct DdayEntry: TimelineEntry {
    let date: Date
    let items: [DdayItem]
}

// MARK: - Provider

struct DdayProvider: TimelineProvider {
    func placeholder(in context: Context) -> DdayEntry {
        DdayEntry(date: Date(), items: [
            DdayItem(title: "수능", dday: "D-100"),
            DdayItem(title: "TOEIC", dday: "D-Day"),
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (DdayEntry) -> Void) {
        completion(DdayEntry(date: Date(), items: loadDdayData()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DdayEntry>) -> Void) {
        let entry = DdayEntry(date: Date(), items: loadDdayData())
        let midnight = Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))
        let timeline = Timeline(entries: [entry], policy: .after(midnight))
        completion(timeline)
    }
}

// MARK: - Color Helper

func ddayColor(_ text: String) -> Color {
    if text == "D-Day" { return .red }
    if text.hasPrefix("D+") { return .gray }
    return Color(red: 1.0, green: 0.35, blue: 0.1)
}

// MARK: - Widget View

struct DdayWidgetEntryView: View {
    var entry: DdayEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        if entry.items.isEmpty {
            emptyView
        } else {
            contentView
        }
    }

    private var emptyView: some View {
        VStack(spacing: 6) {
            Text("🐹")
                .font(.system(size: 28))
            Text("즐겨찾기 디데이 없음")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(14)
    }

    private var contentView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("🐹 D-Day")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.primary)
                Spacer()
            }
            Divider()
            let displayItems = Array(entry.items.prefix(family == .systemSmall ? 3 : 6))
            ForEach(displayItems) { item in
                HStack {
                    Text(item.title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Spacer()
                    Text(item.dday)
                        .font(.system(size: 13, weight: .black))
                        .foregroundColor(ddayColor(item.dday))
                }
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Widget Configuration

struct HamStudyDdayWidget: Widget {
    let kind: String = "HamStudyDdayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DdayProvider()) { entry in
            DdayWidgetEntryView(entry: entry)
                .containerBackground(.background, for: .widget)
                .widgetURL(URL(string: "hamstudy://1")) // 탭 1 = 디데이
        }
        .configurationDisplayName("D-Day")
        .description("즐겨찾기한 디데이를 표시합니다.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    HamStudyDdayWidget()
} timeline: {
    DdayEntry(date: .now, items: [
        DdayItem(title: "수능", dday: "D-100"),
        DdayItem(title: "TOEIC", dday: "D-Day"),
        DdayItem(title: "기말고사", dday: "D+3"),
    ])
}
