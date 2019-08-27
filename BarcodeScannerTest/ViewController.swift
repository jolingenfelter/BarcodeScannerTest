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
    
    lazy var tap: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(tap:)))
        return gesture
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        cameraController.delegate = self
        cameraController.startPreview()
        
        view.layer.addSublayer(cameraController.previewLayer)
        
        view.addGestureRecognizer(tap)
        
        let center = CGPoint(x: view.frame.midX, y: view.frame.midY)
        let rect = CGRect(x: 0, y: 0, width: 300, height: 200)
        
        let boxView = UIView(frame: rect)
        boxView.center = center
        boxView.layer.borderColor = UIColor.green.cgColor
        boxView.layer.borderWidth = 15

        view.addSubview(boxView)
        cameraController.setRectOfInterest(rect)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        cameraController.previewLayer.frame = view.bounds
    }
}

private extension ViewController {
    @objc
    func handleTap(tap: UITapGestureRecognizer) {
        cameraController.tapToFocus(tap: tap, in: view)
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

