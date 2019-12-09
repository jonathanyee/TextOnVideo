//
//  PhotoAccessManager.swift
//  TextOnVideoDemo
//
//  Created by Jonathan Yee on 12/8/19.
//  Copyright © 2019 Jonathan Yee. All rights reserved.
//

import Photos
import UIKit

struct PhotoAccessManager {

    var onHasAccess: (() -> Void)?
    var onAskUserToEnablePhotoPermission: (() -> Void)?

    func checkPhotoStatus() {
        let photoAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
        switch photoAuthorizationStatus {
            case .authorized:
                if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                    DispatchQueue.main.async {
                        self.onHasAccess?()
                    }
                }
                break
            case .notDetermined:
                PHPhotoLibrary.requestAuthorization { _ in
                    self.checkPhotoStatus()
                }
                break
            default:
                DispatchQueue.main.async {
                    self.onAskUserToEnablePhotoPermission?()
                }

                break
        }
    }
}
