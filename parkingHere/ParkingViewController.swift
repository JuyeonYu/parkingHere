//
//  ParkingViewController.swift
//  parkingHere
//
//  Created by Juyeon on 2020/12/13.
//

import UIKit

class ParkingViewController: UIViewController {
    typealias HHMMSS = (HH: Int, MM: Int, SS: Int)
    
    var memoText: String?
    var secondParking: Int = 0
    var carImage: UIImage?
    
    @IBOutlet weak var memoLabel: UILabel!
    @IBOutlet weak var endParkingButton: UIButton!
    @IBOutlet weak var parkingTimeLabel: UILabel!
    @IBOutlet weak var carImageView: UIImageView!
    @IBOutlet weak var trackCarButton: UIButton!
    @IBAction func didTapTrackCarButton(_ sender: Any) {
        guard UserDefaults.standard.double(forKey: "latitude") != 0 else {
            let alert = UIAlertController(title: NSLocalizedString("no location info", comment: ""),
                                          message: NSLocalizedString("allow location", comment: ""),
                                          preferredStyle: UIAlertController.Style.alert)
            let defaultAction = UIAlertAction(title: "OK", style: .destructive) { (action) in }
            alert.addAction(defaultAction)
            present(alert, animated: true, completion: nil)
            return
        }
        
        guard let vc = self.storyboard?.instantiateViewController(withIdentifier: "MapVC") as? MapViewController else { return }
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true)
    }
    
    fileprivate func initParkingInformation() {
        UserDefaults.standard.set(false, forKey: "isParking")
        UserDefaults.standard.set(nil, forKey: "parkingTime")
        UserDefaults.standard.set(nil, forKey: "memo")
        UserDefaults.standard.set(nil, forKey: "carImage")
        UserDefaults.standard.set(0, forKey: "latitude")
        UserDefaults.standard.set(0, forKey: "longitude")
    }
    
    @IBAction func didTabEndParkingButton(_ sender: Any) {
        let preVC = self.presentingViewController
        guard let vc = preVC as? MainViewController else {
            return
        }
        vc.alarmSwitch.isOn = false
        vc.datePicker.isHidden = true
        vc.carImageView.image = UIImage(systemName: "car.fill")
        vc.hasImage = false
        self.dismiss(animated: true, completion: {
            self.initParkingInformation()
        })
    }
    
    fileprivate func getSecondParking() -> Int {
        let date = UserDefaults.standard.object(forKey: "parkingTime") as? Date ?? Date()
        return Int(Date().timeIntervalSince1970 - date.timeIntervalSince1970)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        endParkingButton .setTitle(NSLocalizedString("end parking", comment: ""), for: .normal)
        endParkingButton.layer.cornerRadius = endParkingButton.bounds.height / 2
        
        trackCarButton.setTitle(NSLocalizedString("track car", comment: ""), for: .normal)
        trackCarButton.layer.cornerRadius = trackCarButton.bounds.height / 2
        
        if let carImage = carImage {
            self.carImageView.image = carImage
        }
        
        if let memoText = memoText {
            memoLabel.text = memoText
        } else {
            memoLabel.isHidden = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        Timer.scheduledTimer(timeInterval: 1.0,
                             target: self,
                             selector: #selector(updateCounter),
                             userInfo: nil,
                             repeats: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    func secondsToHoursMinutesSeconds (seconds : Int) -> HHMMSS {
      return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }
    
    @objc func updateCounter() {
        var secondParking = getSecondParking()
        secondParking += 1
        let HHMMSS: HHMMSS = secondsToHoursMinutesSeconds(seconds: secondParking)
        parkingTimeLabel.text =  String(format: "%02d:%02d:%02d", HHMMSS.HH, HHMMSS.MM, HHMMSS.SS)
    }
}
