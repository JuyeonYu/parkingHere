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
    /// 시작 시각 기준으로 시스템이 타이머를 그리므로 갱신할 동적 상태는 없다.
    struct ContentState: Codable, Hashable {}

    var startedAt: Date
    var memo: String?
    var hasLocation: Bool
}
