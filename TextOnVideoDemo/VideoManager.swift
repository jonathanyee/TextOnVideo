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
        let composition = AVMutableComposition()
        let videoAsset = AVURLAsset(url: url, options: nil)

        let videoTracks =  videoAsset.tracks(withMediaType: AVMediaType.video)
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
        let directoryPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = directoryPaths[0]
        let movieFilePath = "\(documentsDirectory)/result.mov"
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

                        OperationQueue.main.addOperation {
                            DispatchQueue.main.async {
                                self.onSuccess?(movieDestinationUrl)
                            }
                        }
                }
            }
        }
    }
}
