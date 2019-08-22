//
//  PreviewView.swift
//  FieldApp
//
//  Created by Jo Lingenfelter on 3/12/19.
//  Copyright © 2019 ns804. All rights reserved.
//

import AVKit

class PreviewView: UIView {
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    /// Convenience wrapper to get layer as its statically known type.
    lazy var videoPreviewLayer: AVCaptureVideoPreviewLayer = {
        return layer as! AVCaptureVideoPreviewLayer
    }()
}
