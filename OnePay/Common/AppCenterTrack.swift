//
//  AppCenterTrack.swift
//  CertifyAUTH
//
//  Created by Palani Krishnan on 12/19/19.
//  Copyright © 2019 Certify. All rights reserved.
//

import Foundation
import AppCenter
import AppCenterAnalytics
import AppCenterCrashes

class AppCenterTrack {
    
    var event: String = ""
    var properties: [String:String] = [:]
    var flag : Flags = .default
    
    init(api:String, parameters:[String:AnyObject]?, response:String, type:Flags) {
        event = api
        var logParameters: [String: String] = [:]
          if let params = parameters {
              for (key, value) in params {
                  let strData = String(describing: value)
                  logParameters[key] = strData
              }
          }
        logParameters["response"] = response
        properties = logParameters
        flag = type
    }
    
    func sendLogToAppCenter() {
        Analytics.trackEvent(event, withProperties: properties, flags: flag)
    }
    
}
