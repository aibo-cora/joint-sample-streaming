//
//  CGImage.swift
//  joint-sample-streaming
//
//  Created by Yura on 12/17/22.
//

import Foundation
import VideoToolbox

extension CGImage {
    static func create(from buffer: CVPixelBuffer?) -> CGImage? {
        guard
            let pixelBuffer = buffer
        else { return nil }
        
        var cgImage: CGImage?
        
        VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: nil, imageOut: &cgImage)
        
        return cgImage
    }
}
