//
//  TransactionHistory.swift
//  OnePay
//
//  Created by Palani Krishnan on 7/16/19.
//  Copyright © 2019 Certify Global. All rights reserved.
//

import Foundation
import SwiftyJSON

struct TransactionHistory {
    var transactionsList = [JSON]()
    
    func name(forIndex:NSInteger)-> String? {
       let transaction = transactionsList[forIndex].dictionaryValue
        guard let value = transaction["Name"]?.stringValue else {
            return nil
        }
        return value
    }
    
    func transactionId(forIndex:NSInteger)-> String? {
        let transaction = transactionsList[forIndex].dictionaryValue
        guard let value = transaction["TransactionId"]?.stringValue else {
            return nil
        }
        return value
    }
    
    func status(forIndex:NSInteger)-> String? {
        let transaction = transactionsList[forIndex].dictionaryValue
        guard let value = transaction["Status"]?.stringValue else {
            return nil
        }
        return value
    }
    
    func amount(forIndex:NSInteger)-> Double? {
        let transaction = transactionsList[forIndex].dictionaryValue
        guard let value = transaction["TransactionAmount"]?.doubleValue else {
            return nil
        }
        return value
    }
    
    func transactionDate(forIndex:NSInteger)-> String? {
        let transaction = transactionsList[forIndex].dictionaryValue
        guard let value = transaction["DateTime"]?.stringValue else {
            return nil
        }
        return value
    }
    
    func cardType(forIndex:NSInteger)-> String? {
        let transaction = transactionsList[forIndex].dictionaryValue
        guard let value = transaction["CardType"]?.stringValue else {
            return nil
        }
        return value
    }
}
