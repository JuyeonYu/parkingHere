//
//  ViewController.swift
//  parkingHere
//
//  Created by Juyeon on 2020/12/13.
//

import UIKit
import CoreLocation

class MainViewController: UIViewController {
    @IBOutlet weak var carImageView: CarImageView!
    @IBOutlet weak var memoTextField: UITextView!
    @IBOutlet weak var startParkingButton: UIButton!
    @IBOutlet weak var addCarButton: UIButton!
    @IBOutlet weak var resetCarButton: UIButton!
    
    var locationManager: CLLocationManager?
    
    @IBAction func didTapResetCarButton(_ sender: Any) {
        let optionMenu = UIAlertController(title: nil, message: NSLocalizedString("choose option", comment: ""), preferredStyle: .actionSheet)

        let deleteAction = UIAlertAction(title: NSLocalizedString("camera", comment: ""), style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.openCamera()
        })
        
        let resetAction = UIAlertAction(title: NSLocalizedString("reset", comment: ""), style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.carImageView.showPlaceholder()
            self.updateCarButtons()
        })
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel, handler: {
            (alert: UIAlertAction!) -> Void in
      })
        optionMenu.addAction(deleteAction)
        optionMenu.addAction(resetAction)
        optionMenu.addAction(cancelAction)
        
        self.present(optionMenu, animated: true, completion: nil)
    }
    
    @IBAction func didTabAddCarButton(_ sender: Any) {
        self.openCamera()
    }
    
    fileprivate func saveParkingInformation() {
        UserDefaults.standard.set(true, forKey: "isParking")
        UserDefaults.standard.set(Date(), forKey: "parkingTime")
        
        if memoTextField.text != NSLocalizedString("memo", comment: "") {
            UserDefaults.standard.set(memoTextField.text, forKey: "memo")
        } else {
            UserDefaults.standard.removeObject(forKey: "memo")
        }
        
        // 사진은 UserDefaults 가 아니라 파일로 저장한다. (재시작 후 사진 유실 버그 수정)
        if carImageView.hasPhoto, let image = carImageView.image {
            CarImageStore.save(image)
        } else {
            CarImageStore.delete()
        }
        
        UserDefaults.standard.set(locationManager?.location?.coordinate.longitude, forKey: "longitude")
        UserDefaults.standard.set(locationManager?.location?.coordinate.latitude, forKey: "latitude")
    }
    
    @IBAction func didTapStartParkingButton(_ sender: Any) {
        saveParkingInformation()
        goParkingVC()
    }
    
    func openCamera() {
        let vc = UIImagePickerController()
        // 카메라가 없는 기기(시뮬레이터 등)에서는 사진 앨범으로 대체한다.
        vc.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        vc.delegate = self
        present(vc, animated: true)
    }
    
    fileprivate func initLocationManager() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.requestWhenInUseAuthorization()
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        locationManager?.startUpdatingLocation()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        startParkingButton.layer.cornerRadius = startParkingButton.bounds.height / 2
        
        memoTextField.textColor = .gray
        memoTextField.delegate = self
        
        startParkingButton.setTitle(NSLocalizedString("start parking", comment: ""), for: .normal)
        memoTextField.text = NSLocalizedString("memo", comment: "")
        
        carImageView.isUserInteractionEnabled = true
        carImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapCarImageView)))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateCarButtons()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(goParkingVC),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
        
        initLocationManager()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 앱을 완전히 종료했다 다시 켰을 때도 진행 중인 주차 화면으로 복귀한다.
        goParkingVC()
    }
    
    func updateCarButtons() {
        addCarButton.isHidden = carImageView.hasPhoto
        resetCarButton.isHidden = !carImageView.hasPhoto
    }
    
    @objc func didTapCarImageView() {
        guard addCarButton.isHidden else {
            return
        }
        
        guard let vc = self.storyboard?.instantiateViewController(withIdentifier: "ImageDetailVC") as? ImageDetailViewController else { return }
        vc.modalPresentationStyle = .fullScreen
        vc.image = carImageView.image
        self.present(vc, animated: true)
    }
    
    @objc func goParkingVC() {
        guard UserDefaults.standard.bool(forKey: "isParking"), presentedViewController == nil else { return }
        NotificationCenter.default.removeObserver(self)
        
        guard let vc = self.storyboard?.instantiateViewController(withIdentifier: "ParkingVC") as? ParkingViewController else { return }
        vc.modalTransitionStyle = UIModalTransitionStyle.flipHorizontal
        vc.modalPresentationStyle = .fullScreen
        
        // 저장된 값에서 복원해야 앱 재시작 후에도 사진과 메모가 유지된다.
        vc.carImage = CarImageStore.load() ?? CarImageView.placeholder
        vc.memoText = UserDefaults.standard.string(forKey: "memo")
        self.present(vc, animated: true)
    }
    
    func findAddr(lat: CLLocationDegrees, long: CLLocationDegrees) {
        let findLocation = CLLocation(latitude: lat, longitude: long)
        let geocoder = CLGeocoder()
        let locale = Locale(identifier: "Ko-kr")
        
        geocoder.reverseGeocodeLocation(findLocation, preferredLocale: locale, completionHandler: {(placemarks, error) in
            if let address: [CLPlacemark] = placemarks {
                var myAdd: String = ""
                if let area: String = address.last?.locality{
                    myAdd += area
                }
                if let name: String = address.last?.name {
                    myAdd += " "
                    myAdd += name
                }
            }
        })
    }
}

extension MainViewController: UINavigationControllerDelegate {
}

extension MainViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.originalImage] as? UIImage else {
                print("No image found")
                return
            }
            self.carImageView.image = image
            picker.dismiss(animated: true)
    }
}

extension MainViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == NSLocalizedString("memo", comment: "") {
            textView.text = ""
        }
        textView.textColor = .label
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text == "" {
            textView.text = NSLocalizedString("memo", comment: "")
        }
        textView.textColor = .gray
    }
}

extension MainViewController: CLLocationManagerDelegate {
    
}
