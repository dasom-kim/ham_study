//
//  HamStudyWidgetLiveActivity.swift
//  HamStudyWidget
//
//  Created by 김다솜 on 5/23/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

// Flutter에서 보낸 데이터를 받는 모델
struct HamStudyAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {}
    var subjectName: String
    var startTime: Int
}

struct HamStudyWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: HamStudyAttributes.self) { context in
            // 1. 잠금화면 (Lock Screen) UI
            let startDate = Date(timeIntervalSince1970: TimeInterval(context.attributes.startTime) / 1000)
            
            HStack {
                Text("🐹")
                    .font(.system(size: 40))
                VStack(alignment: .leading) {
                    Text("\(context.attributes.subjectName) 공부 중")
                        .font(.headline)
                        .foregroundColor(.orange)
                    Text(timerInterval: startDate...Date.distantFuture)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                }
                Spacer()
            }
            .padding(20)
            .background(Color(red: 1.0, green: 0.97, blue: 0.95)) // 파스텔 배경
            
        } dynamicIsland: { context in
            // 2. 다이내믹 아일랜드 (Dynamic Island) UI
            let startDate = Date(timeIntervalSince1970: TimeInterval(context.attributes.startTime) / 1000)
            
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text("HamStudy 🐹")
                        .font(.headline)
                        .foregroundColor(.orange)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: startDate...Date.distantFuture)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("\(context.attributes.subjectName) 열공 중!")
                        .foregroundColor(.gray)
                }
            } compactLeading: {
                Text("🐹")
            } compactTrailing: {
                Text(timerInterval: startDate...Date.distantFuture)
                    .foregroundColor(.orange)
            } minimal: {
                Text("🐹")
            }
        }
    }
}

// MARK: - 홈 화면 위젯 (Home Screen Widget)
struct HamStudyHomeWidgetProvider: TimelineProvider {
    // 위젯을 선택할 때 보여줄 임시 데이터
    func placeholder(in context: Context) -> HamStudyHomeWidgetEntry {
        HamStudyHomeWidgetEntry(date: Date(), subjectName: "국어", totalTime: "02:30:00")
    }

    // 위젯 갤러리에서 보여줄 미리보기
    func getSnapshot(in context: Context, completion: @escaping (HamStudyHomeWidgetEntry) -> ()) {
        let entry = HamStudyHomeWidgetEntry(date: Date(), subjectName: "국어", totalTime: "02:30:00")
        completion(entry)
    }

    // 실제 위젯에 표시될 데이터 (Flutter에서 보낸 데이터 읽기)
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        // 앱 그룹(group.hamstudy)에 저장된 데이터를 가져옵니다.
        let userDefaults = UserDefaults(suiteName: "group.hamstudy")
        let subjectName = userDefaults?.string(forKey: "widget_subjectName") ?? "대기 중"
        let totalTime = userDefaults?.string(forKey: "widget_totalTime") ?? "00:00:00"
        
        let entry = HamStudyHomeWidgetEntry(date: Date(), subjectName: subjectName, totalTime: totalTime)
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct HamStudyHomeWidgetEntry: TimelineEntry {
    let date: Date
    let subjectName: String
    let totalTime: String
}

struct HamStudyHomeWidgetEntryView : View {
    var entry: HamStudyHomeWidgetProvider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("🐹 오늘의 공부")
                .font(.headline)
                .foregroundColor(.orange)
            Text(entry.subjectName)
                .font(.subheadline)
            Text(entry.totalTime)
                .font(.title2)
                .bold()
        }
    }
}

struct HamStudyHomeWidget: Widget {
    let kind: String = "HamStudyHomeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HamStudyHomeWidgetProvider()) { entry in
            HamStudyHomeWidgetEntryView(entry: entry)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("햄스터디 공부 현황")
        .description("오늘의 총 공부 시간과 과목을 확인하세요.")
    }
}
