//
//  HamStudyWidget.swift
//  HamStudyWidget
//

import WidgetKit
import SwiftUI

// MARK: - UserDefaults에서 위젯 데이터 읽기

private let appGroupId = "group.hamstudy"

private func loadWidgetData() -> (subjectName: String, totalTime: String, subjectColor: Color) {
    let defaults = UserDefaults(suiteName: appGroupId)
    let subjectName = defaults?.string(forKey: "widget_subjectName") ?? "대기 중"
    let totalTime   = defaults?.string(forKey: "widget_totalTime")   ?? "00:00:00"
    let colorHex    = defaults?.string(forKey: "widget_subjectColor") ?? "#FF9800"
    return (subjectName, totalTime, colorFromHex(colorHex))
}

private func colorFromHex(_ hex: String) -> Color {
    var h = hex.trimmingCharacters(in: .whitespacesAndNewlines)
    if h.hasPrefix("#") { h = String(h.dropFirst()) }
    guard h.count == 6, let value = UInt64(h, radix: 16) else {
        return Color.orange
    }
    let r = Double((value >> 16) & 0xFF) / 255.0
    let g = Double((value >>  8) & 0xFF) / 255.0
    let b = Double( value        & 0xFF) / 255.0
    return Color(red: r, green: g, blue: b)
}

// MARK: - Timeline Entry

struct SimpleEntry: TimelineEntry {
    let date: Date
    let subjectName: String
    let totalTime: String
    let subjectColor: Color
}

// MARK: - Provider

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), subjectName: "수학", totalTime: "01:23:45", subjectColor: .orange)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        let data = loadWidgetData()
        completion(SimpleEntry(date: Date(), subjectName: data.subjectName,
                               totalTime: data.totalTime, subjectColor: data.subjectColor))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let data = loadWidgetData()
        let entry = SimpleEntry(date: Date(), subjectName: data.subjectName,
                                totalTime: data.totalTime, subjectColor: data.subjectColor)
        // Flutter가 HomeWidget.updateWidget()을 호출할 때마다 위젯이 갱신되므로
        // 타임라인은 .never로 두어 불필요한 재로딩을 방지합니다.
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

// MARK: - Widget View

struct HamStudyWidgetEntryView: View {
    var entry: SimpleEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("🐹 오늘의 공부")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(entry.subjectColor)
                Spacer()
                Text("앱 열기")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            Text(entry.subjectName)
                .font(.system(size: 13))
                .foregroundColor(entry.subjectColor)
                .lineLimit(1)

            Text(entry.totalTime)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.primary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

// MARK: - Widget Configuration

struct HamStudyWidget: Widget {
    let kind: String = "HamStudyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            HamStudyWidgetEntryView(entry: entry)
                .containerBackground(.background, for: .widget)
                .widgetURL(URL(string: "hamstudy://0")) // 탭 0 = 타이머
        }
        .configurationDisplayName("오늘의 공부")
        .description("현재 공부 중인 과목과 누적 시간을 표시합니다.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    HamStudyWidget()
} timeline: {
    SimpleEntry(date: .now, subjectName: "수학", totalTime: "01:23:45", subjectColor: .orange)
    SimpleEntry(date: .now, subjectName: "영어", totalTime: "00:45:10", subjectColor: Color(red: 0.2, green: 0.6, blue: 1.0))
}
