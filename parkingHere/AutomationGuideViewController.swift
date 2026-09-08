//
//  AutomationGuideViewController.swift
//  parkingHere
//
//  단축어 자동화로 주차를 자동 시작하는 방법을 안내한다.
//

import UIKit

final class AutomationGuideViewController: UIViewController {
    init() {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .pageSheet
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = DS.Color.background

        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        scrollView.pinEdges(to: view)

        let titleLabel = UILabel.make(L("guide.title"), font: DS.Font.rounded(.title1, weight: .bold), lines: 0)
        let subtitleLabel = UILabel.make(L("guide.subtitle"),
                                         font: DS.Font.rounded(.subheadline),
                                         color: .secondaryLabel,
                                         lines: 0)
        let header = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        header.axis = .vertical
        header.spacing = 6

        let steps = (1...4).map { makeStepCard(number: $0, text: L("guide.step\($0)")) }

        let openButton = UIButton.make(title: L("guide.openShortcuts"), systemImage: "arrow.up.forward.app", style: .primary)
        openButton.addTarget(self, action: #selector(didTapOpenShortcuts), for: .touchUpInside)

        let tipCard = makeTipCard(L("guide.siriTip"))

        var arranged: [UIView] = [header]
        if #unavailable(iOS 17.2) {
            arranged.append(makeTipCard(L("guide.requiresIOS17"), symbol: "exclamationmark.triangle.fill"))
        }
        arranged += steps
        arranged += [openButton, tipCard]

        let stack = UIStackView(arrangedSubviews: arranged)
        stack.axis = .vertical
        stack.spacing = 12
        stack.setCustomSpacing(24, after: header)
        stack.setCustomSpacing(24, after: steps[steps.count - 1])
        scrollView.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        let leading = stack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: DS.screenPadding)
        let trailing = stack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -DS.screenPadding)
        leading.priority = .defaultHigh
        trailing.priority = .defaultHigh
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 28),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -DS.screenPadding),
            stack.centerXAnchor.constraint(equalTo: scrollView.frameLayoutGuide.centerXAnchor),
            stack.widthAnchor.constraint(lessThanOrEqualToConstant: DS.maxContentWidth),
            leading, trailing,
        ])

        let closeButton = UIButton.makeFloatingIcon(systemImage: "xmark")
        closeButton.addTarget(self, action: #selector(didTapClose), for: .touchUpInside)
        view.addSubview(closeButton)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -DS.screenPadding),
        ])
        // 제목이 닫기 버튼과 겹치지 않게 한다.
        titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: closeButton.leadingAnchor, constant: -8).isActive = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 자동 시작 뒤 사진 알림을 보내려면 알림 권한이 필요하다.
        ParkingReminder.requestAuthorizationIfNeeded()
    }

    private func makeStepCard(number: Int, text: String) -> UIView {
        let card = CardView()
        let badge = UILabel.make("\(number)", font: DS.Font.rounded(size: 15, weight: .bold), color: DS.Color.onBrand)
        badge.textAlignment = .center
        badge.backgroundColor = DS.Color.brand
        badge.layer.cornerRadius = 14
        badge.clipsToBounds = true
        NSLayoutConstraint.activate([
            badge.widthAnchor.constraint(equalToConstant: 28),
            badge.heightAnchor.constraint(equalToConstant: 28),
        ])
        let label = UILabel.make(text, font: DS.Font.rounded(.body), lines: 0)
        let row = UIStackView(arrangedSubviews: [badge, label])
        row.spacing = 12
        row.alignment = .top
        card.addSubview(row)
        row.pinEdges(to: card, insets: NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
        return card
    }

    private func makeTipCard(_ text: String, symbol: String = "mic.fill") -> UIView {
        let card = CardView()
        let icon = IconBadgeView(systemName: symbol, size: 36, pointSize: 15)
        let label = UILabel.make(text, font: DS.Font.rounded(.subheadline), color: .secondaryLabel, lines: 0)
        let row = UIStackView(arrangedSubviews: [icon, label])
        row.spacing = 12
        row.alignment = .center
        card.addSubview(row)
        row.pinEdges(to: card, insets: NSDirectionalEdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16))
        return card
    }

    @objc private func didTapOpenShortcuts() {
        guard let url = URL(string: "shortcuts://") else { return }
        UIApplication.shared.open(url)
    }

    @objc private func didTapClose() {
        dismiss(animated: true)
    }
}
