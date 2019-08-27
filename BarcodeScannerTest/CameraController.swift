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
    private var allMetadataOutObjectTypes: [AVMetadataObject.ObjectType] = [.ean8,
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
    
    func tapToFocus(tap: UITapGestureRecognizer, in view: UIView) {
        let touchPoint:CGPoint = tap.location(in: view)
        let convertedPoint:CGPoint = previewLayer.captureDevicePointConverted(fromLayerPoint: touchPoint)
        
        guard let cameraDevice = cameraDevice else {
            return
        }
        
        if cameraDevice.isFocusPointOfInterestSupported && cameraDevice.isFocusModeSupported(AVCaptureDevice.FocusMode.autoFocus){
            do {
                try cameraDevice.lockForConfiguration()
                cameraDevice.focusPointOfInterest = convertedPoint
                cameraDevice.focusMode = .autoFocus
                cameraDevice.unlockForConfiguration()
                
                DispatchQueue.global().asyncAfter(deadline: .now() + 1.0, execute: {
                    do {
                        try cameraDevice.lockForConfiguration()
                        cameraDevice.focusMode = .continuousAutoFocus
                        cameraDevice.unlockForConfiguration()
                    } catch {
                        print(error)
                    }
                })
                
            } catch let error {
                print(error)
            }
        }
    }
    
    func setRectOfInterest(_ rect: CGRect) {
        metadataOutput.rectOfInterest = rect
    }
}

private extension CameraController {
    func configureSession() {
        queue.async {
            
            self.session.sessionPreset = .inputPriority
            
            self.cameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: self.position)
            
            if let cameraDevice = self.cameraDevice, let input = try? AVCaptureDeviceInput(device: cameraDevice), self.session.canAddInput(input) {
                self.session.addInput(input)
                
                let captureSessionCenter = CGPoint(x: self.previewLayer.frame.midX, y: self.previewLayer.frame.midY)
                let convertedPoint = self.previewLayer.layerPointConverted(fromCaptureDevicePoint: captureSessionCenter)
                
                do {
                    try cameraDevice.lockForConfiguration()
                    cameraDevice.focusMode = .continuousAutoFocus
                    cameraDevice.focusPointOfInterest = convertedPoint
                    cameraDevice.unlockForConfiguration()
                } catch {
                    print(error)
                }
            }
            
            self.cameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: self.position)
            
            if self.session.canAddOutput(self.metadataOutput) {
                self.session.addOutput(self.metadataOutput)
                self.metadataOutput.setMetadataObjectsDelegate(self, queue: self.queue)
                
                var availableOutputTypes: [AVMetadataObject.ObjectType] = []
                
                for outputType in self.allMetadataOutObjectTypes {
                    if self.metadataOutput.availableMetadataObjectTypes.contains(outputType) {
                        availableOutputTypes.append(outputType)
                    }
                }
                
                self.metadataOutput.metadataObjectTypes = availableOutputTypes
            }
        }
    }
    
    func showAccessDeniedMessage() {
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
