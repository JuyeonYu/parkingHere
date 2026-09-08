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

    init?(url: URL) {
        guard url.scheme == Self.scheme else { return nil }
        switch url.host {
        case "parking": self = .parking
        case "map": self = .map
        default: return nil
        }
    }

    var url: URL {
        switch self {
        case .parking: return URL(string: "\(Self.scheme)://parking")!
        case .map: return URL(string: "\(Self.scheme)://map")!
        }
    }
}
