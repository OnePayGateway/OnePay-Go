//
//  LoginService.swift
//  OnePay
//
//  Created by Palani Krishnan on 5/17/19.
//  Copyright © 2019 Certify Global. All rights reserved.
//

import Foundation
import SwiftyJSON

class LoginService: BaseRequest {
    
    var url: String!
    var params: String!
    
    func loginWith(username: String, password: String, onComplete complete: @escaping(Login?, Error?) -> ()) {
        
        let paramString = "grant_type=password&username=\(username)&password=\(password)"
        let postData = paramString.data(using: String.Encoding.utf8)
        
        self.url = APIs().loginAPI()
        self.params = paramString
        
        let request = makeRequestWith(urlString: APIs().loginAPI(), method: "POST", params: postData)
        let session = URLSession.shared
        let task = session.dataTask(with: request as URLRequest) {
            (
            data, response, error) in
            guard let data = data, let _:URLResponse = response, error == nil else {
                let event = AppCenterTrack(api: self.url, parameters: ["request":self.params as AnyObject], response: error.debugDescription, type: .normal)
                event.sendLogToAppCenter()
                complete(nil,error!)
                return
            }
            self.parseLoggedInData(data: data, onComplete: { (login, err) in
                complete(login,err)
            })
        }
        task.resume()
    }
    
    
    func parseLoggedInData(data:Data, onComplete: @escaping(Login?, Error?) -> ()) {
        do {
            let dict = try JSON(data: data)
            print(dict)
            let event = AppCenterTrack(api: self.url, parameters: ["request":self.params as AnyObject], response: dict.debugDescription, type: .normal)
            event.sendLogToAppCenter()
            DispatchQueue.main.async {
                if dict["IsTrue"].boolValue == true {
                    
                    let userName = dict["userName"].stringValue
                    let userId = dict["UserId"].stringValue
                    let userType = dict["UserType"].stringValue
                    let userEmail = dict["email"].stringValue
                    let emailConfirmed = dict["emailConfirmed"].boolValue
                    let gatewayId = dict["GatewayId"].stringValue
                    let accessToken = dict["access_token"].stringValue
                    let tokenType = dict["token_type"].stringValue
                    let refreshToken = dict["refresh_token"].stringValue
                    let terminalId = dict["terminalId"].stringValue
                    
                    let login = Login(msg: "SUCCESS", username: userName, userid: userId, usertype: userType, email: userEmail, emailconfirmed: emailConfirmed, gatewayid: gatewayId, accesstoken: accessToken, tokentype: tokenType, refreshtoken: refreshToken, terminalid: terminalId)
                    onComplete(login,nil)
                    
                } else {
                    let message = dict["Response"].stringValue
                    let login = Login(msg: message, username: "", userid: "", usertype: "", email: "", emailconfirmed: false, gatewayid: "", accesstoken: "", tokentype: "", refreshtoken: "", terminalid: "")
                    
                    let event = AppCenterTrack(api: self.url, parameters: ["request":self.params as AnyObject], response: message, type: .normal)
                                   event.sendLogToAppCenter()
                    
                    onComplete(login,nil)
                }
            }
        } catch let myJSONError {
            print(myJSONError)
            let event = AppCenterTrack(api: self.url, parameters: ["request":self.params as AnyObject], response: myJSONError.localizedDescription, type: .normal)
            event.sendLogToAppCenter()
            onComplete(nil,myJSONError)
        }
    }
    
    func refreshTokenInServer(success: @escaping (_ done:Bool) -> Void) {
        
        if let refreshToken = Session.shared.refreshToken() {
            let paramString = "grant_type=refresh_token&refresh_token=\(refreshToken)"
            let postData = paramString.data(using: String.Encoding.utf8)
            
            self.url = APIs().loginAPI()
            self.params = paramString
            
            let request = makeRequestWith(urlString: APIs().loginAPI(), method: "POST", params: postData)
            let session = URLSession.shared
            let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
                guard let data = data, let _ = response, error == nil else {
                    
                    let event = AppCenterTrack(api: self.url, parameters: ["request":self.params as AnyObject], response: error.debugDescription, type: .normal)
                                   event.sendLogToAppCenter()
                    
                    success(false)
                    return
                }
                self.parseTokenData(data: data, onComplete: { (status) in
                    success(status)
                })
            }
            task.resume()

        }
   }
    
    
    func parseTokenData(data: Data, onComplete:@escaping(_ status:Bool) -> Void) {
        do {
            let dict = try JSON(data: data)
            DispatchQueue.main.async {
                let status = dict["IsTrue"].boolValue
                let token = dict["access_token"].stringValue
                let tokenType = dict["token_type"].stringValue
                let refreshToken = dict["refresh_token"].stringValue
                if status == true {
                    Session.shared.setAccess(token: token)
                    Session.shared.setToken(type: tokenType)
                    Session.shared.setRefresh(token: refreshToken)
                    onComplete(status)
                } else {
                    let event = AppCenterTrack(api: self.url, parameters: ["request":self.params as AnyObject], response: dict.debugDescription, type: .normal)
                    event.sendLogToAppCenter()
                    onComplete(status)
                }
            }
        } catch let myJSONError {
            print(myJSONError)
            let event = AppCenterTrack(api: self.url, parameters: ["request":self.params as AnyObject], response: myJSONError.localizedDescription, type: .normal)
            event.sendLogToAppCenter()
            onComplete(false)
        }
    }
    
    func getProfileData(success: @escaping (_ json:JSON?, Error?) -> Void) {
        guard let userid = Session.shared.userId() else {
            return
        }
        self.url = String(format: "%@%@", APIs().getProfileAPI(), userid)
        let request = makeRequestWith(urlString: self.url, method: "GET", params: nil)
        let session = URLSession.shared
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
            guard let data = data, let _ = response, error == nil else {
                let event = AppCenterTrack(api: self.url, parameters: nil, response: error.debugDescription, type: .normal)
                event.sendLogToAppCenter()
                success(nil, error)
                return
            }
            self.parseProfile(data: data, onComplete: { (json, err)  in
                success(json, err)
            })
        }
        
        task.resume()
    }
    
    func parseProfile(data: Data, onComplete:@escaping(_ json:JSON?, Error?) -> Void) {
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

