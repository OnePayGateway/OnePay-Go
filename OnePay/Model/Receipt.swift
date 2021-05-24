//
//  Receipt.swift
//  OnePay
//
//  Created by Palani Krishnan on 8/9/19.
//  Copyright © 2019 Certify Global. All rights reserved.
//

import Foundation

struct Receipt {
    let action_code = "3"
    let type_code = "10"
    var ref_tran_id: String!
    var customerInfo: Dictionary<String,String> = [:]
    
    mutating func set(email:String) {
        customerInfo["email"] = email
    }
    
    mutating func setPhone(Number:String) {
        customerInfo["phone_number"] = Number
    }
    
    mutating func setTransaction(Id:String) {
        self.ref_tran_id = Id
    }
}
