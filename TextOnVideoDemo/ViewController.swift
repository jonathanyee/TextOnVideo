//
//  ViewController.swift
//  TextOnVideoDemo
//
//  Created by Jonathan Yee on 12/7/19.
//  Copyright © 2019 Jonathan Yee. All rights reserved.
//

import Photos
import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setup()
    }

    private func setup() {
        self.view.backgroundColor = UIColor.white

        let chooseVideoButton = UIButton(type: .roundedRect)
        chooseVideoButton.setTitle("Select Video", for: .normal)
        chooseVideoButton.addTarget(self, action: #selector(startPhotoPicker), for: .touchUpInside)
        chooseVideoButton.translatesAutoresizingMaskIntoConstraints = false

        self.view.addSubview(chooseVideoButton)

        NSLayoutConstraint.activate([
            chooseVideoButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
            chooseVideoButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 15)
        ])
    }

    @objc private func startPhotoPicker() {
        self.checkPhotoStatus()
    }

    private func checkPhotoStatus() {
        let photoAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
        switch photoAuthorizationStatus {
            case .authorized:
                // Access is granted by user.
                break
            case .notDetermined:
                PHPhotoLibrary.requestAuthorization { _ in
                    self.checkPhotoStatus()
                }
            default:
                // go to settings
                DispatchQueue.main.async {
                    self.askUserToEnablePhotoPermission()
                }

                break
        }
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



        self.present(alertController, animated: true, completion: nil)
    }

}

