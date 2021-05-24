//
//  Signature.swift
//  OnePay
//
//  Created by Palani Krishnan on 8/9/19.
//  Copyright © 2019 Certify Global. All rights reserved.
//

import Foundation

struct Signature {
    let action_code = "2"
    let type_code = "10"
    var ref_tran_id: String!
    var signatureDic: Dictionary<String,String> = [:]
    
    mutating func setSignature(base64Str:String) {
        self.signatureDic["id"] = "SIGNATURE"
        self.signatureDic["value"] = base64Str
    }
    
    mutating func setTransaction(Id:String) {
        self.ref_tran_id = Id
    }
}
