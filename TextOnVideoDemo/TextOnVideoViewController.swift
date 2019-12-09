//
//  TextOnVideoViewController.swift
//  TextOnVideoDemo
//
//  Created by Jonathan Yee on 12/7/19.
//  Copyright © 2019 Jonathan Yee. All rights reserved.
//

import MobileCoreServices
import Photos
import UIKit

class TextOnVideoViewController: UIViewController {

    private let textOnVideoView = TextOnVideoView()

    private var photoAccessManager = PhotoAccessManager()
    private var videoManager = VideoManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupView()
        self.setupPhotoManager()
        self.setupVideoManager()
    }

    private func setupView() {
        self.view.backgroundColor = UIColor.white

        self.textOnVideoView.translatesAutoresizingMaskIntoConstraints = false
        self.textOnVideoView.chooseVideoButton.addTarget(self, action: #selector(startPhotoPicker), for: .touchUpInside)
        
        self.view.addSubview(self.textOnVideoView)

        NSLayoutConstraint.activate([
            self.textOnVideoView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.textOnVideoView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.textOnVideoView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            self.textOnVideoView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }

    private func setupPhotoManager() {
        self.photoAccessManager.onHasAccess = { [weak self] in
            let imagePicker = UIImagePickerController()
            imagePicker.sourceType = .photoLibrary
            imagePicker.mediaTypes = [kUTTypeMovie as String]
            imagePicker.allowsEditing = false
            imagePicker.delegate = self

            self?.present(imagePicker, animated: true, completion: nil)
        }

        self.photoAccessManager.onAskUserToEnablePhotoPermission = { [weak self] in
            self?.askUserToEnablePhotoPermission()
        }
    }

    private func setupVideoManager() {
        self.videoManager.onSuccess = { [weak self] url in
            self?.textOnVideoView.activityIndicator.stopAnimating()
            self?.saveVideo(url: url)
        }

        self.videoManager.onFailure = { [weak self] error in
            let alertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Ok", style: .default))

            self?.present(alertController, animated: true)
        }
    }

    @objc private func startPhotoPicker() {
        self.photoAccessManager.checkPhotoStatus()
    }

    private func askUserToEnablePhotoPermission() {
        let alertController = UIAlertController (title: "Photo Permission", message: "Please enable photo permissions in settings to save text on your videos.", preferredStyle: .alert)

        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        alertController.addAction(cancelAction)

        let settingsAction = UIAlertAction(title: "Settings", style: .default) { _ in

            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                return
            }

            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl)
            }
        }
        alertController.addAction(settingsAction)

        self.present(alertController, animated: true)
    }

    private func saveVideo(url: URL) {
        if UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(url.relativePath) {
            UISaveVideoAtPathToSavedPhotosAlbum(url.relativePath, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
        }
    }

    @objc func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            print("\(error)")
            let alertController = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alertController, animated: true)
        } else {
            let alertController = UIAlertController(title: "Saved!", message: "Your video has been saved to Photos app", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alertController, animated: true)
        }
    }
}

extension TextOnVideoViewController: UIImagePickerControllerDelegate {

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard
            let mediaType = info[UIImagePickerController.InfoKey.mediaType] as? NSString,
            mediaType == kUTTypeMovie,
            let mediaURL = info[UIImagePickerController.InfoKey.mediaURL] as? URL
        else {
            return
        }

        picker.dismiss(animated: true)

        let alertController = UIAlertController(title: "Overlay Text", message: "Input text to overlay on your video", preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = "overlay text"
        }

        let okAction = UIAlertAction(title: "OK", style: .default) { [weak self, weak alertController] _ in
            guard
                let textField = alertController?.textFields?.first,
                let text = textField.text,
                let self = self
            else {
                return
            }

            self.textOnVideoView.activityIndicator.startAnimating()
            self.videoManager.drawTextOnVideo(url: mediaURL, text: text)
        
        }
        alertController.addAction(okAction)
        self.present(alertController, animated: true)
    }

}

extension TextOnVideoViewController: UINavigationControllerDelegate { }
