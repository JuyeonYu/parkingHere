//
//  ParkingWidgetBundle.swift
//  ParkingWidget
//

import WidgetKit
import SwiftUI

@main
struct ParkingWidgetBundle: WidgetBundle {
    var body: some Widget {
        ParkingLiveActivity()
        if #available(iOS 18.0, *) {
            StartParkingControl()
            EndParkingControl()
            FindMyCarControl()
        }
    }
}
