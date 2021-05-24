//
//  TransactionDetail.swift
//  OnePay
//
//  Created by Palani Krishnan on 7/17/19.
//  Copyright © 2019 Certify Global. All rights reserved.
//

import Foundation

class TransactionDetail : NSObject {
    
    var itemName: String?
    var itemAmount: Float?
    var totalAmount: Float?
    var cardType: String?
    var lastFourDigits: String?
    var receiptNumber: String?

    init(itemname: String?, itemamount:Float?, totalamount:Float?, cardtype:String?, lastfour: String?, receiptnum: String?) {
        self.itemName = itemname
        self.itemAmount = itemamount
        self.totalAmount = totalamount
        self.cardType = cardtype
        self.lastFourDigits = lastfour
        self.receiptNumber = receiptnum
    }
}
