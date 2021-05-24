//
//  ReceiptViewController.swift
//  OnePay
//
//  Created by Palani Krishnan on 6/7/19.
//  Copyright © 2019 Certify Global. All rights reserved.
//

import UIKit
import SkyFloatingLabelTextField

class ReceiptViewController: UIViewController,UITextFieldDelegate {
    @IBOutlet weak var receiptView: ReceiptView!
   // @IBOutlet weak var pnFieldTop: NSLayoutConstraint!
    @IBOutlet weak var emailFieldTop: NSLayoutConstraint!
    
    var reference_transaction_id: String!
    let receiptService = ReceiptService()
    var receipt = Receipt()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        receipt.setTransaction(Id: reference_transaction_id)
        
        receiptView.emailField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
     //   receiptView.phoneNumberField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        let value = UIInterfaceOrientation.portrait.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
        UIViewController.attemptRotationToDeviceOrientation()
        
        let numberToolbar: UIToolbar = UIToolbar()
        numberToolbar.barStyle = UIBarStyle.default
        
        let view = UIView()
        view.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        let btn = UIButton(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        btn.setTitle("Done", for: .normal)
        btn.addTarget(self, action: #selector(doneClicked), for: .touchUpInside)
        btn.setTitleColor(.blue, for: .normal)
        view.addSubview(btn)
        let rightButtonItem = UIBarButtonItem(customView: view)
        //constraints
        let widthConstraint = view.widthAnchor.constraint(equalToConstant: 44)
        let heightConstraint = view.heightAnchor.constraint(equalToConstant: 44)
        heightConstraint.isActive = true
        widthConstraint.isActive = true
        //add my view to nav bar
        numberToolbar.items=[
            UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: self, action: nil),
            rightButtonItem
        ]
        numberToolbar.sizeToFit()
      //  receiptView.phoneNumberField.inputAccessoryView = numberToolbar
        
        // Do any additional setup after loading the view.
    }
    
    
    @objc func doneClicked () {
      //  receiptView.phoneNumberField.resignFirstResponder()
        self.view.endEditing(true)
    }
    
//    override var preferredStatusBarStyle: UIStatusBarStyle {
//        return .lightContent
//    }
    
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    func showReceiptAlertWith(title: String, btnName: String, success:Bool) {
        
        let showAlert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        let imageView = UIImageView(frame: CGRect(x: 110, y: 70, width: 50, height: 50))
        imageView.image = success == true ? UIImage(named:"approved") : UIImage(named:"declined")
        showAlert.view.addSubview(imageView)
        
        let height = NSLayoutConstraint(item: showAlert.view as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 200)
        
        let width = NSLayoutConstraint(item: showAlert.view as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 250)
        
        showAlert.view.addConstraint(height)
        showAlert.view.addConstraint(width)
        
        showAlert.addAction(UIAlertAction(title: btnName, style: .default, handler: { action in
            if(success) {
                self.navigationController?.popToRootViewController(animated: true)
            }
        }))
        self.present(showAlert, animated: true, completion: nil)
    }
    
    
    func createApiKey() {
        ApiKeyService().getApiKeyFromServer(success: { (key, er) in
            DispatchQueue.main.async {
            guard er == nil else {
                self.hideSpinner()
                self.displayAlert(title: "Something went wrong", message: er!.localizedDescription)
                return
            }
            
            print("api key is\(key!)")
            Session.shared.setApi(Key: key!)
            self.sendReceipt()
            }
        })
    }
    
    
    func sendReceipt() {
        self.receiptService.sendReceipt(receipt:receipt) { (jsonValue, err) in
            DispatchQueue.main.async {
                guard err == nil else {
                    self.hideSpinner()
                    self.displayAlert(title: err!.localizedDescription, message: "")
                    return
                }
                guard let json = jsonValue else {
                    self.hideSpinner()
                    self.displayAlert(title: "Something went wrong", message: "")
                    return
                }
                print(json)
                self.hideSpinner()
                let response = json["transaction_response"].dictionaryValue
                if let code = response["result_code"]?.intValue, code == 1 {
                    print("payment success")
                    self.showReceiptAlertWith(title: "Receipt will be sent shortly", btnName: "Done", success: true)
                } else if let status = response["result_text"]?.stringValue {
                    print(status)
                    self.showReceiptAlertWith(title: "Something went wrong, Please try again", btnName: "Done", success: false)
                }
            }
        }
    }
    
    @IBAction func submitClicked(_ sender: Any) {
        if let emailText = receiptView.emailField.text?.trimmingCharacters(in: CharacterSet.whitespaces)
//            , let phoneNo = receiptView.phoneNumberField.text?.trimmingCharacters(in: CharacterSet.whitespaces)
        {
            //|| !phoneNo.isEmpty
            if(!emailText.isEmpty) {
                if((emailText.count != 0) && (emailText.count < 3 || !emailText.contains("@"))) {
                    receiptView.emailField.errorMessage = "Invalid email"
                    return
                } else {
                    receipt.set(email: emailText)
                }
//                if(phoneNo.count == 10) {
//                    receipt.setPhone(Number: phoneNo)
//                } else {
//                    self.displayAlert(title: "Missing Field", message: "Please enter valid phone number.")
//                    return
//                }
            } else {
                self.displayAlert(title: "Missing Field", message: "Please enter email.")
                return
            }
        }
        showSpinner(onView: self.view)
        createApiKey()
    }
    
    @IBAction func cancelClicked(_ sender: Any) {
        self.navigationController?.popToRootViewController(animated: true)
    }
    @IBAction func backBtnClicked(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func textFieldDidChange(_ textfield: UITextField) {
        if let text = textfield.text {
            if let floatingLabelTextField = textfield as? SkyFloatingLabelTextField {
                DispatchQueue.main.async {
//                    if floatingLabelTextField == self.receiptView.phoneNumberField {
//                        if(text.count == 0) {
//                            self.pnFieldTop.constant = 13
//                        }
//                        else {
//                            self.pnFieldTop.constant = 21
//                        }
//                    } else {
                        if(text.count == 0) {
                            floatingLabelTextField.errorMessage = ""
                            self.emailFieldTop.constant = 15
                        }
                        else {
                            self.emailFieldTop.constant = 23
                            floatingLabelTextField.errorMessage = ""
                        }
                 //  }
              }
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
