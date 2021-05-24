//
//  Checkout.swift
//  OnePay
//
//  Created by Palani Krishnan on 5/21/19.
//  Copyright © 2019 Certify Global. All rights reserved.
//

import Foundation

class Checkout: NSObject {
    var enteredAmount:String!
   // var itemName: String?
    
    init(amount:String) {
        self.enteredAmount = amount
//        self.itemName = item
    }
}
