//
//  CardView.swift
//  OnePay
//
//  Created by Palani Krishnan on 2/1/22.
//  Copyright © 2022 Certify Global. All rights reserved.
//

import Foundation
import UIKit

enum Fields: Int {
  case cardNo = 11,
       expiry,
       cvc
}

protocol CardViewDelegate: NSObject {
    func CardViewTextFieldDidChange()
}

class CardView: UIView {
    
    private var cardNumberField: UITextField!
    private var expirationDateField: UITextField!
    private var cvcField: UITextField!
    
    var cardNumber: String?
    var expiryDate: String?
    var cvc: String?
    
    var field: Fields!
    weak var cardViewDelegate: CardViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func isValid() -> Bool {
        guard cardNumber != nil else {
            cardNumberField.layer.borderColor = UIColor.red.cgColor
            return false
        }
        
        cardNumberField.layer.borderColor = UIColor.lightGray.cgColor
        
        guard expiryDate != nil else {
            expirationDateField.layer.borderColor = UIColor.red.cgColor
            return false
        }
        
        expirationDateField.layer.borderColor = UIColor.lightGray.cgColor
        
        guard cvc != nil else {
            cvcField.layer.borderColor = UIColor.red.cgColor
            return false
        }
        
        cvcField.layer.borderColor = UIColor.lightGray.cgColor
        
        return true
    }
    
    func clear() {
        cardNumberField.text = ""
        expirationDateField.text = ""
        cvcField.text = ""
        cardNumber = nil
        expiryDate = nil
        cvc = nil
    }
    
    func resignResponder() {
        cardNumberField.resignFirstResponder()
        expirationDateField.resignFirstResponder()
        cvcField.resignFirstResponder()
    }
    
    private func commonInit() {
        
        let padding = 10
        let totalWidth = UIScreen.main.bounds.width-94
        let cardFieldWidth = Int(totalWidth*100)/100
        let expirationFieldWidth = Int((Int(totalWidth)-padding)*50)/100
        let cvcFieldWidth = Int((Int(totalWidth) - padding)*50)/100

        let cardFieldX = 0
        let expirationFieldX = 0
        let cvcFieldX = expirationFieldX+expirationFieldWidth+padding

        cardNumberField = UITextField(frame: CGRect(x: cardFieldX, y: 0, width: cardFieldWidth, height: 50))
        cardNumberField.keyboardType = .numberPad
        cardNumberField.placeholder = "Card Number"
        cardNumberField.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        cardNumberField.borderStyle = .roundedRect
        cardNumberField.textAlignment = .center
        cardNumberField.delegate = self
        cardNumberField.tag = 11
        
        expirationDateField = UITextField(frame: CGRect(x: 0, y: 60, width: expirationFieldWidth, height: 50))
        expirationDateField.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        expirationDateField.borderStyle = .roundedRect
        expirationDateField.placeholder = "MM/YY"
        expirationDateField.keyboardType = .numberPad
        expirationDateField.textAlignment = .center
        expirationDateField.delegate = self
        expirationDateField.tag = 12

        cvcField = UITextField(frame: CGRect(x: cvcFieldX, y: 60, width: cvcFieldWidth, height: 50))
        cvcField.keyboardType = .numberPad
        cvcField.placeholder = "CVC"
        cvcField.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        cvcField.borderStyle = .roundedRect
        cvcField.textAlignment = .center
        cvcField.delegate = self
        cvcField.tag = 13

        cardNumberField.layer.borderWidth = 1.0
        cardNumberField.layer.borderColor = UIColor.lightGray.cgColor
        cardNumberField.layer.cornerRadius = 5.0

        
        expirationDateField.layer.borderWidth = 1.0
        expirationDateField.layer.borderColor = UIColor.lightGray.cgColor
        expirationDateField.layer.cornerRadius = 5.0

        
        cvcField.layer.borderWidth = 1.0
        cvcField.layer.borderColor = UIColor.lightGray.cgColor
        cvcField.layer.cornerRadius = 5.0
        
        addSubview(cardNumberField)
        addSubview(expirationDateField)
        addSubview(cvcField)
    }
    
}

extension CardView : UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        field = Fields(rawValue: textField.tag)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard let text = textField.text else {
            return
        }
        print(text)
        handleAllFields(text: text)
        cardViewDelegate?.CardViewTextFieldDidChange()
    }
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        guard let text = textField.text else {
            return
        }
        print(text)
        handleAllFields(text: text)
        cardViewDelegate?.CardViewTextFieldDidChange()
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        guard let oldText = textField.text, let r = Range(range, in: oldText) else {
            return true
        }
        let updatedText = oldText.replacingCharacters(in: r, with: string)
        switch field {
        case .cardNo:
               cardNumber = nil
                switch CardState(fromPrefix: updatedText) {
                case .identified(let card):
                    print("\(card)")
                    if card.isValid(updatedText) {
                        print("valid card")
                        return true
                    } else if updatedText.count <= card.maxLength {
                        print("invalid card and not exceeded max length")
                        if card.isValid(oldText), !string.isEmpty {
                            cardNumber = oldText
//                            expirationDateField.becomeFirstResponder()
                            return false
                        }
                        return true
                    } else {
                        print("invalid card and exceeded max length")
                       return false
                    }
                    //do something with card
                case .indeterminate(let possibleCards):
                    return true
                    //do something with possibleCards
                case .invalid:
                    return false
                    //show some validation error
                }

        case .expiry:
                
               if string == "" {
                    if updatedText.count == 0 {
                        expirationDateField.text = ""
                       // cardNumberField.becomeFirstResponder()
                        return false
                    }
                    if updatedText.count == 2 {
                        textField.text = "\(updatedText.prefix(1))"
                        return false
                    }
                   return true
                } else if updatedText.count == 1 {
                    if updatedText > "1" {
                        return false
                    }
                } else if updatedText.count == 2 {
                    if updatedText <= "12", updatedText != "00" { //Prevent user to not enter month more than 12
                        textField.text = "\(updatedText)/" //This will add "/" when user enters 2nd digit of month
                    }
                    return false
                } else if updatedText.count == 4 {
                    let lastdigit = updatedText.suffix(1)
                    if lastdigit < "2" {
                        return false
                    }
                } else if updatedText.count == 5 {
                    return true
                } else if updatedText.count > 5 {
                    expiryDate = oldText
                   // cvcField.becomeFirstResponder()
                    return false
                }
            
            return true

        case .cvc:
            
            if string == "" {
                 if updatedText.count == 0 {
                     cvcField.text = ""
                    // expirationDateField.becomeFirstResponder()
                     return false
                 }
            }
            guard let cardNumber =  cardNumberField.text, CardState(fromNumber: cardNumber) != .invalid else {
                return false
            }
            if CardState(fromNumber: cardNumber) == .identified(.amex), updatedText.count <= 4 {
                return true
            } else if updatedText.count <= 3 {
                return true
            }
            return false
        case .none:
            return true
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }
}

extension CardView {
    
    func isExpDateValid(dateStr:String) -> Bool {

        let currentYear = Calendar.current.component(.year, from: Date()) % 100   // This will give you current year (i.e. if 2019 then it will be 19)
        let currentMonth = Calendar.current.component(.month, from: Date()) // This will give you current month (i.e if June then it will be 6)

        let enteredYear = Int(dateStr.suffix(2)) ?? 0 // get last two digit from entered string as year
        let enteredMonth = Int(dateStr.prefix(2)) ?? 0 // get first two digit from entered string as month
        print(dateStr) // This is MM/YY Entered by user

        if enteredYear > currentYear {
            if (1 ... 12).contains(enteredMonth) {
                print("Entered Date Is Right")
                return true
            } else {
                print("Entered Date Is Wrong")
            }
        } else if currentYear == enteredYear {
            if enteredMonth >= currentMonth {
                if (1 ... 12).contains(enteredMonth) {
                   print("Entered Date Is Right")
                    return true
                } else {
                   print("Entered Date Is Wrong")
                }
            } else {
                print("Entered Date Is Wrong")
            }
        } else {
           print("Entered Date Is Wrong")
        }
       return false
    }
    
    
    func handleAllFields(text:String) {
        print(text)
        switch field {
        case .cardNo:
            switch CardState(fromNumber: text) {
            case .identified(let card):
                print("\(card)")
                if card.isValid(text) {
                    print("move to expirationDateField")
                    cardNumber = text
                  //  expirationDateField.becomeFirstResponder()
                }
            case .indeterminate(let possibleCards):
                print("\(possibleCards)")
                //do something with possibleCards
            case .invalid:
                print("invalid card")
                //show some validation error
            }
        
        case .expiry:
            print(text)
            if isExpDateValid(dateStr: text) {
                expiryDate = text
               // cvcField.becomeFirstResponder()
            } else {
                expiryDate = nil
            }
        case .cvc:
            print(text)
            guard let cardNumber =  cardNumberField.text, CardState(fromNumber: cardNumber) != .invalid else {
                return
            }

            if CardState(fromNumber: cardNumber) == .identified(.amex), text.count == 4 {
                cvc = text
               // cvcField.resignFirstResponder()
            } else if CardState(fromNumber: cardNumber) != .identified(.amex), text.count == 3 {
                cvc = text
              //  cvcField.resignFirstResponder()
            } else {
                cvc = nil
            }
            
        case .none:
            print(text)
        }
    }
}
