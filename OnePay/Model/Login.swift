//
//  Login.swift
//  OnePay
//
//  Created by Palani Krishnan on 5/17/19.
//  Copyright © 2019 Certify Global. All rights reserved.
//

import Foundation

class Login : NSObject {
    
    var userName: String
    var userId: String
    var userType: String
    var emailConfirmed: Bool
    var gatewayId: String
    var accessToken: String
    var tokenType: String
    var refreshToken: String
    var message: String
    var terminalId: String
    
    
    init(msg: String, username:String, userid:String, usertype:String, emailconfirmed: Bool, gatewayid:String, accesstoken: String, tokentype: String, refreshtoken: String, terminalid: String) {
        self.userName = username
        self.userId = userid
        self.userType = usertype
        self.emailConfirmed = emailconfirmed
        self.gatewayId = gatewayid
        self.accessToken = accesstoken
        self.tokenType = tokentype
        self.refreshToken = refreshtoken
        self.message = msg
        self.terminalId = terminalid
    }
}
