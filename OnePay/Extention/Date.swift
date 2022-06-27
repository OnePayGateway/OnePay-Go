//
//  Date.swift
//  OnePay
//
//  Created by Palani Krishnan on 7/16/19.
//  Copyright © 2019 Certify Global. All rights reserved.
//

import Foundation

extension Date {
    
    static func changeDaysBy(days : Int) -> String {
        let currentDate = Date()
        var dateComponents = DateComponents()
        dateComponents.day = days
        let dateValue = Calendar.current.date(byAdding: dateComponents, to: currentDate)!
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy hh:mm a"
        return (formatter.string(from: dateValue) as NSString) as String
    }
    
    func generateCurrentTimeStampAsNonce () -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmss"
        return (formatter.string(from: self) as NSString) as String
    }
    
    func generateCurrentDateString () -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        return (formatter.string(from: self) as NSString) as String
    }
    
    func generateCurrentDateTime () -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy, hh:mm a"
        return (formatter.string(from: self) as NSString) as String
    }
    
    func days(from date: Date) -> Int {
        return Calendar.current.dateComponents([.day], from: date, to: self).day ?? 0
    }
    
}
