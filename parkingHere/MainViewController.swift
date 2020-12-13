//
//  ViewController.swift
//  parkingHere
//
//  Created by Juyeon on 2020/12/13.
//

import UIKit

class MainViewController: UIViewController {
    var isParking: Bool = false
    var hasImage: Bool = false

    @IBAction func didTapAlarmButton(_ sender: Any) {
        datePicker.isHidden = !datePicker.isHidden
    }
    @IBOutlet weak var alarmButton: UIButton!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var carImage: UIImageView!
    @IBOutlet weak var alarmTime: UILabel!
    @IBOutlet weak var memo: UITextView!
    @IBOutlet weak var parkingButton: UIButton!
    @IBOutlet weak var addCarButton: UIButton!
    @IBOutlet weak var resetCarButton: UIButton!
    @IBAction func didTapResetCarButton(_ sender: Any) {
        let optionMenu = UIAlertController(title: nil, message: "Choose Option", preferredStyle: .actionSheet)

        let deleteAction = UIAlertAction(title: "camera", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.openCamera()
        })
        
        let resetAction = UIAlertAction(title: "reset", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.addCarButton.isHidden = false
            self.resetCarButton.isHidden =  true
            self.carImage.image = UIImage(systemName: "car.fill")
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
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
    
    @IBAction func didTapParkingButton(_ sender: Any) {
        guard let vc = self.storyboard?.instantiateViewController(withIdentifier: "ParkingVC") else {
            return
        }
        vc.modalTransitionStyle = UIModalTransitionStyle.flipHorizontal
        vc.modalPresentationStyle = .fullScreen
        
        self.present(vc, animated: true)
    }
    
    func openCamera() {
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.allowsEditing = true
        vc.delegate = self
        present(vc, animated: true)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        parkingButton.layer.cornerRadius = parkingButton.bounds.height / 2
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if hasImage {
            addCarButton.isHidden = true
            resetCarButton.isHidden = false
        } else {
            addCarButton.isHidden = false
            resetCarButton.isHidden = true
        }
    }
}

extension MainViewController: UINavigationControllerDelegate {
    
}

extension MainViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)

            guard let image = info[.editedImage] as? UIImage else {
                print("No image found")
                return
            }
        self.carImage.image = image
        hasImage = true
    }
}
