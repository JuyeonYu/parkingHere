//
//  ParkingViewController.swift
//  parkingHere
//
//  Created by Juyeon on 2020/12/13.
//

import UIKit

class ParkingViewController: UIViewController {
    @IBOutlet weak var endParkingButton: UIButton!
    
    @IBAction func didTabENdParkingButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        endParkingButton.layer.cornerRadius = endParkingButton.bounds.height / 2
    }
}
