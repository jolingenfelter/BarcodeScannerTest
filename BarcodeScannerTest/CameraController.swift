//
//  CameraController.swift
//  BarcodeScannerTest
//
//  Created by Jo Lingenfelter on 8/22/19.
//  Copyright © 2019 ns804. All rights reserved.
//

import AVFoundation
import UIKit

protocol CameraControllerDelegate: class {
    func cameraController(_ cameraController: CameraController, didScanCode: String)
}

final class CameraController: NSObject {
    private let queue = DispatchQueue(label: "com.barcodeScannerTest.CameraController")
    private let session = AVCaptureSession()
    private let stillCameraOutput = AVCapturePhotoOutput()
    private let metadataOutput = AVCaptureMetadataOutput()
    
    private let position: AVCaptureDevice.Position = .back
    private var cameraDevice: AVCaptureDevice?
    
    let previewLayer: AVCaptureVideoPreviewLayer
    
    weak var delegate: CameraControllerDelegate?
    
    override init() {
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        
        super.init()
    
        previewLayer.videoGravity = .resizeAspectFill
        
        let authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch authorizationStatus {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { (granted) in
                if granted {
                    self.configureSession()
                } else {
                    DispatchQueue.main.async {
                        self.showAccessDeniedMessage()
                    }
                }
            })
        case .authorized:
            configureSession()
        case .denied, .restricted:
            showAccessDeniedMessage()
        default:
            showAccessDeniedMessage()
        }
        
        // Without this call all `UIDevice.current.orientation` responses will be 0
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(orientationDidChange(_:)),
                                               name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    deinit {
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }
    
    func startPreview() {
        queue.async {
            self.session.startRunning()
        }
    }
    
    func stopPreview() {
        queue.async {
            self.session.stopRunning()
        }
    }
}

private extension CameraController {
    func configureSession() {
        queue.async {
            
            session.sessionPreset = .photo
            
            self.cameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: self.position)
            
            if self.session.canAddOutput(self.metadataOutput) {
                self.session.addOutput(self.metadataOutput)
                self.metadataOutput.metadataObjectTypes = [.ean8,
                                                           .ean13,
                                                           .pdf417,
                                                           .aztec,
                                                           .code128,
                                                           .code39,
                                                           .code39Mod43,
                                                           .code93,
                                                           .dataMatrix,
                                                           .face,
                                                           .interleaved2of5,
                                                           .itf14,
                                                           .qr,
                                                           .upce]
            }
            
            self.updateOrientation()
        }
    }
    
    func updateOrientation() {
        dispatchPrecondition(condition: .onQueue(queue))
        guard let orientation = AVCaptureVideoOrientation(rawValue: UIDevice.current.orientation.rawValue) else { return }
        self.previewLayer.connection?.videoOrientation = orientation
    }
    
    func showAccessDeniedMessage() {
        
    }
    
    @objc
    func orientationDidChange(_ notification: Notification) {
        queue.async {
            self.updateOrientation()
        }
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate
extension CameraController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject, let stringValue = object.stringValue else {
            return
        }
        
        DispatchQueue.main.async {
            self.delegate?.cameraController(self, didScanCode: stringValue)
        }
    }
}
