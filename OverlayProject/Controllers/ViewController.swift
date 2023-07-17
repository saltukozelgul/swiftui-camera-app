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
    
    let awu = AssetWriterUtils()
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
            DispatchQueue.main.async {
                self.recordButton.setTitle("Stop", for: .normal)
            }
        } else {
            // Demolish timer
            DispatchQueue.main.async {
                self.recordButton.setTitle("Record", for: .normal)
            }
            finishAssetWriter()
        }
    }
    
    func setupAssetWriter() {
        assetWriter = awu.setAssetWriter()!
        assetWriterInput = awu.setAssetWriterInput()
        assetWriter.add(assetWriterInput)
        pixelBufferAdaptor = awu.setPixelBufferAdaptor(assetWriterInput)
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
                    print("Saved to library video name: \(self.assetWriter.outputURL.path)")
                }
                self.restartAssetWriter()
            }
        } else {
            print("Error: AssetWriter status is \(assetWriter.status)")
            print("Error: AssetWriter error is \(String(describing: assetWriter.error))")
        }
    }
        
    func restartAssetWriter() {
        self.assetWriter = nil
        self.assetWriterInput = nil
        self.pixelBufferAdaptor = nil
        // Restart writing session
        self.setupAssetWriter()
        if let safeTimer = self.timer {
            safeTimer.invalidate()
        }
        self.duration = 0
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


