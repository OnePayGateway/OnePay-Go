//
//  VoidTransactionService.swift
//  OnePay
//
//  Created by Palani Krishnan on 7/17/19.
//  Copyright © 2019 Certify Global. All rights reserved.
//

import Foundation
import SwiftyJSON

class VoidTransactionService: BaseRequest {
    var url: String!
    var params = [String:Any]()
    
    
    func makePayment(amount:String, transType:String, transactionId: String, cardInfo:Dictionary<String, Any>, marketCode:String, Oncomplete: @escaping(JSON?, Error?) -> Void) {
        
        let payment = Payment()
        let custom_fields = [payment.customDic]
        let additionalData = [payment.userDic,payment.sourceDic]
        
        let parameters = ["amount":amount, "method":"CC", "type":transType, "nonce":Date().generateCurrentTimeStampAsNonce(), "reference_transaction_id":transactionId,  "notes":"", "card":cardInfo, "custom_fields": custom_fields, "additionalData":additionalData] as [String : Any]
        
        self.url = APIs().paymentAPI()
        self.params = parameters
        
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

