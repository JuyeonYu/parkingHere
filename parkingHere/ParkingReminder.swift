//
//  ParkingReminder.swift
//  parkingHere
//

import UserNotifications

/// 자동으로 시작된 주차에 "사진을 남길까요?" 알림을 보낸다.
enum ParkingReminder {
    static let categoryIdentifier = "PARKING_ADD_PHOTO"
    static let addPhotoActionIdentifier = "ADD_PHOTO"
    private static let requestIdentifier = "parking.addPhoto"

    static func registerCategories() {
        let addPhoto = UNNotificationAction(identifier: addPhotoActionIdentifier,
                                            title: L("notification.addPhoto.action"),
                                            options: [.foreground])
        let category = UNNotificationCategory(identifier: categoryIdentifier,
                                              actions: [addPhoto],
                                              intentIdentifiers: [],
                                              options: [])
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    /// 자동화 가이드처럼 알림이 필요한 이유가 분명한 순간에 정식으로 권한을 요청한다.
    static func requestAuthorizationIfNeeded() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined || settings.authorizationStatus == .provisional else { return }
            center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
        }
    }

    /// 사진 없이 주차가 시작됐을 때 호출한다. 권한이 없으면 조용히 알림 센터에만 들어가는 임시 권한을 쓴다.
    static func scheduleAddPhoto() async {
        let center = UNUserNotificationCenter.current()
        var settings = await center.notificationSettings()
        if settings.authorizationStatus == .notDetermined {
            _ = try? await center.requestAuthorization(options: [.alert, .sound, .provisional])
            settings = await center.notificationSettings()
        }
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else { return }

        let content = UNMutableNotificationContent()
        content.title = L("notification.addPhoto.title")
        content.body = L("notification.addPhoto.body")
        content.sound = .default
        content.categoryIdentifier = categoryIdentifier
        content.userInfo = ["deepLink": DeepLink.photo.url.absoluteString]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        let request = UNNotificationRequest(identifier: requestIdentifier, content: content, trigger: trigger)
        try? await center.add(request)
    }

    static func cancelAddPhoto() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [requestIdentifier])
        center.removeDeliveredNotifications(withIdentifiers: [requestIdentifier])
    }
}
