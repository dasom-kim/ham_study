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

@main
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
