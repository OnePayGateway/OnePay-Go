//
//  ReceiptService.swift
//  OnePay
//
//  Created by Palani Krishnan on 8/9/19.
//  Copyright © 2019 Certify Global. All rights reserved.
//

import Foundation
import SwiftyJSON

class ReceiptService: BaseRequest {
    var url: String!
    var params = [String:Any]()
    
    func sendReceipt(receipt:Receipt, Oncomplete: @escaping(JSON?, Error?) -> Void) {
        
        let payment = Payment()
        let additionalData: [[String:Any]] = [payment.sourceDic]
        
        let parameters = ["method":"CC", "type":receipt.type_code, "action_code":receipt.action_code, "nonce":Date().generateCurrentTimeStampAsNonce(), "reference_transaction_id":receipt.ref_tran_id!,"customer": receipt.customerInfo, "additional_data":additionalData] as [String : Any]
        print(parameters)
        
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
                    let jsonValue = try JSON(data: data, options: .fragmentsAllowed)
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

