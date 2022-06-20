//
//  DeviceSettings.swift
//  OnePay
//
//  Created by Palani Krishnan on 7/5/19.
//  Copyright © 2019 Certify Global. All rights reserved.
//

import Foundation
import UIKit

class PaymentSettings: NSObject {
    
    private let PAYMENT_DEVICE_ID:String = "PAYMENT_DEVICE_ID"
    
    private let SELECTED_TERMINAL_ID:String = "SELECTED_TERMINAL_ID"
    private let SELECTED_TERMINAL_TYPE:String = "SELECTED_TERMINAL_TYPE"
    private let SELECTED_TERMINAL_NAME:String = "SELECTED_TERMINAL_NAME"

    private let ACTIVE_TERMINAL_IDS: String = "ACTIVE_TERMINAL_IDS"
    private let ACTIVE_TERMINAL_TYPES: String = "ACTIVE_TERMINAL_TYPES"
    private let ACTIVE_TERMINAL_NAMES: String = "ACTIVE_TERMINAL_NAMES"

   // var lib: MTSCRA?

    private override init() {}
    static let shared = PaymentSettings()
    private let defaults = UserDefaults.standard
    
    func setPaymentDevice(id:NSInteger) {
        defaults.set(id, forKey: PAYMENT_DEVICE_ID)
    }
    
    func paymentDeviceId()-> NSInteger? {
        return defaults.integer(forKey: PAYMENT_DEVICE_ID)
    }

//    func setMagtekLib(lib:MTSCRA) {
//        self.lib = lib
//    }
//
//    func magtekLib()-> MTSCRA? {
//         return self.lib
//    }
    
    func setSelectedTerminal(Id:String) {
        defaults.set(Id, forKey: SELECTED_TERMINAL_ID)
    }

    func selectedTerminalId()-> String? {
        return defaults.value(forKey: SELECTED_TERMINAL_ID) as? String
    }
    
    func setSelectedTerminal(Type:String) {
        defaults.set(Type, forKey: SELECTED_TERMINAL_TYPE)
    }
    
    func selectedTerminalType()-> String? {
        return defaults.value(forKey: SELECTED_TERMINAL_TYPE) as? String
    }
    
    func setSelectedTerminal(Name:String) {
        defaults.set(Name, forKey: SELECTED_TERMINAL_NAME)
    }
    
    func selectedTerminalName()-> String? {
        return defaults.value(forKey: SELECTED_TERMINAL_NAME) as? String
    }
    
    func setActiveTerminal(Ids:Array<String>) {
        defaults.set(Ids, forKey: ACTIVE_TERMINAL_IDS)
    }
    
    func activeTerminalIds()-> Array<String>? {
        return defaults.value(forKey: ACTIVE_TERMINAL_IDS) as? Array
    }
    
    func setActiveTerminal(Names:Array<String>) {
        defaults.set(Names, forKey: ACTIVE_TERMINAL_NAMES)
    }
    
    func activeTerminalNames()-> Array<String>? {
        return defaults.value(forKey: ACTIVE_TERMINAL_NAMES) as? Array
    }
    
    
    func setActiveTerminal(Types:Array<String>) {
        defaults.set(Types, forKey: ACTIVE_TERMINAL_TYPES)
    }
    
    func activeTerminalTypes()-> Array<String>? {
        return defaults.value(forKey: ACTIVE_TERMINAL_TYPES) as? Array
    }
    
    func removeAll() {
        defaults.removeObject(forKey: PAYMENT_DEVICE_ID)
        defaults.removeObject(forKey: SELECTED_TERMINAL_ID)
        defaults.removeObject(forKey: SELECTED_TERMINAL_TYPE)
        defaults.removeObject(forKey: ACTIVE_TERMINAL_IDS)
        defaults.removeObject(forKey: ACTIVE_TERMINAL_TYPES)
    }
}
