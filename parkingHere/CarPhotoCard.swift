//
//  CarPhotoCard.swift
//  parkingHere
//

import UIKit

/// 차 사진 카드. 사진이 있으면 둥근 사각형에 꽉 채워 보여주고,
/// 없으면 아이콘과 안내 문구를 보여준다. 탭하면 `.touchUpInside` 이벤트를 보낸다.
final class CarPhotoCard: UIControl {
    var image: UIImage? {
        didSet {
            imageView.image = image
            placeholderStack.isHidden = hasPhoto
            accessoryButton.isHidden = !hasPhoto || !showsAccessoryWhenPhoto
        }
    }

    var hasPhoto: Bool { image != nil }

    /// 사진이 있을 때 오른쪽 아래에 보여줄 버튼 사용 여부
    var showsAccessoryWhenPhoto = false {
        didSet { accessoryButton.isHidden = !hasPhoto || !showsAccessoryWhenPhoto }
    }

    let accessoryButton = UIButton.makeFloatingIcon(systemImage: "camera.fill")

    private let imageView = UIImageView()
    private let placeholderStack = UIStackView()

    init(placeholderSymbol: String, placeholderTitle: String, placeholderSubtitle: String? = nil) {
        super.init(frame: .zero)

        backgroundColor = DS.Color.card
        layer.cornerRadius = DS.cardRadius
        layer.cornerCurve = .continuous
        clipsToBounds = true
        isAccessibilityElement = true
        accessibilityLabel = placeholderTitle

        imageView.contentMode = .scaleAspectFill
        imageView.isUserInteractionEnabled = false
        // 원본 사진 크기가 레이아웃에 영향을 주지 않도록 한다.
        for axis in [NSLayoutConstraint.Axis.horizontal, .vertical] {
            imageView.setContentHuggingPriority(UILayoutPriority(1), for: axis)
            imageView.setContentCompressionResistancePriority(UILayoutPriority(1), for: axis)
        }
        addSubview(imageView)
        imageView.pinEdges(to: self)

        let titleLabel = UILabel.make(placeholderTitle,
                                      font: DS.Font.rounded(.headline, weight: .semibold))
        titleLabel.textAlignment = .center
        placeholderStack.axis = .vertical
        placeholderStack.alignment = .center
        placeholderStack.spacing = 6
        placeholderStack.isUserInteractionEnabled = false
        placeholderStack.addArrangedSubview(IconBadgeView(systemName: placeholderSymbol, size: 64, pointSize: 26))
        placeholderStack.setCustomSpacing(14, after: placeholderStack.arrangedSubviews[0])
        placeholderStack.addArrangedSubview(titleLabel)
        if let subtitle = placeholderSubtitle {
            let subtitleLabel = UILabel.make(subtitle,
                                             font: DS.Font.rounded(.subheadline),
                                             color: .secondaryLabel,
                                             lines: 0)
            subtitleLabel.textAlignment = .center
            placeholderStack.addArrangedSubview(subtitleLabel)
        }
        addSubview(placeholderStack)
        placeholderStack.translatesAutoresizingMaskIntoConstraints = false

        accessoryButton.isHidden = true
        addSubview(accessoryButton)
        accessoryButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            placeholderStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            placeholderStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            placeholderStack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: DS.cardPadding),
            trailingAnchor.constraint(greaterThanOrEqualTo: placeholderStack.trailingAnchor, constant: DS.cardPadding),
            accessoryButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            accessoryButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.15) {
                self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.985, y: 0.985) : .identity
                self.alpha = self.isHighlighted ? 0.92 : 1
            }
        }
    }
}
