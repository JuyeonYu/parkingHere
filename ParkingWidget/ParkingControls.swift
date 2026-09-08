//
//  ParkingControls.swift
//  ParkingWidget
//
//  제어 센터, 잠금 화면 하단, 액션 버튼에 넣을 수 있는 컨트롤 (iOS 18+).
//

import AppIntents
import SwiftUI
import WidgetKit

@available(iOS 18.0, *)
struct StartParkingControl: ControlWidget {
    static let kind = "com.johnny.findMyCar.control.start"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: StartParkingControlIntent()) {
                Label("control.start", systemImage: "car.fill")
            }
        }
        .displayName("control.start")
        .description("control.start.description")
    }
}

@available(iOS 18.0, *)
struct EndParkingControl: ControlWidget {
    static let kind = "com.johnny.findMyCar.control.end"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: EndParkingControlIntent()) {
                Label("control.end", systemImage: "flag.checkered")
            }
        }
        .displayName("control.end")
        .description("control.end.description")
    }
}

@available(iOS 18.0, *)
struct FindMyCarControl: ControlWidget {
    static let kind = "com.johnny.findMyCar.control.find"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: OpenParkingScreenIntent()) {
                Label("control.find", systemImage: "location.fill")
            }
        }
        .displayName("control.find")
        .description("control.find.description")
    }
}
