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
                                                   hasLocation: session.coordinate != nil)
        let state = contentState(for: session)
        do {
            if #available(iOS 16.2, *) {
                _ = try Activity.request(attributes: attributes, content: ActivityContent(state: state, staleDate: nil))
            } else {
                _ = try Activity.request(attributes: attributes, contentState: state)
            }
        } catch {
            NSLog("ParkingActivityController: failed to start activity - %@", String(describing: error))
        }
    }

    /// 메모나 사진이 바뀌었을 때 표시 중인 액티비티를 갱신한다.
    static func update(for session: ParkingSession) {
        guard #available(iOS 16.1, *) else { return }
        let state = contentState(for: session)
        for activity in Activity<ParkingActivityAttributes>.activities {
            Task {
                if #available(iOS 16.2, *) {
                    await activity.update(ActivityContent(state: state, staleDate: nil))
                } else {
                    await activity.update(using: state)
                }
            }
        }
    }

    @available(iOS 16.1, *)
    private static func contentState(for session: ParkingSession) -> ParkingActivityAttributes.ContentState {
        ParkingActivityAttributes.ContentState(memo: session.memo, hasPhoto: CarImageStore.exists)
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
