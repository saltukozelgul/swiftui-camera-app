//
//  AssetWriterUtils.swift
//  OverlayProject
//
//  Created by Saltuk Bugra OZELGUL on 17.07.2023.
//

import Foundation
import AVFoundation

class AssetWriterUtils {
    
    
    public func setAssetWriter() -> AVAssetWriter? {
        // Create asset writer
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        // add currentdate to video URl as well
        let currentDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy HH:mm:ss:SSS"
        let convertedDate = dateFormatter.string(from: currentDate)
        let videoOutputURL = URL(fileURLWithPath: documentsPath).appendingPathComponent("output_\(convertedDate).mp4")
        
        do {
            let assetWriter = try AVAssetWriter(outputURL: videoOutputURL, fileType: .mp4)
            return assetWriter
        } catch {
            print(error)
            return nil
        }
    }
    
    public func setAssetWriterInput() -> AVAssetWriterInput {
        // Create asset writer input
        let videoSettings = [
            AVVideoCodecKey : AVVideoCodecType.h264,
            AVVideoWidthKey : 1920,
            AVVideoHeightKey : 1080
        ] as [String : Any]
        let assetWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoSettings)
        assetWriterInput.expectsMediaDataInRealTime = true
        // set video orientation
        assetWriterInput.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
        return assetWriterInput
    }
    
    public func setPixelBufferAdaptor(_ assetWriterInput: AVAssetWriterInput) -> AVAssetWriterInputPixelBufferAdaptor {
        // Create pixel buffer adaptor
        let sourcePixelBufferAttributesDictionary = [
            kCVPixelBufferPixelFormatTypeKey as String : NSNumber(value: kCVPixelFormatType_32BGRA),
            kCVPixelBufferWidthKey as String : NSNumber(value: 1920),
            kCVPixelBufferHeightKey as String : NSNumber(value: 1080)
        ]
        let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: assetWriterInput, sourcePixelBufferAttributes: sourcePixelBufferAttributesDictionary)
        
        return pixelBufferAdaptor
    }
}


