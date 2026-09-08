//
//  MainViewController.swift
//  parkingHere
//
//  Created by Juyeon on 2020/12/13.
//

import UIKit
import CoreLocation

/// 첫 화면. 사진과 메모를 받아 주차를 시작한다.
final class MainViewController: UIViewController {
    private let photoCard = CarPhotoCard(placeholderSymbol: "camera.fill",
                                         placeholderTitle: L("photo.add"),
                                         placeholderSubtitle: L("photo.hint"))
    private let memoTextView = UITextView()
    private let memoPlaceholderLabel = UILabel.make(L("memo.placeholder"),
                                                    font: DS.Font.rounded(.body),
                                                    color: .placeholderText)
    private let startButton = UIButton.make(title: L("parking.start"), systemImage: "car.fill", style: .primary)
    private let locationManager = CLLocationManager()
    private let photoPicker = PhotoPicker()
    /// 첫 viewDidAppear 전에 들어온 딥링크. 화면이 뜬 뒤 처리한다.
    private var pendingDeepLink: DeepLink?
    private var hasAppeared = false

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = DS.Color.background
        buildLayout()

        photoCard.showsAccessoryWhenPhoto = true
        photoCard.addTarget(self, action: #selector(didTapPhotoCard), for: .touchUpInside)
        photoCard.accessoryButton.menu = photoMenu()
        photoCard.accessoryButton.showsMenuAsPrimaryAction = true
        startButton.addTarget(self, action: #selector(didTapStart), for: .touchUpInside)
        memoTextView.delegate = self

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sessionDidChange),
                                               name: .parkingSessionDidChange,
                                               object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        locationManager.startUpdatingLocation()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        hasAppeared = true
        // 앱을 완전히 종료했다 다시 켰을 때 진행 중인 주차 화면으로 복귀한다.
        restoreSessionIfNeeded()
        ParkingActivityController.sync(with: ParkingSessionStore.current)
        if let link = pendingDeepLink {
            pendingDeepLink = nil
            handle(link)
        }
    }

    /// 라이브 액티비티 등에서 열린 딥링크를 처리한다.
    func handle(_ link: DeepLink) {
        guard hasAppeared else {
            pendingDeepLink = link
            return
        }
        restoreSessionIfNeeded()
        guard let parkingVC = presentedViewController as? ParkingViewController else { return }
        switch link {
        case .parking: break
        case .map: parkingVC.showMap()
        case .photo: parkingVC.presentPhotoPicker()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        locationManager.stopUpdatingLocation()
    }

    // MARK: - Layout

    private func buildLayout() {
        let titleLabel = UILabel.make(L("app.title"), font: DS.Font.rounded(.largeTitle, weight: .bold))
        let subtitleLabel = UILabel.make(L("main.subtitle"),
                                         font: DS.Font.rounded(.subheadline),
                                         color: .secondaryLabel,
                                         lines: 0)
        let titles = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        titles.axis = .vertical
        titles.spacing = 4

        let automationButton = UIButton.makeFloatingIcon(systemImage: "wand.and.stars")
        automationButton.accessibilityLabel = L("guide.title")
        automationButton.addTarget(self, action: #selector(didTapAutomation), for: .touchUpInside)

        let header = UIStackView(arrangedSubviews: [titles, automationButton])
        header.spacing = 12
        header.alignment = .top

        let memoCard = CardView()
        memoTextView.backgroundColor = .clear
        memoTextView.font = DS.Font.rounded(.body)
        memoTextView.adjustsFontForContentSizeCategory = true
        memoTextView.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        memoTextView.textContainer.lineFragmentPadding = 0
        memoTextView.returnKeyType = .done
        memoCard.addSubview(memoTextView)
        memoTextView.pinEdges(to: memoCard)
        memoCard.addSubview(memoPlaceholderLabel)
        memoPlaceholderLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            memoPlaceholderLabel.topAnchor.constraint(equalTo: memoCard.topAnchor, constant: 16),
            memoPlaceholderLabel.leadingAnchor.constraint(equalTo: memoCard.leadingAnchor, constant: 16),
            memoPlaceholderLabel.trailingAnchor.constraint(lessThanOrEqualTo: memoCard.trailingAnchor, constant: -16),
            memoCard.heightAnchor.constraint(equalToConstant: 112),
        ])

        let stack = UIStackView(arrangedSubviews: [header, photoCard, memoCard, startButton, UIView.makeSpacer()])
        stack.axis = .vertical
        stack.spacing = DS.spacing
        stack.setCustomSpacing(24, after: header)
        stack.setCustomSpacing(0, after: startButton)
        view.addSubview(stack)
        stack.pinContent(in: view)

        // 사진 카드가 남는 세로 공간을 모두 차지한다.
        photoCard.setContentHuggingPriority(DS.stretchHugging, for: .vertical)
        photoCard.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        photoCard.heightAnchor.constraint(greaterThanOrEqualToConstant: 180).isActive = true
        // iPad 처럼 세로 공간이 넉넉해도 사진 카드가 지나치게 길어지지 않게 한다.
        photoCard.heightAnchor.constraint(lessThanOrEqualTo: photoCard.widthAnchor, multiplier: 1.3).isActive = true
    }

    private func photoMenu() -> UIMenu {
        UIMenu(children: [
            UIAction(title: L("photo.retake"), image: UIImage(systemName: "camera")) { [weak self] _ in
                self?.openCamera()
            },
            UIAction(title: L("photo.remove"), image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
                self?.photoCard.image = nil
            },
        ])
    }

    // MARK: - Actions

    @objc private func didTapPhotoCard() {
        if let image = photoCard.image {
            present(ImageDetailViewController(image: image), animated: true)
        } else {
            openCamera()
        }
    }

    @objc private func didTapAutomation() {
        present(AutomationGuideViewController(), animated: true)
    }

    /// 주차 상태가 화면 밖(Siri, 단축어, 주차 종료 버튼)에서 바뀌면 화면을 맞춘다.
    @objc private func sessionDidChange() {
        guard hasAppeared else { return }
        if ParkingSessionStore.current == nil {
            if presentedViewController is ParkingViewController {
                dismiss(animated: true)
            }
        } else {
            restoreSessionIfNeeded()
        }
    }

    @objc private func didTapStart() {
        view.endEditing(true)
        startButton.isEnabled = false
        let memo = memoTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let photo = photoCard.image

        Task { @MainActor [weak self] in
            guard let self = self else { return }
            // 앱을 열자마자 눌렀거나 사진을 찍고 돌아온 직후라 아직 위치가 없으면 잠깐 기다려 받아 온다.
            var coordinate = self.locationManager.location?.coordinate
            if coordinate == nil {
                coordinate = await OneShotLocation().request(timeout: 3)?.coordinate
            }
            self.startButton.isEnabled = true

            let session = ParkingSession(startedAt: Date(), memo: memo.isEmpty ? nil : memo, coordinate: coordinate)
            ParkingSessionStore.start(session, photo: photo)

            let parkingVC = ParkingViewController(session: session, photo: photo)
            self.present(parkingVC, animated: true) { [weak self] in
                self?.resetForm()
            }
        }
    }

    private func restoreSessionIfNeeded() {
        guard presentedViewController == nil, let session = ParkingSessionStore.current else { return }
        present(ParkingViewController(session: session, photo: CarImageStore.load()), animated: false)
    }

    private func openCamera() {
        photoPicker.present(from: self) { [weak self] image in
            guard let image = image else { return }
            self?.photoCard.image = image
        }
    }

    private func resetForm() {
        photoCard.image = nil
        memoTextView.text = ""
        memoPlaceholderLabel.isHidden = false
    }
}

// MARK: - UITextViewDelegate

extension MainViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        memoPlaceholderLabel.isHidden = !textView.text.isEmpty
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
}

// MARK: - CLLocationManagerDelegate

extension MainViewController: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        default:
            break
        }
    }
}
