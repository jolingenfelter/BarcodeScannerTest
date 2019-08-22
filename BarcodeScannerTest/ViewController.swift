//
//  ViewController.swift
//  BarcodeScannerTest
//
//  Created by Jo Lingenfelter on 8/22/19.
//  Copyright © 2019 ns804. All rights reserved.
//

import UIKit
import AVKit

class ViewController: UIViewController  {
    let cameraController = CameraController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        cameraController.delegate = self
        cameraController.startPreview()
        
        view.layer.addSublayer(cameraController.previewLayer)
        
        let overlay = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 300))
        overlay.layer.borderColor = UIColor.green.cgColor
        overlay.layer.borderWidth = 15
        
        view.addSubview(overlay)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        cameraController.previewLayer.frame = view.bounds
    }
}

extension ViewController: CameraControllerDelegate {
    func cameraController(_ cameraController: CameraController, didScanCode: String) {
        cameraController.stopPreview()
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        
        display(alert: "Success", message: didScanCode, okHandler: { _ in
            self.cameraController.startPreview()
        }, okIsDestructive: false)
    }
}

