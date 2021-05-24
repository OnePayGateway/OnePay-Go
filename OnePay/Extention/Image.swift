//
//  Image.swift
//  OnePay
//
//  Created by Palani Krishnan on 7/16/19.
//  Copyright © 2019 Certify Global. All rights reserved.
//

import Foundation

extension UIImage {
    
    enum JPEGQuality: CGFloat {
        case lowest  = 0
        case low     = 0.25
        case medium  = 0.5
        case high    = 0.75
        case highest = 1
    }
    
    func toBase64(_ jpegQuality: JPEGQuality) -> String? {
        guard let data = self.jpegData(compressionQuality: jpegQuality.rawValue) else { return nil }
        return data.base64EncodedString(options: Data.Base64EncodingOptions.endLineWithCarriageReturn)
    }
    
    func getBase64Size(_ jpegQuality: JPEGQuality)-> String? {
        guard let data = self.jpegData(compressionQuality: jpegQuality.rawValue) else { return nil }
            print("There were \(data.count) bytes")
            let bcf = ByteCountFormatter()
            bcf.allowedUnits = [.useMB] // optional: restricts the units to MB only
            bcf.countStyle = .file
            let string = bcf.string(fromByteCount: Int64(data.count))
            print("formatted result: \(string)")
            return string
    }
    
}
