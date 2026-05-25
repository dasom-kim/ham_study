//
//  HamStudyWidgetBundle.swift
//  HamStudyWidget
//
//  Created by 김다솜 on 5/23/26.
//

import WidgetKit
import SwiftUI

@main
struct HamStudyWidgetBundle: WidgetBundle {
    var body: some Widget {
        HamStudyWidget()          // 공부시간 위젯
        HamStudyDdayWidget()      // 디데이 위젯
        HamStudyWidgetLiveActivity()
    }
}
