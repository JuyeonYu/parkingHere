//
//  ParkingActivityAttributes.swift
//  parkingHere
//
//  앱과 ParkingWidget 익스텐션이 함께 쓰는 라이브 액티비티 정의.
//

import ActivityKit
import Foundation

@available(iOS 16.1, *)
struct ParkingActivityAttributes: ActivityAttributes {
    /// 주차 중에 바뀔 수 있는 값. 타이머는 시작 시각 기준으로 시스템이 그린다.
    struct ContentState: Codable, Hashable {
        var memo: String?
        var hasPhoto: Bool
    }

    var startedAt: Date
    var hasLocation: Bool
}
