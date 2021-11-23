//
//  RkiImportStatus+description.swift
//  MiuraSDK Payment Sample
//
//  Created by John Barton on 04/11/2019.
//  Copyright © 2019 Miura Systems Ltd. All rights reserved.
//

import Foundation

extension RkiImportStatus: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case.noError : return "No error found"
        case.hsmFileMissing :  return "Data missing"
        case.failedToValidateHSM : return "Failed to Validate HSM"
        case.failedToLoadRSAKey : return "Failed to load RSA Key"
        case.failedToValidateTransportKey : return "Validaye transportKey = failed"
        case.failedToInstallDUKPT_Key :return "Dukpt key - failed"
        case.failedToInstallDUKPT_Init : return "Dukpt init - failed"
        case.internalError : return "Internal error"
        }
    }

}
