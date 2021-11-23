//
//  eAaccessory.swift
//  OnePay
//
//  Created by Palani Krishnan on 8/6/21.
//  Copyright © 2021 Certify Global. All rights reserved.
//

import Foundation
import ExternalAccessory

class Config {

    static let MIURA_SHUTTLE_PROTOCOL = "com.miura.shuttle"
    static let MIURA_RPI_PROTOCOL = "com.miura.rpi"

}


extension EAAccessory {

    var deviceType: TargetDevice {
        return self.protocolStrings[0] == Config.MIURA_RPI_PROTOCOL ? TargetDevice.POS : TargetDevice.PED
    }
    
    var isDefault: Bool {
        return self.serialNumber == Session.shared.defaultPED || self.serialNumber == Session.shared.defaultPOS
    }

}


enum CurrencyCode: UInt {
    case gbp = 826 /*british pound(£)*/
    case usd = 840 /*usa dollar($)*/
    case eur = 978 /*european euro(€)*/
    case jpy = 392 /*japan yen(¥)*/
    case pln = 985 /*poland zloty(z)*/
    case cop = 170 /*columbia peso($)*/
    case inr = 356 /*india repee(R)*/
    case zar = 710 /*south african rand(R)*/
}
