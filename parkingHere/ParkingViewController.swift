//
//  ParkingViewController.swift
//  parkingHere
//
//  Created by Juyeon on 2020/12/13.
//

import UIKit

/// 주차 중 화면. 경과 시간을 보여주고 차를 찾거나 주차를 끝낸다.
final class ParkingViewController: UIViewController {
    private let session: ParkingSession
    private let photo: UIImage?

    private let photoCard = CarPhotoCard(placeholderSymbol: "car.fill", placeholderTitle: L("photo.none"))
    private let timerLabel = UILabel.make("00:00:00", font: DS.Font.timer(size: 44))
    private var timer: Timer?

    init(session: ParkingSession, photo: UIImage?) {
        self.session = session
        self.photo = photo
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = DS.Color.background
        buildLayout()

        photoCard.image = photo
        photoCard.addTarget(self, action: #selector(didTapPhotoCard), for: .touchUpInside)
        updateTimer()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
        timer?.tolerance = 0.1
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Layout

    private func buildLayout() {
        let statusDot = UIView()
        statusDot.backgroundColor = .systemGreen
        statusDot.layer.cornerRadius = 5
        NSLayoutConstraint.activate([
            statusDot.widthAnchor.constraint(equalToConstant: 10),
            statusDot.heightAnchor.constraint(equalToConstant: 10),
        ])
        let startedLabel = UILabel.make(String(format: L("parking.startedAt %@"), session.startedAtText()),
                                        font: DS.Font.rounded(.subheadline),
                                        color: .secondaryLabel)
        let statusRow = UIStackView(arrangedSubviews: [statusDot, startedLabel])
        statusRow.spacing = 8
        statusRow.alignment = .center

        let titleLabel = UILabel.make(L("parking.inProgress"), font: DS.Font.rounded(.largeTitle, weight: .bold))
        let header = UIStackView(arrangedSubviews: [titleLabel, statusRow])
        header.axis = .vertical
        header.spacing = 6
        header.alignment = .leading

        let timerCard = CardView()
        let elapsedCaption = UILabel.make(L("parking.elapsed"),
                                          font: DS.Font.rounded(.footnote, weight: .semibold),
                                          color: .secondaryLabel)
        timerLabel.adjustsFontSizeToFitWidth = true
        timerLabel.minimumScaleFactor = 0.6
        let timerStack = UIStackView(arrangedSubviews: [elapsedCaption, timerLabel])
        timerStack.axis = .vertical
        timerStack.spacing = 2
        timerCard.addSubview(timerStack)
        timerStack.pinEdges(to: timerCard, insets: NSDirectionalEdgeInsets(top: 16, leading: DS.cardPadding,
                                                                          bottom: 16, trailing: DS.cardPadding))

        let findButton = UIButton.make(title: L("parking.findCar"), systemImage: "location.fill", style: .primary)
        findButton.addTarget(self, action: #selector(didTapFindCar), for: .touchUpInside)
        let endButton = UIButton.make(title: L("parking.end"), systemImage: "flag.checkered", style: .destructive)
        endButton.addTarget(self, action: #selector(didTapEnd), for: .touchUpInside)

        var arranged: [UIView] = [header, photoCard, timerCard]
        if let memo = session.memo {
            arranged.append(makeMemoCard(memo))
        }
        arranged += [findButton, endButton]

        let stack = UIStackView(arrangedSubviews: arranged)
        stack.axis = .vertical
        stack.spacing = DS.spacing
        stack.setCustomSpacing(24, after: header)
        stack.setCustomSpacing(12, after: findButton)
        view.addSubview(stack)
        stack.pinEdges(to: view.safeAreaLayoutGuide,
                       insets: NSDirectionalEdgeInsets(top: 12, leading: DS.screenPadding,
                                                       bottom: DS.screenPadding, trailing: DS.screenPadding))

        photoCard.setContentHuggingPriority(.defaultLow, for: .vertical)
        photoCard.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        photoCard.heightAnchor.constraint(greaterThanOrEqualToConstant: 140).isActive = true
    }

    private func makeMemoCard(_ memo: String) -> UIView {
        let card = CardView()
        let icon = IconBadgeView(systemName: "note.text", size: 36, pointSize: 15)
        let label = UILabel.make(memo, font: DS.Font.rounded(.body), lines: 3)
        let row = UIStackView(arrangedSubviews: [icon, label])
        row.spacing = 12
        row.alignment = .center
        card.addSubview(row)
        row.pinEdges(to: card, insets: NSDirectionalEdgeInsets(top: 14, leading: DS.cardPadding,
                                                              bottom: 14, trailing: DS.cardPadding))
        return card
    }

    // MARK: - Actions

    private func updateTimer() {
        timerLabel.text = session.elapsedText()
    }

    @objc private func didTapPhotoCard() {
        guard let photo = photo else { return }
        present(ImageDetailViewController(image: photo), animated: true)
    }

    @objc private func didTapFindCar() {
        guard session.coordinate != nil else {
            presentLocationUnavailableAlert()
            return
        }
        present(MapViewController(session: session), animated: true)
    }

    /// 딥링크로 지도를 연다. 이미 다른 화면이 떠 있으면 그대로 둔다.
    func showMap() {
        guard presentedViewController == nil else { return }
        didTapFindCar()
    }

    @objc private func didTapEnd() {
        let alert = UIAlertController(title: L("parking.endConfirm.title"),
                                      message: L("parking.endConfirm.message"),
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L("common.cancel"), style: .cancel))
        alert.addAction(UIAlertAction(title: L("parking.end"), style: .destructive) { _ in
            // 화면 닫기는 세션 변경 알림을 받은 MainViewController 가 맡는다.
            ParkingSessionStore.end()
        })
        present(alert, animated: true)
    }

    private func presentLocationUnavailableAlert() {
        let alert = UIAlertController(title: L("location.unavailable.title"),
                                      message: L("location.unavailable.message"),
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L("common.settings"), style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        alert.addAction(UIAlertAction(title: L("common.ok"), style: .cancel))
        present(alert, animated: true)
    }
}
