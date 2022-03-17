//
//  BaseAPIs.swift
//  OnePay
//
//  Created by Palani Krishnan on 5/17/19.
//  Copyright © 2019 Certify Global. All rights reserved.
//

import Foundation

struct APIs {
    
//    let appBaseURL = "https://portalqa.onepay.com"
//    let gatewayBaseURL = "https://apiqa.onepay.com/"
    
    let appProdBaseURL = "https://portal.onepay.com"
    let appDemoBaseURL = "https://demo.onepay.com"
    let appTestBaseURL = "https://portalqa.onepay.com"
    let appDevBaseURL = "https://portaldev.onepay.com"

    let gatewayProdBaseURL = "https://api.onepay.com/"
    let gatewayDemoBaseURL = "https://apisandbox.onepay.com/"
    let gatewayTestBaseURL = "https://apiqa.onepay.com/"
    let gatewayDevBaseURL = "https://apidev.onepay.com/"

    let loginRelativeURL = "/EP/Token"
    let getApiKeyURL = "/EP/api/Merchant/GetApiKey"
    let retrieveTransactionsURL = "/EP/api/Transaction/RetriveTransaction"
    let getTransactionDetailURL = "/EP/api/Transaction/GetTransactionDetails"
    let getTerminalIdsURL = "/EP/api/Merchant/GetTerminalAccessList"
    let paymentRelativeURL = "/Transaction"
    let forgotPasswordRelativeUrl = "/forgot-password"
    
    func appBaseAPI()-> String {
        if Session.shared.apiZone() == 1 {
            return appDemoBaseURL
        } else if Session.shared.apiZone() == 2 {
            return appTestBaseURL
        } else if Session.shared.apiZone() == 3 {
            return appDevBaseURL
        }
        return appProdBaseURL
    }
    
    func loginAPI() -> String {
        return self.appBaseAPI() + self.loginRelativeURL
    }
    
    func getTerminalIdsAPI() -> String {
        return self.appBaseAPI() + self.getTerminalIdsURL
    }
    
    func getApiKeyAPI() -> String {
        return self.appBaseAPI() + self.getApiKeyURL
    }
    
    func retrieveTransactionsAPI() -> String {
        return self.appBaseAPI() + self.retrieveTransactionsURL
    }
    
    func getTransactionDetailAPI() -> String {
        return self.appBaseAPI() + self.getTransactionDetailURL
    }
    
    func forgotPasswordAPI() -> String {
        return self.appBaseAPI() + self.forgotPasswordRelativeUrl
    }
    
    func gatewayBaseAPI()-> String {
        if Session.shared.apiZone() == 1 {
            return gatewayDemoBaseURL
        } else if Session.shared.apiZone() == 2 {
            return gatewayTestBaseURL
        } else if Session.shared.apiZone() == 3 {
            return gatewayDevBaseURL
        }
        return gatewayProdBaseURL
    }
    
    func paymentAPI() -> String {
        return self.gatewayBaseAPI() + self.paymentRelativeURL
    }
    
}

