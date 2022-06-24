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
    
  //  ,,"Card Last 4 Digits","Source Application"
    
    func name(forIndex:NSInteger)-> String? {
       let transaction = transactionsList[forIndex].dictionaryValue
        guard let value = transaction["Name"]?.stringValue else {
            return nil
        }
        return value
    }
    
    func firstName(forIndex:NSInteger)-> String? {
       let transaction = transactionsList[forIndex].dictionaryValue
        guard let value = transaction["FirstName"]?.stringValue else {
            return nil
        }
        return value
    }
    
    func lastName(forIndex:NSInteger)-> String? {
       let transaction = transactionsList[forIndex].dictionaryValue
        guard let value = transaction["LastName"]?.stringValue else {
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
    
    func customerId(forIndex:NSInteger)-> String? {
        let transaction = transactionsList[forIndex].dictionaryValue
        guard let value = transaction["CustomerId"]?.stringValue else {
            return nil
        }
        return value
    }
    
    func email(forIndex:NSInteger)-> String? {
       let transaction = transactionsList[forIndex].dictionaryValue
        guard let value = transaction["Email"]?.stringValue else {
            return nil
        }
        return value
    }
    
    func phone(forIndex:NSInteger)-> String? {
       let transaction = transactionsList[forIndex].dictionaryValue
        guard let value = transaction["PhoneNumber"]?.stringValue else {
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
    
    func lastFourDigit(forIndex:NSInteger)-> String? {
        let transaction = transactionsList[forIndex].dictionaryValue
        guard let value = transaction["Last4"]?.stringValue else {
            return nil
        }
        return value
    }
    
    func sourceApplication(forIndex:NSInteger)-> String? {
        let transaction = transactionsList[forIndex].dictionaryValue
        guard let value = transaction["SourceApplication"]?.stringValue else {
            return nil
        }
        return value
    }
    
}
