//
//  ApiKeyService.swift
//  OnePay
//
//  Created by Palani Krishnan on 7/15/19.
//  Copyright © 2019 Certify Global. All rights reserved.
//

import Foundation
import SwiftyJSON

class ApiKeyService: BaseRequest {
    
    var url: String!
    var params = [String:Any]()
    
    func getApiKeyFromServer(success: @escaping (_ apiKey:String?, Error?) -> Void) {
        
        let parameters = ["terminalId":PaymentSettings.shared.selectedTerminalId()!, "GatewayId":Session.shared.gatewayId()!] as [String : Any]
        
        if let postData = (try? JSONSerialization.data(withJSONObject: parameters, options: [])) {
            
        self.url = APIs().getApiKeyAPI()
        self.params = parameters
                   
        let request = makeRequestWith(urlString: APIs().getApiKeyAPI(), method: "POST", params: postData)
        let session = URLSession.shared
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
            guard let data = data, let _ = response, error == nil else {
                let event = AppCenterTrack(api: self.url, parameters: self.params as [String : AnyObject], response: error.debugDescription, type: .normal)
                event.sendLogToAppCenter()
                success(nil, error)
                return
            }
            do {
                let jsonValue = try JSON(data: data, options: .allowFragments)
                success(jsonValue.stringValue, nil)
                
            } catch let myJSONError {
                print(myJSONError)
                let event = AppCenterTrack(api: self.url, parameters: self.params as [String : AnyObject], response: myJSONError.localizedDescription, type: .normal)
                event.sendLogToAppCenter()
                success(nil, myJSONError)
            }
        }
        
        task.resume()
      }
  }

    
    func getTerminalIdsFromServer(success: @escaping (_ json:JSON?, Error?) -> Void) {
        
        let request = makeRequestWith(urlString: APIs().getTerminalIdsAPI(), method: "GET", params: nil)
        self.url = APIs().getTerminalIdsAPI()
        let session = URLSession.shared
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
            guard let data = data, let _ = response, error == nil else {
                let event = AppCenterTrack(api: self.url, parameters: nil, response: error.debugDescription, type: .normal)
                event.sendLogToAppCenter()
                success(nil, error)
                return
            }
            self.parseTerminalIds(data: data, onComplete: { (json, err)  in
                success(json, err)
            })
        }
        
        task.resume()
    }
    
    
    func parseTerminalIds(data: Data, onComplete:@escaping(_ json:JSON?, Error?) -> Void) {
        do {
            let json = try JSON(data: data)
            onComplete(json, nil)
        } catch let myJSONError {
            print(myJSONError)
            let event = AppCenterTrack(api: self.url, parameters: nil, response: myJSONError.localizedDescription, type: .normal)
            event.sendLogToAppCenter()
            onComplete(nil, myJSONError)
        }
    }
    
    
}
