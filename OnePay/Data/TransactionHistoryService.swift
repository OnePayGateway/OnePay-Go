//
//  TransactionHistoryService.swift
//  OnePay
//
//  Created by Palani Krishnan on 7/15/19.
//  Copyright © 2019 Certify Global. All rights reserved.
//

import Foundation
import SwiftyJSON

class TransactionHistoryService: BaseRequest {

    var url: String!
    var params = [String:Any]()
    
    func retrieveTransactions(from: String, to: String, onComplete: @escaping(JSON?, Error?) -> ()) {
        
        let parameters = ["Fromdate":from, "Todate":to, "MerchantTerminalId":PaymentSettings.shared.selectedTerminalId()!] as [String : Any]
        
        self.url = APIs().retrieveTransactionsAPI()
        self.params = parameters
        
        if let postData = (try? JSONSerialization.data(withJSONObject: parameters, options: [])) {
            
            let request = makeRequestWith(urlString: APIs().retrieveTransactionsAPI(), method: "POST", params: postData)
            let session = URLSession.shared
            let task = session.dataTask(with: request as URLRequest) {
                (
                data, response, error) in
                guard let data = data, let _:URLResponse = response, error == nil else {
                    print("error")
                    let event = AppCenterTrack(api: self.url, parameters: self.params as [String : AnyObject], response: error.debugDescription, type: .normal)
                    event.sendLogToAppCenter()
                    onComplete(nil,error!)
                    return
                }
                self.parseTransactionsData(data: data, onComplete: { (dic, err) in
                    onComplete(dic,err)
                })
            }
            task.resume()
        }
    }


    func parseTransactionsData(data:Data, onComplete: @escaping(JSON?, Error?) -> ()) {
            do {
                let dict = try JSON(data: data, options: .fragmentsAllowed)
                onComplete(dict,nil)
            } catch let myJSONError {
                print(myJSONError)
                let event = AppCenterTrack(api: self.url, parameters: self.params as [String : AnyObject], response: myJSONError.localizedDescription, type: .normal)
                event.sendLogToAppCenter()
                onComplete(nil,myJSONError)
            }
    }

}
