//
//  RkiInitStatus+description.swift
//  MiuraSDK Payment Sample
//
//  Created by John Barton on 08/11/2019.
//  Copyright © 2019 Miura Systems Ltd. All rights reserved.
//

import Foundation

extension RkiInitStatus: CustomStringConvertible {

    public var description: String {
        switch self {
        case.fileMissing:  return "file missing"
        case.failedToGenerateRSAKey : return "Failed to Validate HSM"
        case.failedToLoadRSAKey : return "Failed to load RSA Key"
        case.failedToCreateRSACert : return "Failed to create RSA cert"
        case.failedToPrepareOutputFiles : return "Failed to prepare output files"
        case.internalError : return "Internal error"
            
        }
    }
    
}
