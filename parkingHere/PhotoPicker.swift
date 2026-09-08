//
//  PhotoPicker.swift
//  parkingHere
//

import UIKit

/// 카메라(없으면 사진 앨범)를 띄우고 고른 사진을 돌려준다.
final class PhotoPicker: NSObject {
    private var completion: ((UIImage?) -> Void)?

    func present(from presenter: UIViewController, completion: @escaping (UIImage?) -> Void) {
        self.completion = completion
        let picker = UIImagePickerController()
        // 카메라가 없는 기기(시뮬레이터 등)에서는 사진 앨범으로 대체한다.
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.delegate = self
        presenter.present(picker, animated: true)
    }
}

extension PhotoPicker: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        let image = info[.originalImage] as? UIImage
        picker.dismiss(animated: true) { [weak self] in
            self?.completion?(image)
            self?.completion = nil
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true) { [weak self] in
            self?.completion?(nil)
            self?.completion = nil
        }
    }
}
