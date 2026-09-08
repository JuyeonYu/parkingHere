//
//  DesignSystem.swift
//  parkingHere
//

import UIKit

/// 문자열 로컬라이즈 단축 함수
func L(_ key: String) -> String {
    NSLocalizedString(key, comment: "")
}

/// 앱 전체에서 공유하는 디자인 토큰
enum DS {
    static let screenPadding: CGFloat = 20
    static let spacing: CGFloat = 16
    static let cardRadius: CGFloat = 24
    static let cardPadding: CGFloat = 20
    static let buttonHeight: CGFloat = 56
    static let buttonRadius: CGFloat = 18
    /// iPad 등 넓은 화면에서 콘텐츠가 늘어지지 않도록 하는 최대 폭
    static let maxContentWidth: CGFloat = 600
    /// 남는 세로 공간을 가장 먼저 차지하는 뷰(사진 카드)의 hugging 우선순위
    static let stretchHugging = UILayoutPriority(200)
    /// 사진 카드가 최대 높이에 닿은 뒤 남는 공간을 받는 스페이서의 hugging 우선순위
    static let spacerHugging = UILayoutPriority(240)

    enum Color {
        static let brand = UIColor(named: "BrandYellow")!
        static let onBrand = UIColor(named: "OnBrand")!
        static let background = UIColor.systemGroupedBackground
        static let card = UIColor.secondarySystemGroupedBackground
    }

    enum Font {
        /// Dynamic Type 을 따르는 SF Rounded 서체
        static func rounded(_ style: UIFont.TextStyle, weight: UIFont.Weight = .regular) -> UIFont {
            let size = UIFont.preferredFont(forTextStyle: style).pointSize
            return UIFontMetrics(forTextStyle: style).scaledFont(for: rounded(size: size, weight: weight))
        }

        static func rounded(size: CGFloat, weight: UIFont.Weight) -> UIFont {
            let base = UIFont.systemFont(ofSize: size, weight: weight)
            guard let descriptor = base.fontDescriptor.withDesign(.rounded) else { return base }
            return UIFont(descriptor: descriptor, size: size)
        }

        /// 타이머처럼 숫자 폭이 고정돼야 하는 곳에 쓴다.
        static func timer(size: CGFloat) -> UIFont {
            let base = UIFont.monospacedDigitSystemFont(ofSize: size, weight: .bold)
            guard let descriptor = base.fontDescriptor.withDesign(.rounded) else { return base }
            return UIFont(descriptor: descriptor, size: size)
        }
    }
}

// MARK: - Components

/// 둥근 모서리의 기본 카드
final class CardView: UIView {
    init() {
        super.init(frame: .zero)
        backgroundColor = DS.Color.card
        layer.cornerRadius = DS.cardRadius
        layer.cornerCurve = .continuous
        clipsToBounds = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

/// 브랜드 색 원 안에 SF Symbol 을 넣은 아이콘
final class IconBadgeView: UIView {
    init(systemName: String, size: CGFloat = 48, pointSize: CGFloat = 20) {
        super.init(frame: .zero)
        backgroundColor = DS.Color.brand
        layer.cornerRadius = size / 2

        let imageView = UIImageView(image: UIImage(systemName: systemName))
        imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .semibold)
        imageView.tintColor = DS.Color.onBrand
        imageView.contentMode = .center
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: size),
            heightAnchor.constraint(equalToConstant: size),
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

enum ButtonStyle {
    case primary
    case destructive
}

extension UIButton {
    /// 화면 하단에 놓이는 큰 액션 버튼
    static func make(title: String, systemImage: String? = nil, style: ButtonStyle) -> UIButton {
        var config: UIButton.Configuration
        switch style {
        case .primary:
            config = .filled()
            config.baseBackgroundColor = DS.Color.brand
            config.baseForegroundColor = DS.Color.onBrand
        case .destructive:
            config = .tinted()
            config.baseBackgroundColor = .systemRed
            config.baseForegroundColor = .systemRed
        }
        config.cornerStyle = .fixed
        config.background.cornerRadius = DS.buttonRadius
        config.title = title
        if let systemImage = systemImage {
            config.image = UIImage(systemName: systemImage)
            config.imagePadding = 8
            config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 17, weight: .semibold)
        }
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            attributes.font = DS.Font.rounded(.headline, weight: .semibold)
            return attributes
        }

        let button = UIButton(configuration: config)
        button.heightAnchor.constraint(equalToConstant: DS.buttonHeight).isActive = true
        return button
    }

    /// 지도, 사진 위에 떠 있는 원형 아이콘 버튼
    static func makeFloatingIcon(systemImage: String, onDark: Bool = false) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.cornerStyle = .capsule
        config.image = UIImage(systemName: systemImage)
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        if onDark {
            config.baseBackgroundColor = UIColor.white.withAlphaComponent(0.18)
            config.baseForegroundColor = .white
        } else {
            config.baseBackgroundColor = .systemBackground
            config.baseForegroundColor = .label
        }

        let button = UIButton(configuration: config)
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = onDark ? 0 : 0.12
        button.layer.shadowRadius = 8
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 44),
            button.heightAnchor.constraint(equalToConstant: 44),
        ])
        return button
    }
}

extension UILabel {
    static func make(_ text: String? = nil, font: UIFont, color: UIColor = .label, lines: Int = 1) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = font
        label.textColor = color
        label.numberOfLines = lines
        label.adjustsFontForContentSizeCategory = true
        return label
    }
}

extension UIView {
    /// 스택 끝에 두는 빈 뷰. 사진 카드가 더 못 늘어날 때(iPad) 남는 공간을 흡수한다.
    static func makeSpacer() -> UIView {
        let spacer = UIView()
        spacer.setContentHuggingPriority(DS.spacerHugging, for: .vertical)
        return spacer
    }

    /// 화면 콘텐츠 배치. iPhone 에서는 좌우 여백만 두고, iPad 처럼 넓은 화면에서는 가운데 600pt 컬럼으로 모은다.
    func pinContent(in view: UIView, top: CGFloat = 12, bottom: CGFloat = DS.screenPadding) {
        translatesAutoresizingMaskIntoConstraints = false
        let safe = view.safeAreaLayoutGuide
        let leading = leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: DS.screenPadding)
        let trailing = trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -DS.screenPadding)
        leading.priority = .defaultHigh
        trailing.priority = .defaultHigh
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: safe.topAnchor, constant: top),
            bottomAnchor.constraint(equalTo: safe.bottomAnchor, constant: -bottom),
            centerXAnchor.constraint(equalTo: safe.centerXAnchor),
            widthAnchor.constraint(lessThanOrEqualToConstant: DS.maxContentWidth),
            leading, trailing,
        ])
    }

    func pinEdges(to guide: UILayoutGuide, insets: NSDirectionalEdgeInsets = .zero) {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: guide.topAnchor, constant: insets.top),
            leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: insets.leading),
            trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -insets.trailing),
            bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -insets.bottom),
        ])
    }

    func pinEdges(to view: UIView, insets: NSDirectionalEdgeInsets = .zero) {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: view.topAnchor, constant: insets.top),
            leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: insets.leading),
            trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -insets.trailing),
            bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -insets.bottom),
        ])
    }
}
