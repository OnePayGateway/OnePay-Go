//
//  PaymentService.swift
//  OnePay
//
//  Created by Palani Krishnan on 5/23/19.
//  Copyright © 2019 Certify Global. All rights reserved.
//

import Foundation
import SwiftyJSON

class PaymentService: BaseRequest {
    
    var url: String!
    var params = [String:Any]()
    
    func makePayment(payment:Payment, cardInfo:Dictionary<String, Any>, customerInfo:Dictionary<String, Any>, emv:Dictionary<String,Any>?, device_code:String, Oncomplete: @escaping(JSON?, Error?) -> Void) {
        
        var parameters = [String : Any]()
        let amount = payment.amount
        if(emv != nil) {
            parameters = ["amount":amount!, "method":"CC", "type":payment.type_code, "nonce":Date().generateCurrentTimeStampAsNonce(), "test":"0", "device_code":"MAGTEK", "market_code":PaymentSettings.shared.selectedTerminalType() == "MOTO" ? "M":"R", "referrer_url":"onepay.com", "emv":emv!] as [String : Any]
            
        } else {
            var locDic: Dictionary = ["id":"Location", "value":"0;0"]
            if let location = Session.shared.userLoc() {
                locDic["value"] = location
            }
            let custom_fields = [payment.customDic]
            let additionalData: [[String:Any]] = [payment.userDic,payment.sourceDic, locDic]
            
            parameters = ["amount":amount!, "method":"CC", "type":payment.type_code, "nonce":Date().generateCurrentTimeStampAsNonce(), "test":"0", "client_ip":"172.26.15.177","device_code":device_code, "market_code":PaymentSettings.shared.selectedTerminalType() == "MOTO" ? "M":"R", "referrer_url":"onepay.com", "notes":"", "card":cardInfo, "customer": customerInfo, "custom_fields": custom_fields, "additional_data":additionalData] as [String : Any]
        }
        print(parameters)
        self.url = APIs().paymentAPI()
        self.params = parameters
        
//        let defaults = UserDefaults.standard
//        defaults.set(false, forKey: "called")
        
        if let postData = (try? JSONSerialization.data(withJSONObject: parameters, options: [])) {
            
            let request = self.makeRequestWith(urlString: APIs().paymentAPI(), method: "POST", params: postData)
            let session = URLSession.shared
            let task = session.dataTask(with: request as URLRequest) {
                (data, response, error) in
                
                guard let data = data, let _:URLResponse = response, error == nil else {
                    print("error")
                    let event = AppCenterTrack(api: self.url, parameters: self.params as [String : AnyObject], response: error.debugDescription, type: .normal)
                    event.sendLogToAppCenter()
                    Oncomplete(nil, error)
                    return
                }
                do {
                    let jsonValue = try JSON(data: data, options: .allowFragments)
                    if let dataFromString = jsonValue.stringValue.data(using: .utf8, allowLossyConversion: false) {
                        do {
                            let json = try JSON(data: dataFromString)
                            Oncomplete(json, nil)
                            return
                        } catch let error {
                            let event = AppCenterTrack(api: self.url, parameters: self.params as [String : AnyObject], response: error.localizedDescription, type: .normal)
                            event.sendLogToAppCenter()
                            Oncomplete(nil, error)
                            return
                        }
                    }
                    
                } catch let error {
                    print(error)
                    let event = AppCenterTrack(api: self.url, parameters: self.params as [String : AnyObject], response: error.localizedDescription, type: .normal)
                    event.sendLogToAppCenter()
                    Oncomplete(nil, error)
                }
            }
            task.resume()
        }
        
   }

}

