//
//  MapViewController.swift
//  parkingHere
//
//  Created by Juyeon on 2020/12/15.
//

import UIKit
import MapKit

/// 주차 위치와 현재 위치를 지도에 보여주고, 애플 지도 도보 길찾기로 연결한다.
final class MapViewController: UIViewController {
    private let session: ParkingSession
    private let carCoordinate: CLLocationCoordinate2D

    private let mapView = MKMapView()
    private let distanceLabel = UILabel.make(font: DS.Font.rounded(.footnote), color: .secondaryLabel)
    private var didFitBothLocations = false

    init(session: ParkingSession) {
        self.session = session
        self.carCoordinate = session.coordinate ?? CLLocationCoordinate2D()
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        buildLayout()

        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.pointOfInterestFilter = .excludingAll

        let annotation = MKPointAnnotation()
        annotation.coordinate = carCoordinate
        annotation.title = L("map.title")
        annotation.subtitle = session.memo
        mapView.addAnnotation(annotation)
        mapView.setRegion(MKCoordinateRegion(center: carCoordinate, latitudinalMeters: 300, longitudinalMeters: 300),
                          animated: false)
    }

    // MARK: - Layout

    private func buildLayout() {
        view.addSubview(mapView)
        mapView.pinEdges(to: view)

        let closeButton = UIButton.makeFloatingIcon(systemImage: "xmark")
        closeButton.addTarget(self, action: #selector(didTapClose), for: .touchUpInside)
        let locateButton = UIButton.makeFloatingIcon(systemImage: "location.fill")
        locateButton.addTarget(self, action: #selector(didTapLocate), for: .touchUpInside)

        let infoCard = CardView()
        infoCard.layer.shadowColor = UIColor.black.cgColor
        infoCard.layer.shadowOpacity = 0.12
        infoCard.layer.shadowRadius = 16
        infoCard.layer.shadowOffset = CGSize(width: 0, height: 4)
        infoCard.clipsToBounds = false

        let titleLabel = UILabel.make(L("map.title"), font: DS.Font.rounded(.headline, weight: .semibold))
        let subtitle = session.memo ?? String(format: L("parking.startedAt %@"), session.startedAtText())
        let subtitleLabel = UILabel.make(subtitle, font: DS.Font.rounded(.subheadline), color: .secondaryLabel, lines: 2)
        distanceLabel.isHidden = true
        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel, distanceLabel])
        textStack.axis = .vertical
        textStack.spacing = 2

        let infoRow = UIStackView(arrangedSubviews: [IconBadgeView(systemName: "car.fill"), textStack])
        infoRow.spacing = 14
        infoRow.alignment = .center

        let directionsButton = UIButton.make(title: L("map.directions"), systemImage: "figure.walk", style: .primary)
        directionsButton.addTarget(self, action: #selector(didTapDirections), for: .touchUpInside)

        let cardStack = UIStackView(arrangedSubviews: [infoRow, directionsButton])
        cardStack.axis = .vertical
        cardStack.spacing = DS.spacing
        infoCard.addSubview(cardStack)
        cardStack.pinEdges(to: infoCard, insets: NSDirectionalEdgeInsets(top: DS.cardPadding, leading: DS.cardPadding,
                                                                        bottom: DS.cardPadding, trailing: DS.cardPadding))

        [closeButton, locateButton, infoCard].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        let safe = view.safeAreaLayoutGuide
        let cardLeading = infoCard.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: DS.screenPadding)
        let cardTrailing = infoCard.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -DS.screenPadding)
        cardLeading.priority = .defaultHigh
        cardTrailing.priority = .defaultHigh
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: safe.topAnchor, constant: 12),
            closeButton.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: DS.screenPadding),
            locateButton.topAnchor.constraint(equalTo: safe.topAnchor, constant: 12),
            locateButton.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -DS.screenPadding),
            infoCard.centerXAnchor.constraint(equalTo: safe.centerXAnchor),
            infoCard.widthAnchor.constraint(lessThanOrEqualToConstant: DS.maxContentWidth),
            cardLeading, cardTrailing,
            infoCard.bottomAnchor.constraint(equalTo: safe.bottomAnchor, constant: -DS.screenPadding),
        ])
    }

    // MARK: - Actions

    @objc private func didTapClose() {
        dismiss(animated: true)
    }

    @objc private func didTapLocate() {
        mapView.setUserTrackingMode(.follow, animated: true)
    }

    @objc private func didTapDirections() {
        let placemark = MKPlacemark(coordinate: carCoordinate)
        let item = MKMapItem(placemark: placemark)
        item.name = L("map.title")
        item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking])
    }

    /// 차와 사용자가 모두 보이도록 한 번만 화면을 맞춘다.
    private func fitBothLocationsIfNeeded(userCoordinate: CLLocationCoordinate2D, distance: CLLocationDistance) {
        guard !didFitBothLocations else { return }
        didFitBothLocations = true
        // 바로 옆에 있으면 기본 축척(300m)이 더 보기 좋다.
        guard distance > 100 else { return }

        let carPoint = MKMapPoint(carCoordinate)
        let userPoint = MKMapPoint(userCoordinate)
        let rect = MKMapRect(x: min(carPoint.x, userPoint.x),
                             y: min(carPoint.y, userPoint.y),
                             width: abs(carPoint.x - userPoint.x),
                             height: abs(carPoint.y - userPoint.y))
        let padding = UIEdgeInsets(top: 100, left: 60, bottom: 260, right: 60)
        mapView.setVisibleMapRect(rect, edgePadding: padding, animated: true)
    }
}

// MARK: - MKMapViewDelegate

extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !(annotation is MKUserLocation) else { return nil }
        let identifier = "car"
        let view = (mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView)
            ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        view.annotation = annotation
        view.markerTintColor = DS.Color.brand
        view.glyphImage = UIImage(systemName: "car.fill")
        view.glyphTintColor = DS.Color.onBrand
        view.canShowCallout = true
        view.displayPriority = .required
        return view
    }

    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        guard let location = userLocation.location else { return }
        let distance = location.distance(from: CLLocation(latitude: carCoordinate.latitude,
                                                          longitude: carCoordinate.longitude))
        let formatter = MKDistanceFormatter()
        formatter.unitStyle = .abbreviated
        distanceLabel.text = String(format: L("map.distance %@"), formatter.string(fromDistance: distance))
        distanceLabel.isHidden = false
        fitBothLocationsIfNeeded(userCoordinate: location.coordinate, distance: distance)
    }
}
