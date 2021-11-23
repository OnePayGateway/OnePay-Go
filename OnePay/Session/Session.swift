//
//  Session.swift
//  OnePay
//
//  Created by Palani Krishnan on 5/17/19.
//  Copyright © 2019 Certify Global. All rights reserved.
//


import Foundation
import UIKit

class Session : NSObject {
    
    private let ZONE_API: String = "ZONE_API"
    private let LOGGED_IN: String = "LOGGED_IN"
    private let USER_NAME: String = "USER_NAME"
    private let USER_ID: String = "USER_ID"
    private let USER_TYPE: String = "USER_TYPE"
    private let EMAIL_CONFIRMED: String = "EMAIL_CONFIRMED"
    private let GATEWAY_ID: String = "GATEWAY_ID"
    private let API_KEY: String = "API_KEY"

    private let ACCESS_TOKEN: String = "ACCESS_TOKEN"
    private let TOKEN_TYPE: String = "TOKEN_TYPE"
    private let REFRESH_TOKEN: String = "REFRESH_TOKEN"
    private let TERMINAL_ID: String = "TERMINAL_ID"
    private let USER_LOC: String = "USER_LOC"
    private let DEFAULT_PED_KEY: String = "DEFAULT_PED_KEY"
    private let DEFAULT_POS_KEY: String = "DEFAULT_POS_KEY"

    private override init() {}
    static let shared = Session()
    private let defaults = UserDefaults.standard
    
    func setApi(Zone:NSInteger) {
        defaults.set(Zone, forKey: ZONE_API)
    }
    
    func apiZone() -> Int? {
        return defaults.integer(forKey: ZONE_API)
    }
    
    func setLoggedIn() {
        defaults.set(true, forKey: LOGGED_IN)
    }
    
    func isLoggedIn() -> Bool {
        return defaults.bool(forKey: LOGGED_IN)
    }
    
    func setEmailConfirmed(status:Bool) {
        defaults.set(status, forKey: EMAIL_CONFIRMED)
    }
    
    func isEmailConfirmed() -> Bool {
        return defaults.bool(forKey: EMAIL_CONFIRMED)
    }
    
    func setUser(name:String) {
        if(!name.isEmpty) {
            defaults.setValue(name, forKey: USER_NAME)
        }
    }
    func userName() -> String? {
        return defaults.value(forKey: USER_NAME) as? String
    }
    
    func setUser(id:String) {
        if(!id.isEmpty) {
            defaults.setValue(id, forKey: USER_ID)
        }
    }
    func userId() -> String? {
        return defaults.value(forKey: USER_ID) as? String
    }
    
    func setUser(type:String) {
        if(!type.isEmpty) {
            defaults.setValue(type, forKey: USER_TYPE)
        }
    }
    
    func userType() -> String? {
        return defaults.value(forKey: USER_TYPE) as? String
    }
    
    func setGateway(id:String) {
        if(!id.isEmpty) {
            defaults.setValue(id, forKey: GATEWAY_ID)
        }
    }
    
    func gatewayId() -> String? {
        return defaults.value(forKey: GATEWAY_ID) as? String
    }
    
    func setAccess(token:String) {
        if(!token.isEmpty) {
            defaults.setValue(token, forKey: ACCESS_TOKEN)
        }
    }
    func accessToken() -> String? {
        return defaults.value(forKey: ACCESS_TOKEN) as? String
    }
    
    func setToken(type:String) {
        if(!type.isEmpty) {
            defaults.setValue(type, forKey: TOKEN_TYPE)
        }
    }
    func tokenType() -> String? {
        return defaults.value(forKey: TOKEN_TYPE) as? String
    }
    
    func setRefresh(token:String) {
        if(!token.isEmpty) {
            defaults.setValue(token, forKey: REFRESH_TOKEN)
        }
    }
    func refreshToken() -> String? {
        return defaults.value(forKey: REFRESH_TOKEN) as? String
    }
    
    func setTerminal(Id:String) {
        if(!Id.isEmpty) {
            defaults.setValue(Id, forKey: TERMINAL_ID)
        }
    }
    
    func terminalId() -> String? {
        return defaults.value(forKey: TERMINAL_ID) as? String
    }
    
    func setApi(Key:String) {
        if(!Key.isEmpty) {
            defaults.setValue(Key, forKey: API_KEY)
        }
    }
    
    func ApiKey() -> String? {
        return defaults.value(forKey: API_KEY) as? String
    }
    
    func setUser(Loc:String) {
        if(!Loc.isEmpty) {
            defaults.setValue(Loc, forKey: USER_LOC)
        }
    }
    
    func userLoc() -> String? {
        return defaults.value(forKey: USER_LOC) as? String
    }
    
    
    var defaultPED: String? {
        get {
            return defaults.string(forKey: DEFAULT_PED_KEY)
        }
        set(newValue) {
            defaults.set(newValue, forKey: DEFAULT_PED_KEY)
            defaults.synchronize()
        }
    }
    var defaultPOS: String? {
        get {
            return defaults.string(forKey: DEFAULT_POS_KEY)
        }
        set(newValue) {
            defaults.set(newValue, forKey: DEFAULT_POS_KEY)
            defaults.synchronize()
        }
    }
    
    func logOut() {
        
        defaults.removeObject(forKey: LOGGED_IN)
        defaults.removeObject(forKey: USER_NAME)
        defaults.removeObject(forKey: USER_ID)
        defaults.removeObject(forKey: USER_TYPE)
        defaults.removeObject(forKey: EMAIL_CONFIRMED)
        defaults.removeObject(forKey: GATEWAY_ID)
        defaults.removeObject(forKey: TERMINAL_ID)
        defaults.removeObject(forKey: ACCESS_TOKEN)
        defaults.removeObject(forKey: TOKEN_TYPE)
        defaults.removeObject(forKey: REFRESH_TOKEN)
        defaults.removeObject(forKey: API_KEY)
        defaults.removeObject(forKey: USER_LOC)
    }
}
