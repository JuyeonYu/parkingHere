//
//  CarImageStore.swift
//  parkingHere
//

import UIKit

/// 차 사진을 앱 Documents 폴더에 JPEG 파일로 저장한다.
///
/// 이전 버전은 PNG 데이터를 UserDefaults 에 넣었는데, 카메라 원본 PNG 는 수십 MB 라
/// UserDefaults 의 4MB 제한을 넘어 디스크에 기록되지 않았고 앱을 재시작하면 사진이 사라졌다.
enum CarImageStore {
    private static let fileName = "carImage.jpg"
    private static let legacyDefaultsKey = "carImage"
    private static let maxDimension: CGFloat = 2048

    private static var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }

    @discardableResult
    static func save(_ image: UIImage) -> Bool {
        guard let data = normalized(image).jpegData(compressionQuality: 0.85) else { return false }
        do {
            try data.write(to: fileURL, options: .atomic)
            return true
        } catch {
            print("CarImageStore: failed to save image - \(error)")
            return false
        }
    }

    static func load() -> UIImage? {
        if let image = UIImage(contentsOfFile: fileURL.path) {
            return image
        }
        // 이전 버전에서 UserDefaults 에 저장된 사진이 남아 있으면 파일로 옮긴다.
        if let legacyData = UserDefaults.standard.data(forKey: legacyDefaultsKey),
           let image = UIImage(data: legacyData) {
            UserDefaults.standard.removeObject(forKey: legacyDefaultsKey)
            save(image)
            return image
        }
        return nil
    }

    static func delete() {
        try? FileManager.default.removeItem(at: fileURL)
        UserDefaults.standard.removeObject(forKey: legacyDefaultsKey)
    }

    /// EXIF 회전 정보를 픽셀에 반영하고, 너무 큰 사진은 긴 변 기준 `maxDimension` 으로 줄인다.
    private static func normalized(_ image: UIImage) -> UIImage {
        let scale = min(1, maxDimension / max(image.size.width, image.size.height))
        let target = CGSize(width: (image.size.width * scale).rounded(),
                            height: (image.size.height * scale).rounded())
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
    }
}
