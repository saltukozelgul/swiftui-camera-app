import UIKit
import SwiftUI
import OpenGLES.ES2
import AVFoundation
import Photos
import HaishinKit


class ViewController : UIViewController,AVCaptureVideoDataOutputSampleBufferDelegate {
    private var permissionGranted = false
    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    
    let audioSession = AVAudioSession.sharedInstance()
    var rtmpConnection = RTMPConnection()
    var rtmpStream: RTMPStream!
    

    private var previewLayer = AVCaptureVideoPreviewLayer()
    var videoDataOutput: AVCaptureVideoDataOutput!
    var assetWriter: AVAssetWriter!
    var assetWriterInput: AVAssetWriterInput!
    var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor!
    var isRecording = false
    var wasFirstBuffer = false
    var frameCount = 0
    var videoOutputURL: URL!
    
    var screenRect: CGRect! = nil
    let recordButton = UIButton(type: .contactAdd)
    let testButton = UIButton(type: .system)
    
    override func  viewDidLoad() {
        checkPermission()
        // Record Button
        recordButton.setTitle("Record", for: .normal)
        recordButton.addTarget(self, action: #selector(toggleRecording), for: .touchUpInside)
        recordButton.translatesAutoresizingMaskIntoConstraints = false
        recordButton.layer.zPosition = 1000
        view.addSubview(recordButton)
        NSLayoutConstraint.activate([
            recordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            recordButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
        
        testButton.setTitle("Test", for: .normal)
        testButton.addTarget(self, action: #selector(totalTimeOfBuffers), for: .touchUpInside)
        testButton.translatesAutoresizingMaskIntoConstraints = false
        testButton.layer.zPosition = 1000
        view.addSubview(testButton)
        NSLayoutConstraint.activate([
            testButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            testButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50)
        ])
        

        sessionQueue.async { [unowned self] in
            guard permissionGranted else {return}
            self.setupCaptureSession()
            self.setupAssetWriter()
            self.setupRTMPSession()
            print("Merhabaa")
            self.captureSession.startRunning()
        }
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
    
    func setupRTMPSession() {
        rtmpStream = RTMPStream(connection: rtmpConnection)
        rtmpStream.frameRate = 30
        
//        let hkView = HKView(frame: view.bounds)
//        hkView.videoGravity = AVLayerVideoGravity.resizeAspectFill
//        hkView.attachStream(rtmpStream)
//        DispatchQueue.main.async { [weak self] in
//            self?.view.addSubview(hkView)
//        }
        rtmpConnection.connect("rtmp://192.168.0.14/live")
        rtmpStream.publish("testStream")
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
        if isRecording {
            recordButton.setTitle("Stop", for: .normal)
        } else {
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
        dateFormatter.dateFormat = "dd-MM-yyyy HH:mm:ss"
        let convertedDate = dateFormatter.string(from: currentDate)
        let videoOutputURL = URL(fileURLWithPath: documentsPath).appendingPathComponent("output_\(convertedDate).mov")
                
        do {
            assetWriter = try AVAssetWriter(outputURL: videoOutputURL, fileType: AVFileType.mov)
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
        print("AssetWriter initiliazed")
        print(videoOutputURL)
        
    }
    
    @objc func totalTimeOfBuffers() -> Int   {
        // Frame count is the total number of buffers and fps is 29 so calculate video duration
        // convert to nearest int
        let duration = Double(frameCount) / 29
        print(round(duration))
        return Int(round(duration))
    }
    
    func finishAssetWriter() {
        // Finish writing session
        assetWriterInput.markAsFinished()
        assetWriter.finishWriting {
            print("Total number of frames: \(self.frameCount)")
            UISaveVideoAtPathToSavedPhotosAlbum(self.assetWriter.outputURL.path, nil, nil, nil)
            print("Saved to library video name: \(self.assetWriter.outputURL.path)")
            
            self.restartAssetWriter()
        }
        
    }
    
    func restartAssetWriter() {
        // Restart writing session
        setupAssetWriter()
        wasFirstBuffer = false
        frameCount = 0
    }
    

    func captureOutput(_ captureOutput: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Adding the buffers to assetWriter session for creating video.
        if isRecording {
            if wasFirstBuffer == false {
                assetWriter.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
                wasFirstBuffer = true
            }
            
            //
            // EDIT THIS BUFFER
            //
            
            // Edit this buffer and text
            let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let context = CIContext()
            
            // add top left corner text
            let text = "Scoreboard"
            let textRect = CGRect(x: 15, y: 15, width: 215, height: 215)
        
            let textAttributes = [
                NSAttributedString.Key.foregroundColor: UIColor.orange,
                NSAttributedString.Key.font: UIFont(name: "Helvetica Bold", size: 35)!
            ]
             let textImage = UIGraphicsImageRenderer(size: textRect.size).image { _ in
                 text.draw(in: textRect, withAttributes: textAttributes)
             }
             var textCiImage = CIImage(image: textImage)!
            // Rotate this image
            textCiImage = textCiImage.oriented(.left)
             // add text to the image
             let textCiImageWithBackground = textCiImage.composited(over: ciImage)
             // add image to the buffer
             context.render(textCiImageWithBackground, to: pixelBuffer)
            
            // add top left corner text
            let score = "0-0"
            let scoreRect = CGRect(x: 80, y: 45, width: 215, height: 215)
            let scoreAttributes = [
                NSAttributedString.Key.foregroundColor: UIColor.orange,
                NSAttributedString.Key.font: UIFont(name: "Helvetica Bold", size: 35)!
            ]
             let scoreImage = UIGraphicsImageRenderer(size: scoreRect.size).image { _ in
                 score.draw(in: scoreRect, withAttributes: scoreAttributes)
             }
             var scoreCiImage = CIImage(image: scoreImage)!
            // Rotate this image
            scoreCiImage = scoreCiImage.oriented(.left)
             // add text to the image
             let scoreCiImageWithBackground = scoreCiImage.composited(over: ciImage)
             // add image to the buffer
             context.render(scoreCiImageWithBackground, to: pixelBuffer)
 
            //Conver to buffer again to add pixelBufferAdaptor
            var timingInfo = CMSampleTimingInfo()
            timingInfo.presentationTimeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            timingInfo.duration = CMSampleBufferGetDuration(sampleBuffer)
            var videoInfo: CMVideoFormatDescription?
            CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer, formatDescriptionOut: &videoInfo)
            var sampleBuffer: CMSampleBuffer?
            CMSampleBufferCreateReadyWithImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer, formatDescription: videoInfo!, sampleTiming: &timingInfo, sampleBufferOut: &sampleBuffer)
            
            // Add buffer to assetWriter' session
            pixelBufferAdaptor.append(CMSampleBufferGetImageBuffer(sampleBuffer!)!, withPresentationTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer!))
            
            rtmpStream.appendSampleBuffer(sampleBuffer!)
            frameCount += 1
        }
        else {
            rtmpStream.appendSampleBuffer(sampleBuffer)
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
        print("updated")
    }
}
