import UIKit
import SwiftUI
import AVFoundation

class ViewController : UIViewController,AVCaptureFileOutputRecordingDelegate {
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        print("Finished recording to \(outputFileURL.absoluteString)")
        recordButton.setTitle("Record", for: .normal)
    }
    
    private var  permissionGranted = false
    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    
    private var previewLayer = AVCaptureVideoPreviewLayer()
    var screenRect: CGRect! = nil
    var movieOutput = AVCaptureMovieFileOutput()
    let recordButton = UIButton(type: .system)
    
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
        }    }
    
    
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
        if movieOutput.isRecording {
            movieOutput.stopRecording()
        } else {
            let outputPath = NSTemporaryDirectory() + "output.mov"
            let outputFileURL = URL(fileURLWithPath: outputPath)
            recordButton.setTitle("Recording...", for: .normal)
            movieOutput.startRecording(to: outputFileURL, recordingDelegate: self)
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
        
        // Add new layer which have OverlayView content
//        let overlayLayer = CALayer()
//        overlayLayer.frame = previewLayer.frame
//        let textLayer = CATextLayer()
//        textLayer.string = "Top Left Text"
//        textLayer.font = UIFont.systemFont(ofSize: 20)
//        textLayer.fontSize = 20
//        textLayer.alignmentMode = .left
//        textLayer.foregroundColor = UIColor.white.cgColor
//        textLayer.frame = CGRect(x: 150, y: 150, width: 200, height: 30)
//        overlayLayer.addSublayer(textLayer)
        
        // Add movie output
        if captureSession.canAddOutput(movieOutput) {
            captureSession.addOutput(movieOutput)
            if let connection = movieOutput.connection(with: .video) {
                if connection.isVideoStabilizationSupported {
                    connection.preferredVideoStabilizationMode = .auto
                }
                if connection.isVideoOrientationSupported {
                    connection.videoOrientation = .portrait
                }
            }
        }
        
        // Updates to UI must be on main queue
        DispatchQueue.main.async { [weak self] in
            self?.view.layer.addSublayer(self!.previewLayer)
//            self?.view.layer.addSublayer(overlayLayer)
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
