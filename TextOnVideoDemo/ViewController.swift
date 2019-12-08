//
//  ViewController.swift
//  TextOnVideoDemo
//
//  Created by Jonathan Yee on 12/7/19.
//  Copyright © 2019 Jonathan Yee. All rights reserved.
//

import MobileCoreServices
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
                if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                    DispatchQueue.main.async {
                        let imagePicker = UIImagePickerController()
                        imagePicker.sourceType = .photoLibrary
                        imagePicker.mediaTypes = [kUTTypeMovie as String]
                        imagePicker.allowsEditing = false
                        imagePicker.delegate = self

                        self.present(imagePicker, animated: true, completion: nil)
                    }
                }
                break
            case .notDetermined:
                PHPhotoLibrary.requestAuthorization { _ in
                    self.checkPhotoStatus()
                }
                break
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

    private func saveVideo(url: URL) {
        if UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(url.relativePath) {
            UISaveVideoAtPathToSavedPhotosAlbum(url.relativePath, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
        }
    }

    @objc func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            print("\(error)")
            let alert = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        } else {
            let alert = UIAlertController(title: "Saved!", message: "Your video has been saved to Photos app", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }

    private func drawTextOnVideo(url: URL, text: String) {
        let composition = AVMutableComposition()
        let vidAsset = AVURLAsset(url: url, options: nil)

        // get video track
        let vtrack =  vidAsset.tracks(withMediaType: AVMediaType.video)
        let videoTrack = vtrack[0]

        // audio
        let atrack =  vidAsset.tracks(withMediaType: AVMediaType.audio)
        let audioTrack:AVAssetTrack = atrack[0]
        let audio_timerange = CMTimeRangeMake(start: CMTime.zero, duration: vidAsset.duration)

        if let compositionvideoTrack = composition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: CMPersistentTrackID()) {

            let vid_timerange = CMTimeRangeMake(start: CMTime.zero, duration: vidAsset.duration)

            do {
                try compositionvideoTrack.insertTimeRange(vid_timerange, of: videoTrack, at: CMTime.zero)
            } catch {
                print(error)
            }

            compositionvideoTrack.preferredTransform = videoTrack.preferredTransform

            if let compositionAudioTrack:AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: CMPersistentTrackID()) {

                do {
                    try compositionAudioTrack.insertTimeRange(audio_timerange, of: audioTrack, at: CMTime.zero)
                } catch {
                    print(error)
                }

                compositionvideoTrack.preferredTransform = audioTrack.preferredTransform
            }
        }

        // Watermark Effect
        let size = videoTrack.naturalSize

        // create text Layer
        let titleLayer = CATextLayer()
        titleLayer.backgroundColor = UIColor.clear.cgColor
        titleLayer.string = text
        titleLayer.font = UIFont(name: "Helvetica", size: 28)
        titleLayer.shadowOpacity = 0.5
        titleLayer.alignmentMode = .center
        titleLayer.frame = CGRect(x: 0, y: 50, width: size.width, height: size.height / 6)

        let videolayer = CALayer()
        videolayer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)

        let parentlayer = CALayer()
        parentlayer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        parentlayer.addSublayer(videolayer)
        parentlayer.addSublayer(titleLayer)

        let layercomposition = AVMutableVideoComposition()
        layercomposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        layercomposition.renderSize = size
        layercomposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videolayer, in: parentlayer)

        // instruction for watermark
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: composition.duration)
        let videotrack = composition.tracks(withMediaType: AVMediaType.video)[0]
        let layerinstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videotrack)
        instruction.layerInstructions = [layerinstruction]
        layercomposition.instructions = [instruction]

        //  create new file to receive data
        let dirPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let docsDir = dirPaths[0]
        let movieFilePath = "\(docsDir)/result.mov"
        let movieDestinationUrl = URL(fileURLWithPath: movieFilePath)

        // delete old one first
        do {
            try FileManager.default.removeItem(at: movieDestinationUrl)
        } catch {
            print(error.localizedDescription)
        }

        // use AVAssetExportSession to export video
        if let assetExport = AVAssetExportSession(asset: composition, presetName:AVAssetExportPresetHighestQuality) {
            assetExport.videoComposition = layercomposition
            assetExport.outputFileType = AVFileType.mov
            assetExport.outputURL = movieDestinationUrl

            assetExport.exportAsynchronously {
                switch assetExport.status {
                    case  .failed:
                        if let error = assetExport.error {
                            print("failed \(error)")
                        }
                    case .cancelled:
                        if let error = assetExport.error {
                            print("cancelled \(error)")
                        }
                    default:
                        print("Movie complete")

                        // play video
                        OperationQueue.main.addOperation {
                            DispatchQueue.main.async {
                                self.saveVideo(url: movieDestinationUrl)
                            }
                        }
                }
            }
        }
    }
}

extension ViewController: UIImagePickerControllerDelegate {

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
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

        let alert = UIAlertController(title: "Overlay Text", message: "Input text to overlay on your video", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "overlay text"
        }

        let okAction = UIAlertAction(title: "OK", style: .default) { [weak self, weak alert] _ in
            if let textField = alert?.textFields?.first,
                let text = textField.text {
                self?.drawTextOnVideo(url: mediaURL, text: text)
            }
        }
        alert.addAction(okAction)
        self.present(alert, animated: true)
    }

}

extension ViewController: UINavigationControllerDelegate { }
