//
//  ViewController.swift
//  parkingHere
//
//  Created by Juyeon on 2020/12/13.
//

import UIKit

class MainViewController: UIViewController {
    var hasImage: Bool = false
    
    @IBOutlet weak var carImageView: UIImageView!
    @IBOutlet weak var memoTextField: UITextView!
    @IBOutlet weak var startParkingButton: UIButton!
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
            self.carImageView.image = UIImage(systemName: "car.fill")
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
    
    fileprivate func saveParkingInformation() {
        UserDefaults.standard.set(true, forKey: "isParking")
        UserDefaults.standard.set(Date(), forKey: "parkingTime")
        
        if memoTextField.text != "간단메모" {
            UserDefaults.standard.set(memoTextField.text, forKey: "memo")
        }
        
        if hasImage {
            UserDefaults.standard.set(carImageView.image?.pngData(), forKey: "carImage")
        }
    }
    
    @IBAction func didTapStartParkingButton(_ sender: Any) {
        saveParkingInformation()
        goParkingVC()
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
        
        startParkingButton.layer.cornerRadius = startParkingButton.bounds.height / 2
        
        memoTextField.textColor = .gray
        memoTextField.delegate = self
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
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(goParkingVC),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
    }
    
    @objc func goParkingVC() {
        if UserDefaults.standard.bool(forKey: "isParking") {
            NotificationCenter.default.removeObserver(self)
            
            guard let vc = self.storyboard?.instantiateViewController(withIdentifier: "ParkingVC") as? ParkingViewController else { return }
            vc.modalTransitionStyle = UIModalTransitionStyle.flipHorizontal
            vc.modalPresentationStyle = .fullScreen
            
            if let carPNG = UserDefaults.standard.data(forKey: "carImage") {
                vc.carImage = UIImage(data: carPNG)
            } else {
                vc.carImage = UIImage(systemName: "car.fill")
            }
            
            if memoTextField.text != "간단메모" {
                vc.memoText = memoTextField.text
            }
            self.present(vc, animated: true)
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
        self.carImageView.image = image
        hasImage = true
    }
}

extension MainViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == "간단메모" {
            textView.text = ""
        }
        textView.textColor = .label
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text == "" {
            textView.text = "간단메모"
        }
        textView.textColor = .gray
    }
}
