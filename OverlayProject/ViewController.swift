//
//  ViewController.swift
//  OverlayProject
//
//  Created by Saltuk Bugra OZELGUL on 7.05.2023.
//

import UIKit
import SwiftUI
import AVFoundation

class ViewController : UIViewController {
    
 private var  permissionGranted = false
 private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    
    private var previewLayer = AVCaptureVideoPreviewLayer()
    var screenRect: CGRect! = nil
    
    override func  viewDidLoad() {
        checkPermission()
        
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
        
        // Create and add text layer to the overlay layer
        let overlayLayer = CALayer()
        overlayLayer.frame = previewLayer.frame
        overlayLayer.masksToBounds = true
            let textLayer = CATextLayer()
            textLayer.string = "Top Left"
            textLayer.fontSize = 24
            textLayer.foregroundColor = UIColor.white.cgColor
            textLayer.frame = CGRect(x: 10, y: 10, width: 100, height: 30)
        overlayLayer.addSublayer(textLayer)
        
        // Add the overlay layer to the preview layer's superlayer
        previewLayer.superlayer?.addSublayer(overlayLayer)
        
        // Updates to UI must be on main queue
        DispatchQueue.main.async { [weak self] in
            self!.view.layer.addSublayer(self!.previewLayer)
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
