import UIKit
import SwiftUI
import OpenGLES.ES2
import AVFoundation
import Photos


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
    var wasFirstBuffer = false
    var videoOutputURL: URL!
    
    var screenRect: CGRect! = nil
    let recordButton = UIButton(type: .contactAdd)
    
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

        sessionQueue.async { [unowned self] in
            guard permissionGranted else {return}
            self.setupCaptureSession()
            self.setupAssetWriter()
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
        // Create videoOutputURL type Url and if its already exits remove first
        let videoOutputURL = URL(fileURLWithPath: documentsPath).appendingPathComponent("output.mov")
        
        // Remove file if already exits
        do {
            try FileManager.default.removeItem(at: videoOutputURL)
        } catch {
            print(error)
        }
        
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
    
    func finishAssetWriter() {
        // Finish writing session
        assetWriterInput.markAsFinished()
        assetWriter.finishWriting {
            print("Finished writing")
        }
        
        // Save the video to the photo library on main thread
        DispatchQueue.main.async { [self] in
            UISaveVideoAtPathToSavedPhotosAlbum(assetWriter.outputURL.path, nil, nil, nil)
        }
        
    }

    func captureOutput(_ captureOutput: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Adding the buffers to assetWriter session for creating video.
        if isRecording {
            if wasFirstBuffer == false {
                assetWriter.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
                wasFirstBuffer = true
            }
            
            //
            // TODO - EDIT THIS BUFFER BY USING BITMAX PAINTING OR OPENGL
            //
            
            
            // Add buffer to assetWriter' session
            pixelBufferAdaptor.append(CMSampleBufferGetImageBuffer(sampleBuffer)!, withPresentationTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
        }
       
        // print(sampleBuffer)
    
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
