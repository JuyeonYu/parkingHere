//
//  CarImageView.swift
//  parkingHere
//

import UIKit

/// 차 사진 카드. 둥근 사각형 안에 사진을 꽉 채워 보여주고,
/// 사진이 없을 때는 연한 배경 위에 `car.fill` 플레이스홀더를 보여준다.
final class CarImageView: UIImageView {
    static let placeholder = UIImage(systemName: "car.fill")
    static let cornerRadius: CGFloat = 24

    /// 플레이스홀더가 아닌 실제 사진이 들어 있는지
    var hasPhoto: Bool {
        guard let image = image else { return false }
        return !image.isSymbolImage
    }

    override var image: UIImage? {
        didSet { updateAppearance() }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        clipsToBounds = true
        layer.cornerRadius = Self.cornerRadius
        layer.cornerCurve = .continuous
        updateAppearance()
    }

    func showPlaceholder() {
        image = Self.placeholder
    }

    private func updateAppearance() {
        contentMode = hasPhoto ? .scaleAspectFill : .scaleAspectFit
        backgroundColor = hasPhoto ? .clear : .secondarySystemBackground
    }
}
