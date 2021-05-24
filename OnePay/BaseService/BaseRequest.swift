//
//  BaseRequest.swift
//  OnePay
//
//  Created by Palani Krishnan on 5/17/19.
//  Copyright © 2019 Certify Global. All rights reserved.
//

import Foundation

class BaseRequest {
    let defaults = UserDefaults.standard
    
    func makeRequestWith(urlString:String, method:String, params:Data?) -> NSURLRequest {
        let url:NSURL = NSURL(string:urlString)!
        let request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = method
        request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringCacheData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        //request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = params
        if (urlString == APIs().paymentAPI()) {
//            if defaults.bool(forKey: "called") {
//                request.setValue("1000:38743C", forHTTPHeaderField:"x-authorization")
//            } else {
                request.setValue(Session.shared.ApiKey(), forHTTPHeaderField:"x-authorization")
               // defaults.set(true, forKey: "called")
          //  }

        } else if let accessToken = Session.shared.accessToken() , let tokenType = Session.shared.tokenType() {
            if(urlString != APIs().loginAPI()) {
                let tokenString = tokenType + " " + accessToken
                request.setValue(tokenString, forHTTPHeaderField: "Authorization")
                request.addValue(Session.shared.gatewayId()!, forHTTPHeaderField: "GatewayId")
                if(urlString == APIs().getTerminalIdsAPI()) {
                    request.setValue(Session.shared.userId(), forHTTPHeaderField: "UserId")
                }
            }
        }
        return request
    }
}
