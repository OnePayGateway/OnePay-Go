//
//  TransactionDetailService.swift
//  OnePay
//
//  Created by Palani Krishnan on 7/17/19.
//  Copyright © 2019 Certify Global. All rights reserved.
//

import Foundation
import SwiftyJSON

class TransactionDetailService: BaseRequest {
    
    var url: String!
    
    func getTransactionDetailFor(Id: String, onComplete: @escaping(JSON?, Error?) -> ()) {
        
        self.url = "\(APIs().getTransactionDetailAPI())/\(Id)"
        
        let request = makeRequestWith(urlString: self.url, method: "GET", params: nil)
        let session = URLSession.shared
        let task = session.dataTask(with: request as URLRequest) {
            (
            data, response, error) in
            guard let data = data, let _:URLResponse = response, error == nil else {
                print("error")
                let event = AppCenterTrack(api: self.url, parameters: nil, response: error.debugDescription, type: .normal)
                event.sendLogToAppCenter()
                onComplete(nil,error!)
                return
            }
            self.parseTransactionDetail(data: data, onComplete: { (dic, err) in
                onComplete(dic,err)
            })
        }
        task.resume()
    }
    
    
    func parseTransactionDetail(data:Data, onComplete: @escaping(JSON?, Error?) -> ()) {
        do {
            let json = try JSON(data: data)
            onComplete(json,nil)
        } catch let myJSONError {
            print(myJSONError)
            let event = AppCenterTrack(api: self.url, parameters: nil, response: myJSONError.localizedDescription, type: .normal)
            event.sendLogToAppCenter()
            onComplete(nil,myJSONError)
        }
    }
}
