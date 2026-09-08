//
//  OneShotLocation.swift
//  parkingHere
//

import CoreLocation

/// 현재 위치를 한 번만 구한다. App Intent 처럼 화면 없이 도는 곳에서 쓴다.
///
/// 최근 위치가 캐시돼 있으면 그것을 쓰고, 아니면 잠깐 기다려 새 위치를 받는다.
/// 백그라운드에서 '앱 사용 중' 권한만으로는 새 위치가 오지 않을 수 있어서 제한 시간을 둔다.
@MainActor
final class OneShotLocation: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocation?, Never>?

    func request(timeout: TimeInterval = 4, freshness: TimeInterval = 120) async -> CLLocation? {
        if let cached = manager.location, Date().timeIntervalSince(cached.timestamp) < freshness {
            return cached
        }
        let status = manager.authorizationStatus
        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            return nil
        }

        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            manager.delegate = self
            manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            manager.requestLocation()
            DispatchQueue.main.asyncAfter(deadline: .now() + timeout) { [weak self] in
                self?.finish(with: self?.manager.location)
            }
        }
    }

    private func finish(with location: CLLocation?) {
        guard let continuation = continuation else { return }
        self.continuation = nil
        manager.delegate = nil
        continuation.resume(returning: location)
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in self.finish(with: locations.last) }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in self.finish(with: self.manager.location) }
    }
}
