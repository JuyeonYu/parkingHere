//
//  DeepLink.swift
//  parkingHere
//

import Foundation

/// `parkinghere://` URL 스킴. 라이브 액티비티에서 앱을 열 때 쓴다.
enum DeepLink: Equatable {
    static let scheme = "parkinghere"

    /// 주차 중 화면
    case parking
    /// 주차 중 화면 위에 지도까지 연다
    case map
    /// 주차 중 화면에서 사진 추가(카메라)를 연다
    case photo

    init?(url: URL) {
        guard url.scheme == Self.scheme else { return nil }
        switch url.host {
        case "parking": self = .parking
        case "map": self = .map
        case "photo": self = .photo
        default: return nil
        }
    }

    var url: URL {
        switch self {
        case .parking: return URL(string: "\(Self.scheme)://parking")!
        case .map: return URL(string: "\(Self.scheme)://map")!
        case .photo: return URL(string: "\(Self.scheme)://photo")!
        }
    }
}

/// 앱 프로세스 안(App Intent 등)에서 화면 이동을 요청할 때 쓴다. SceneDelegate 가 handler 를 등록한다.
enum DeepLinkRouter {
    static var handler: ((DeepLink) -> Void)?

    static func open(_ link: DeepLink) {
        DispatchQueue.main.async { handler?(link) }
    }
}
