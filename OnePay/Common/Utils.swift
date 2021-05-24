//
//  Utils.swift
//  OnePay
//
//  Created by Palani Krishnan on 6/27/19.
//  Copyright © 2019 Certify Global. All rights reserved.
//

import Foundation

public func delay(_ delay:Double, closure:@escaping ()->()) {
    DispatchQueue.main.asyncAfter(
        deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
}


