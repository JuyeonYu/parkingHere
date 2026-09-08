//
//  ParkingSession.swift
//  parkingHere
//

import UIKit
import CoreLocation

/// 진행 중인 주차 한 건
struct ParkingSession {
    var startedAt: Date
    var memo: String?
    var coordinate: CLLocationCoordinate2D?

    func elapsedText(at now: Date = Date()) -> String {
        let seconds = max(0, Int(now.timeIntervalSince(startedAt)))
        return String(format: "%02d:%02d:%02d", seconds / 3600, (seconds % 3600) / 60, seconds % 60)
    }

    func startedAtText() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = Calendar.current.isDateInToday(startedAt) ? .none : .medium
        formatter.doesRelativeDateFormatting = true
        return formatter.string(from: startedAt)
    }
}

extension Notification.Name {
    /// 주차가 시작되거나 끝났을 때. App Intent 등 화면 밖에서 바뀐 경우 UI 가 따라가도록 한다.
    static let parkingSessionDidChange = Notification.Name("parkingSessionDidChange")
}

/// 주차 정보 저장소. 사진은 `CarImageStore`, 나머지는 UserDefaults 에 둔다.
/// 키 이름은 이전 버전과 같아서 업데이트 후에도 진행 중인 주차가 유지된다.
enum ParkingSessionStore {
    private static let defaults = UserDefaults.standard

    private enum Key {
        static let isParking = "isParking"
        static let startedAt = "parkingTime"
        static let memo = "memo"
        static let latitude = "latitude"
        static let longitude = "longitude"
    }

    static var current: ParkingSession? {
        guard defaults.bool(forKey: Key.isParking) else { return nil }
        let startedAt = defaults.object(forKey: Key.startedAt) as? Date ?? Date()
        let memo = defaults.string(forKey: Key.memo).flatMap { $0.isEmpty ? nil : $0 }
        var coordinate: CLLocationCoordinate2D?
        let latitude = defaults.double(forKey: Key.latitude)
        let longitude = defaults.double(forKey: Key.longitude)
        if latitude != 0 || longitude != 0 {
            coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        return ParkingSession(startedAt: startedAt, memo: memo, coordinate: coordinate)
    }

    static func start(_ session: ParkingSession, photo: UIImage?) {
        defaults.set(true, forKey: Key.isParking)
        defaults.set(session.startedAt, forKey: Key.startedAt)
        defaults.set(session.memo, forKey: Key.memo)
        defaults.set(session.coordinate?.latitude, forKey: Key.latitude)
        defaults.set(session.coordinate?.longitude, forKey: Key.longitude)

        if let photo = photo {
            CarImageStore.save(photo)
        } else {
            CarImageStore.delete()
        }
        ParkingActivityController.start(session)
        notifyChange()
    }

    static func end() {
        [Key.isParking, Key.startedAt, Key.memo, Key.latitude, Key.longitude]
            .forEach { defaults.removeObject(forKey: $0) }
        CarImageStore.delete()
        ParkingActivityController.endAll()
        notifyChange()
    }

    /// 호출한 쪽의 화면 전환이 먼저 끝나도록 다음 런루프에 알린다.
    private static func notifyChange() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .parkingSessionDidChange, object: nil)
        }
    }
}
