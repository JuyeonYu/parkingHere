//
//  ControlIntents.swift
//  parkingHere
//
//  제어 센터 컨트롤과 앱이 함께 쓰는 인텐트. 이 파일은 앱과 ParkingWidget 두 타겟에 모두 들어간다.
//  실제 동작은 앱 프로세스에서만 실행되므로 익스텐션 빌드(PARKING_WIDGET)에서는 빈 구현으로 둔다.
//

import AppIntents

/// 앱을 열어 주차 화면(위치가 있으면 지도까지)으로 이동한다.
@available(iOS 17.0, *)
struct OpenParkingScreenIntent: AppIntent {
    static var title: LocalizedStringResource = "intent.find.title"
    static var openAppWhenRun = true
    static var isDiscoverable = false

    func perform() async throws -> some IntentResult {
        #if !PARKING_WIDGET
        let hasLocation = ParkingSessionStore.current?.coordinate != nil
        DeepLinkRouter.open(hasLocation ? .map : .parking)
        #endif
        return .result()
    }
}

/// 제어 센터의 "주차 시작" 버튼. LiveActivityIntent 라서 시스템이 앱 프로세스에서 실행한다.
@available(iOS 17.0, *)
struct StartParkingControlIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "intent.start.title"
    static var isDiscoverable = false
    static var openAppWhenRun = false

    func perform() async throws -> some IntentResult {
        #if !PARKING_WIDGET
        _ = try await StartParkingIntent().perform()
        #endif
        return .result()
    }
}

/// 제어 센터의 "주차 종료" 버튼.
@available(iOS 17.0, *)
struct EndParkingControlIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "intent.end.title"
    static var isDiscoverable = false
    static var openAppWhenRun = false

    func perform() async throws -> some IntentResult {
        #if !PARKING_WIDGET
        _ = try await EndParkingIntent().perform()
        #endif
        return .result()
    }
}
