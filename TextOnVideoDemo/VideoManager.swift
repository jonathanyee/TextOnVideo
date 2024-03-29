//
//  VideoManager.swift
//  TextOnVideoDemo
//
//  Created by Jonathan Yee on 12/8/19.
//  Copyright © 2019 Jonathan Yee. All rights reserved.
//

import MobileCoreServices
import Photos
import UIKit

struct VideoManager {

    var onSuccess: ((URL) -> Void)?
    var onFailure: ((Error) -> Void)?

    func drawTextOnVideo(url: URL, text: String) {
        let composition = self.createComposition(from: url)
        let videoTrack = composition.tracks(withMediaType: AVMediaType.video)[0]

        let size = videoTrack.naturalSize

        let textLayer = self.createTextLayer(with: text, size: size)

        let videolayer = CALayer()
        videolayer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)

        let parentlayer = CALayer()
        parentlayer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        parentlayer.addSublayer(videolayer)
        parentlayer.addSublayer(textLayer)

        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)

        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: composition.duration)
        instruction.layerInstructions = [layerInstruction]

        let mainComposition = AVMutableVideoComposition()
        mainComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        mainComposition.renderSize = size
        mainComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videolayer, in: parentlayer)
        mainComposition.instructions = [instruction]

        //  create new file to receive data
        let directoryPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = directoryPaths[0]
        let movieFilePath = "\(documentsDirectory)/result.mov"
        let movieDestinationUrl = URL(fileURLWithPath: movieFilePath)

        if FileManager.default.fileExists(atPath: movieDestinationUrl.path) {
            do {
                try FileManager.default.removeItem(at: movieDestinationUrl)
            } catch {
                print(error.localizedDescription)
            }
        }

        self.saveVideo(composition: composition, layerComposition: mainComposition, url: movieDestinationUrl)
    }

    private func createComposition(from url: URL) -> AVMutableComposition {
        let composition = AVMutableComposition()
        let videoAsset = AVURLAsset(url: url, options: nil)

        let videoTracks = videoAsset.tracks(withMediaType: AVMediaType.video)
        let videoTrack = videoTracks[0]

        let audioTracks = videoAsset.tracks(withMediaType: AVMediaType.audio)
        let audioTrack = audioTracks[0]
        let audioTimeRange = CMTimeRangeMake(start: CMTime.zero, duration: videoAsset.duration)

        if let compositionvideoTrack = composition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: CMPersistentTrackID()),
            let compositionAudioTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: CMPersistentTrackID()) {

            let videoTimeRange = CMTimeRangeMake(start: CMTime.zero, duration: videoAsset.duration)

            do {
                try compositionvideoTrack.insertTimeRange(videoTimeRange, of: videoTrack, at: CMTime.zero)
                compositionvideoTrack.preferredTransform = videoTrack.preferredTransform

                try compositionAudioTrack.insertTimeRange(audioTimeRange, of: audioTrack, at: CMTime.zero)
                compositionvideoTrack.preferredTransform = audioTrack.preferredTransform
            } catch {
                self.onFailure?(error)
                print(error)
            }
        }

        return composition
    }

    private func createTextLayer(with text: String, size: CGSize) -> CATextLayer {
        let textLayer = CATextLayer()
        textLayer.backgroundColor = UIColor.clear.cgColor
        textLayer.string = text
        textLayer.font = UIFont(name: "Helvetica", size: 28)
        textLayer.shadowOpacity = 0.5
        textLayer.alignmentMode = .center
        textLayer.frame = CGRect(x: 0, y: 50, width: size.width, height: size.height / 6)

        return textLayer
    }

    private func saveVideo(composition: AVMutableComposition, layerComposition: AVMutableVideoComposition, url: URL) {
        if let assetExport = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) {
            assetExport.videoComposition = layerComposition
            assetExport.outputFileType = AVFileType.mov
            assetExport.outputURL = url

            assetExport.exportAsynchronously {
                switch assetExport.status {
                    case  .failed:
                        if let error = assetExport.error {
                            self.onFailure?(error)
                            print("failed \(error)")
                        }
                    case .cancelled:
                        if let error = assetExport.error {
                            self.onFailure?(error)
                            print("cancelled \(error)")
                        }
                    default:
                        print("Movie complete")

                        DispatchQueue.main.async {
                            self.onSuccess?(url)
                        }
                }
            }
        }
    }

}
