//
//  RestTimerWidgetBundle.swift
//  RestTimerWidget
//
//  Created by Reed Rawlings on 12/19/25.
//

import WidgetKit
import SwiftUI

@main
struct RestTimerWidgetBundle: WidgetBundle {
    var body: some Widget {
        RestTimerWidget()
        RestTimerWidgetControl()
        RestTimerWidgetLiveActivity()
    }
}
