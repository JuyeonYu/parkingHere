//
//  ParkingActivityController.swift
//  parkingHere
//

import ActivityKit
import Foundation

/// 주차 중 잠금 화면과 다이내믹 아일랜드에 표시되는 라이브 액티비티를 관리한다.
enum ParkingActivityController {
    static func start(_ session: ParkingSession) {
        guard #available(iOS 16.1, *) else { return }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            NSLog("ParkingActivityController: live activities are disabled for this app")
            return
        }
        endAll()

        let attributes = ParkingActivityAttributes(startedAt: session.startedAt,
                                                   memo: session.memo,
                                                   hasLocation: session.coordinate != nil)
        do {
            if #available(iOS 16.2, *) {
                let content = ActivityContent(state: ParkingActivityAttributes.ContentState(), staleDate: nil)
                _ = try Activity.request(attributes: attributes, content: content)
            } else {
                _ = try Activity.request(attributes: attributes,
                                         contentState: ParkingActivityAttributes.ContentState())
            }
        } catch {
            NSLog("ParkingActivityController: failed to start activity - %@", String(describing: error))
        }
    }

    static func endAll() {
        guard #available(iOS 16.1, *) else { return }
        for activity in Activity<ParkingActivityAttributes>.activities {
            Task {
                if #available(iOS 16.2, *) {
                    await activity.end(nil, dismissalPolicy: .immediate)
                } else {
                    await activity.end(dismissalPolicy: .immediate)
                }
            }
        }
    }

    /// 앱이 실행될 때 저장된 주차 상태와 액티비티를 맞춘다.
    /// 시스템이 액티비티를 끝냈거나(8시간 제한, 재부팅) 앱이 종료된 사이 어긋난 경우를 복구한다.
    static func sync(with session: ParkingSession?) {
        guard #available(iOS 16.1, *) else { return }
        let running = Activity<ParkingActivityAttributes>.activities
        if let session = session {
            if running.isEmpty { start(session) }
        } else if !running.isEmpty {
            endAll()
        }
    }
}
