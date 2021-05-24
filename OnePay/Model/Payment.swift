//
//  PaymentMode.swift
//  OnePay
//
//  Created by Palani Krishnan on 5/22/19.
//  Copyright © 2019 Certify Global. All rights reserved.
//

import Foundation

struct Payment {
    var amount: String!
    let type_code = "2"
    let customDic:Dictionary = ["id":"1", "value":"ONEPAY GO TEST"]
    let userDic: Dictionary = ["id":"USER", "value":Session.shared.userName()!]
    let sourceDic: Dictionary = ["id":"SOURCE", "value":"ONEPAYGO"]
    //let ldic: Dictionary = ["id":"L2L3", "value":"L2"]
    //let lCountdic: Dictionary = ["id":"L3COUNT", "value":"0"]
    //let taxIndDic: Dictionary = ["id":"TAXINDICATOR", "value":"0"]
}
