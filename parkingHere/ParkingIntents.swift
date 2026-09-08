//
//  ParkingIntents.swift
//  parkingHere
//
//  Siri, 단축어, 자동화에서 쓰는 App Intent.
//

import AppIntents
import CoreLocation

@available(iOS 17.0, *)
struct StartParkingIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "intent.start.title"
    static var description = IntentDescription("intent.start.description")
    static var openAppWhenRun = false

    /// 단축어의 "현재 위치 가져오기" 결과를 그대로 받는다. 앱이 백그라운드 위치 권한 없이도 위치를 저장할 수 있다.
    @Parameter(title: "intent.param.location")
    var location: CLPlacemark?

    @Parameter(title: "intent.param.memo")
    var memo: String?

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let trimmed = memo?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let session = ParkingSession(startedAt: Date(),
                                     memo: trimmed.isEmpty ? nil : trimmed,
                                     coordinate: location?.location?.coordinate)
        // 이미 주차 중이어도 가장 최근 하차가 현재 주차이므로 새 세션으로 바꾼다.
        ParkingSessionStore.start(session, photo: nil)
        await ParkingReminder.scheduleAddPhoto()
        return .result(dialog: IntentDialog(session.coordinate == nil ? "intent.start.done.noLocation" : "intent.start.done"))
    }
}

@available(iOS 17.0, *)
struct EndParkingIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "intent.end.title"
    static var description = IntentDescription("intent.end.description")
    static var openAppWhenRun = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard ParkingSessionStore.current != nil else {
            return .result(dialog: IntentDialog("intent.noSession"))
        }
        ParkingSessionStore.end()
        return .result(dialog: IntentDialog("intent.end.done"))
    }
}

@available(iOS 17.0, *)
enum ParkingIntentError: Error, CustomLocalizedStringResourceConvertible {
    case noSession

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .noSession: return "intent.noSession"
        }
    }
}

@available(iOS 17.0, *)
struct FindMyCarIntent: AppIntent {
    static var title: LocalizedStringResource = "intent.find.title"
    static var description = IntentDescription("intent.find.description")
    static var openAppWhenRun = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let session = ParkingSessionStore.current else {
            throw ParkingIntentError.noSession
        }

        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = session.startedAt.timeIntervalSinceNow < -3600 ? [.hour, .minute] : [.minute]
        formatter.unitsStyle = .full
        let elapsed = formatter.string(from: session.startedAt, to: Date()) ?? ""

        let dialog: IntentDialog
        if let memo = session.memo {
            dialog = IntentDialog("intent.find.statusMemo \(memo) \(elapsed)")
        } else {
            dialog = IntentDialog("intent.find.status \(elapsed)")
        }
        return .result(opensIntent: OpenParkingScreenIntent(), dialog: dialog)
    }
}

/// 앱을 열어 주차 화면(위치가 있으면 지도까지)으로 이동한다. `FindMyCarIntent` 가 이어서 실행한다.
@available(iOS 17.0, *)
struct OpenParkingScreenIntent: AppIntent {
    static var title: LocalizedStringResource = "intent.find.title"
    static var openAppWhenRun = true
    static var isDiscoverable = false

    func perform() async throws -> some IntentResult {
        let hasLocation = ParkingSessionStore.current?.coordinate != nil
        DeepLinkRouter.open(hasLocation ? .map : .parking)
        return .result()
    }
}

@available(iOS 17.0, *)
struct ParkingShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: StartParkingIntent(),
                    phrases: ["Start parking with \(.applicationName)",
                              "\(.applicationName) start parking",
                              "I parked with \(.applicationName)"],
                    shortTitle: "intent.start.shortTitle",
                    systemImageName: "car.fill")
        AppShortcut(intent: EndParkingIntent(),
                    phrases: ["End parking with \(.applicationName)",
                              "\(.applicationName) end parking"],
                    shortTitle: "intent.end.shortTitle",
                    systemImageName: "flag.checkered")
        AppShortcut(intent: FindMyCarIntent(),
                    phrases: ["Where is my car in \(.applicationName)",
                              "Find my car with \(.applicationName)",
                              "\(.applicationName) where did I park"],
                    shortTitle: "intent.find.shortTitle",
                    systemImageName: "location.fill")
    }
}
