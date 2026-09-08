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
        guard link == .map, let parkingVC = presentedViewController as? ParkingViewController else { return }
        parkingVC.showMap()
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

        let stack = UIStackView(arrangedSubviews: [header, photoCard, memoCard, startButton])
        stack.axis = .vertical
        stack.spacing = DS.spacing
        stack.setCustomSpacing(24, after: header)
        view.addSubview(stack)
        stack.pinEdges(to: view.safeAreaLayoutGuide,
                       insets: NSDirectionalEdgeInsets(top: 12, leading: DS.screenPadding,
                                                       bottom: DS.screenPadding, trailing: DS.screenPadding))

        // 사진 카드가 남는 세로 공간을 모두 차지한다.
        photoCard.setContentHuggingPriority(.defaultLow, for: .vertical)
        photoCard.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        photoCard.heightAnchor.constraint(greaterThanOrEqualToConstant: 180).isActive = true
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
        let memo = memoTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let session = ParkingSession(startedAt: Date(),
                                     memo: memo.isEmpty ? nil : memo,
                                     coordinate: locationManager.location?.coordinate)
        ParkingSessionStore.start(session, photo: photoCard.image)

        let parkingVC = ParkingViewController(session: session, photo: photoCard.image)
        present(parkingVC, animated: true) { [weak self] in
            self?.resetForm()
        }
    }

    private func restoreSessionIfNeeded() {
        guard presentedViewController == nil, let session = ParkingSessionStore.current else { return }
        present(ParkingViewController(session: session, photo: CarImageStore.load()), animated: false)
    }

    private func openCamera() {
        let picker = UIImagePickerController()
        // 카메라가 없는 기기(시뮬레이터 등)에서는 사진 앨범으로 대체한다.
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.delegate = self
        present(picker, animated: true)
    }

    private func resetForm() {
        photoCard.image = nil
        memoTextView.text = ""
        memoPlaceholderLabel.isHidden = false
    }
}

// MARK: - UIImagePickerControllerDelegate

extension MainViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let image = info[.originalImage] as? UIImage {
            photoCard.image = image
        }
        picker.dismiss(animated: true)
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
