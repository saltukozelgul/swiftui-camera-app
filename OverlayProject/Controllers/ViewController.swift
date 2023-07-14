import UIKit
import SwiftUI
import OpenGLES.ES2
import AVFoundation
import Photos
import HaishinKit
import WebRTC

class ViewController : UIViewController,AVCaptureVideoDataOutputSampleBufferDelegate {
    private var permissionGranted = false
    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    
    private var previewLayer = AVCaptureVideoPreviewLayer()
    var videoDataOutput: AVCaptureVideoDataOutput!
    var assetWriter: AVAssetWriter!
    var assetWriterInput: AVAssetWriterInput!
    var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor!
    var isRecording = false
    var duration = 0
    var timer : Timer!
    var videoOutputURL: URL!
    var wasFirstBuffer = true
    
    
    var screenRect: CGRect! = nil
    var recordButton = UIButton(type: .contactAdd)
    let testButton = UIButton(type: .system)
    
    
    // When app minimized
    @objc func appMovedToBackground() {
        if isRecording {
            toggleRecording()
            restartAssetWriter()
        }
    }
    
    @objc func appMovedToForeground() {
        
    }
    
    
    override func  viewDidLoad() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
        
        // App enter foregrond
        NotificationCenter.default.addObserver(self, selector: #selector(self.appMovedToForeground), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        checkPermission()
        // Record Button
        UIBrain.setRecordButtonProperties(recordButton, view)
        recordButton.addTarget(self, action: #selector(toggleRecording), for: .touchUpInside)
        
        UIBrain.setTestButtonProperties(testButton, view)
        //testButton.addTarget(self, action: #selector(totalTimeOfBuffers), for: .touchUpInside)
        
        
        sessionQueue.async { [unowned self] in
            guard permissionGranted else {return}
            self.setupCaptureSession()
            self.setupAssetWriter()
            self.captureSession.startRunning()
        }
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        screenRect = UIScreen.main.bounds
        self.previewLayer.frame = CGRect(x: 0, y: 0, width: screenRect.size.width, height: screenRect.size.height)
        
        switch UIDevice.current.orientation {
            // Home button on top
        case UIDeviceOrientation.portraitUpsideDown:
            self.previewLayer.connection?.videoOrientation = .portraitUpsideDown
            
            // Home button on right
        case UIDeviceOrientation.landscapeLeft:
            self.previewLayer.connection?.videoOrientation = .landscapeRight
            
            // Home button on left
        case UIDeviceOrientation.landscapeRight:
            self.previewLayer.connection?.videoOrientation = .landscapeLeft
            
            // Home button at bottom
        case UIDeviceOrientation.portrait:
            self.previewLayer.connection?.videoOrientation = .portrait
            
        default:
            break
        }
    }
    
    
    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionGranted = true
        case .notDetermined:
            requestPermission()
        default:
            permissionGranted = false
        }
    }
    
    func requestPermission() {
        sessionQueue.suspend()
        AVCaptureDevice.requestAccess(for: .video) { [unowned self] granted in
            self.permissionGranted = granted
            self.sessionQueue.resume()
        }
        
    }
    
    @objc func toggleRecording() {
        isRecording.toggle()
        print("New recording status: \(isRecording)")
        if isRecording {
            // Create timer
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                self.duration += 1
            }
            recordButton.setTitle("Stop", for: .normal)
        } else {
            // Demolish timer
            recordButton.setTitle("Record", for: .normal)
            finishAssetWriter()
        }
    }
    
    func setupAssetWriter() {
        // Create asset writer
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        // add currentdate to video URl as well
        let currentDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy HH:mm:ss:SSS"
        let convertedDate = dateFormatter.string(from: currentDate)
        let videoOutputURL = URL(fileURLWithPath: documentsPath).appendingPathComponent("output_\(convertedDate).mp4")
        
        do {
            assetWriter = try AVAssetWriter(outputURL: videoOutputURL, fileType: .mp4)
        } catch {
            print(error)
        }
        
        // Create asset writer input
        let videoSettings = [
            AVVideoCodecKey : AVVideoCodecType.h264,
            AVVideoWidthKey : 1920,
            AVVideoHeightKey : 1080
        ] as [String : Any]
        assetWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoSettings)
        assetWriterInput.expectsMediaDataInRealTime = true
        // set video orientation
        assetWriterInput.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
        assetWriter.add(assetWriterInput)
        
        // Create pixel buffer adaptor
        let sourcePixelBufferAttributesDictionary = [
            kCVPixelBufferPixelFormatTypeKey as String : NSNumber(value: kCVPixelFormatType_32BGRA),
            kCVPixelBufferWidthKey as String : NSNumber(value: 1920),
            kCVPixelBufferHeightKey as String : NSNumber(value: 1080)
        ]
        pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: assetWriterInput, sourcePixelBufferAttributes: sourcePixelBufferAttributesDictionary)
        
        assetWriter.startWriting()
    }
    
    func finishAssetWriter() {
        if assetWriter.status == .writing {
            // Finish writing session
            assetWriterInput.markAsFinished()
            assetWriter.finishWriting {
                print("Total duration of video: \(self.duration)")
                
                // Main queue
                DispatchQueue.main.async {
                    UISaveVideoAtPathToSavedPhotosAlbum(self.assetWriter.outputURL.path, nil, nil, nil)
                }
                print("Saved to library video name: \(self.assetWriter.outputURL.path)")
                self.restartAssetWriter()
            }
        } else {
            print("Error: AssetWriter status is \(assetWriter.status)")
        }
    }
        
    func restartAssetWriter() {
        // Restart writing session
        self.setupAssetWriter()
        if let safeTimer = self.timer {
            safeTimer.invalidate()
        }
        self.duration = 0
    }
        
        func captureOutput(_ captureOutput: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            
            // Adding the buffers to assetWriter session for creating video.
            if isRecording && assetWriter.status == .writing {
                //
                // EDIT THIS BUFFER
                //
                if wasFirstBuffer {
                    // First buffer
                    assetWriter.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
                    wasFirstBuffer = false
                }
                
       
                
                // Edit this buffer and text
                let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
                let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
                let context = CIContext()
                
                // Adding Scoreboard Image
                let image = UIImage(named: "score")
                let imageWidth = image?.size.width
                let imageHeight = image?.size.height
                
                // get max value of X
                // we change the orientation so we have to fetch Y for X
                let max = ciImage.extent.maxY
                let max2 = ciImage.extent.maxX
                
                let imageRect = CGRect(x:50 , y: max - imageHeight! - 50, width: imageWidth!, height: imageHeight!)
                var ciScoreboardImage = CIImage(image: image!)!
                ciScoreboardImage = ciScoreboardImage.oriented(.upMirrored)
                ciScoreboardImage = ciScoreboardImage.transformed(by: CGAffineTransform(translationX: imageRect.origin.x, y: imageRect.origin.y))
                let cgImageWithBackground = ciScoreboardImage.composited(over: ciImage)
                context.render(cgImageWithBackground, to: pixelBuffer)
                
                // TAKIM 1
                
                let teamOne = "Takım - 1"
                // create textRect for right top corner
                let textRect = CGRect(x: 50, y: 50, width: 500, height: max/2 + 25)
                let textAttributes = [
                    NSAttributedString.Key.foregroundColor: UIColor.black,
                    NSAttributedString.Key.font: UIFont(name: "Helvetica Bold", size: 25)!
                ]
                let textImage = UIGraphicsImageRenderer(size: textRect.size).image { _ in
                    teamOne.draw(in: textRect, withAttributes: textAttributes)
                }
                var textCiImage = CIImage(image: textImage)!
                textCiImage = textCiImage.oriented(.up)
                let textCiImageWithBackground = textCiImage.composited(over: ciImage)
                context.render(textCiImageWithBackground, to: pixelBuffer)
                
                // SKOR
                
                let score = "0 - 0"
                let scoreRect = CGRect(x: 230, y: 50, width: 500, height: max/2 + 25)
                let scoreAttributes = [
                    NSAttributedString.Key.foregroundColor: UIColor.white,
                    NSAttributedString.Key.font: UIFont(name: "Helvetica Bold", size: 25)!
                ]
                let scoreImage = UIGraphicsImageRenderer(size: scoreRect.size).image { _ in
                    score.draw(in: scoreRect, withAttributes: scoreAttributes)
                }
                var scoreCiImage = CIImage(image: scoreImage)!
                // Rotate this image
                scoreCiImage = scoreCiImage.oriented(.up)
                // add text to the image
                let scoreCiImageWithBackground = scoreCiImage.composited(over: ciImage)
                // add image to the buffer
                context.render(scoreCiImageWithBackground, to: pixelBuffer)
                
                // TAKIM - 2
                
                let teamTwo = "Takım - 2"
                let textRect2 = CGRect(x: 320, y: 50, width: 500, height: max/2 + 25)
                let textImage2 = UIGraphicsImageRenderer(size: textRect2.size).image { _ in
                    teamTwo.draw(in: textRect2, withAttributes: textAttributes)
                }
                var textCiImage2 = CIImage(image: textImage2)!
                textCiImage2 = textCiImage2.oriented(.up)
                let textCiImageWithBackground2 = textCiImage2.composited(over: ciImage)
                context.render(textCiImageWithBackground2, to: pixelBuffer)
                
                
                // Convert this MM:SS format
                let minutes = self.duration / 60
                let seconds = self.duration % 60
                let time = String(format: "%02d:%02d", minutes, seconds)


                let timeRect = CGRect(x: 225, y: 50, width: 500, height: max/2 - 5 )
                let timeAttributes = [
                    NSAttributedString.Key.foregroundColor: UIColor.black,
                    NSAttributedString.Key.font: UIFont(name: "Helvetica Bold", size: 25)!
                ]
                DispatchQueue.main.async {
                    let timeImage = UIGraphicsImageRenderer(size: timeRect.size).image { _ in
                        time.draw(in: timeRect, withAttributes: timeAttributes)
                    }
                    var timeCiImage = CIImage(image: timeImage)!
                    timeCiImage = timeCiImage.oriented(.up)
                    let timeCiImageWithBackground = timeCiImage.composited(over: ciImage)
                    context.render(timeCiImageWithBackground, to: pixelBuffer)
                }
                

                //Convert to buffer again to add pixelBufferAdaptor
                var timingInfo = CMSampleTimingInfo()
                timingInfo.presentationTimeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                timingInfo.duration = CMSampleBufferGetDuration(sampleBuffer)
                var videoInfo: CMVideoFormatDescription?
                CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer, formatDescriptionOut: &videoInfo)
                var sampleBuffer: CMSampleBuffer?
                CMSampleBufferCreateReadyWithImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer, formatDescription: videoInfo!, sampleTiming: &timingInfo, sampleBufferOut: &sampleBuffer)
                
                // Add buffer to assetWriter' session
                pixelBufferAdaptor.append(CMSampleBufferGetImageBuffer(sampleBuffer!)!, withPresentationTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer!))
            }
            else {
                // Not recoring state
            }
        }
        
        
        func setupCaptureSession() {
            // Access camera
            guard let videoDevice = AVCaptureDevice.default(.builtInDualWideCamera,for: .video, position: .back) else { return }
            guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else { return }
            guard captureSession.canAddInput(videoDeviceInput) else { return }
            captureSession.addInput(videoDeviceInput)
            
            // Preview layer
            screenRect = UIScreen.main.bounds
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.frame = CGRect(x: 0, y: 0, width: screenRect.size.width, height: screenRect.size.height)
            previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill // Fill screen
            previewLayer.connection?.videoOrientation = .portrait
            
            //Video data output
            let videoDataOutput = AVCaptureVideoDataOutput()
            
            // Set the sample buffer delegate of the AVCaptureVideoDataOutput object to your view controller.
            videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main)
            
            // Configure the AVCaptureVideoDataOutput object.
            videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            
            // Add the AVCaptureVideoDataOutput object to the AVCaptureSession object.
            captureSession.addOutput(videoDataOutput)
            
            // Updates to UI must be on main queue
            DispatchQueue.main.async { [weak self] in
                self?.view.layer.addSublayer(self!.previewLayer)
            }
        }
        
        
    }
    
    struct HostedViewController: UIViewControllerRepresentable {
        func makeUIViewController(context: Context) -> UIViewController {
            return ViewController()
        }
        
        func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
            
        }
    }


