//
//  ViewController.swift
//  OnePay
//
//  Created by Palani Krishnan on 5/16/19.
//  Copyright © 2019 Certify Global. All rights reserved.
//

import UIKit
import SkyFloatingLabelTextField
import SideMenuSwift

class LoginViewController: UIViewController, UITextFieldDelegate {
    
//    @IBOutlet weak var unHeight: NSLayoutConstraint!
//    @IBOutlet weak var psHeight: NSLayoutConstraint!
//    @IBOutlet weak var psFieldTop: NSLayoutConstraint!
//    @IBOutlet weak var unFieldTop: NSLayoutConstraint!
    @IBOutlet weak var loginView: LoginView!
    let loginService = LoginService()

    var login : Login? {
        didSet {
            guard let loggedIn = login else { return }
            if loggedIn.message == "SUCCESS" {
                Session.shared.setLoggedIn()
                Session.shared.setUser(name: loggedIn.userName)
                Session.shared.setUser(id: loggedIn.userId)
                Session.shared.setUser(type: loggedIn.userType)
                Session.shared.setUser(email: loggedIn.userEmail)
                Session.shared.setEmailConfirmed(status: loggedIn.emailConfirmed)
                Session.shared.setGateway(id: loggedIn.gatewayId)
                Session.shared.setAccess(token: loggedIn.accessToken)
                Session.shared.setToken(type: loggedIn.tokenType)
                Session.shared.setRefresh(token: loggedIn.refreshToken)
                Session.shared.setTerminal(Id: loggedIn.terminalId)
                self.getAllActiveTerminalIdsFor()

            } else {
                self.hideSpinner()
                self.loginView.msgLbl.text = loggedIn.message
                self.loginView.usernameField.layer.borderColor = UIColor.red.cgColor
                self.loginView.pswField.layer.borderColor = UIColor.red.cgColor
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loginView.usernameField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        loginView.usernameField.setLeftPaddingPoints(10)
        loginView.usernameField.setRightPaddingPoints(10)
        loginView.pswField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        loginView.pswField.setLeftPaddingPoints(10)
        loginView.pswField.setRightPaddingPoints(10)
        // Do any additional setup after loading the view.
    }
    
    
    @objc func textFieldDidChange(_ textfield: UITextField) {
        if let text = textfield.text {
            self.loginView.msgLbl.text = ""
            if #available(iOS 13.0, *) {
                self.loginView.usernameField.layer.borderColor = UIColor.systemGray4.cgColor
                self.loginView.pswField.layer.borderColor = UIColor.systemGray4.cgColor

            } else {
                self.loginView.usernameField.layer.borderColor = UIColor.lightGray.cgColor
                self.loginView.pswField.layer.borderColor = UIColor.lightGray.cgColor
                // Fallback on earlier versions
            }
        }
    }
    
//    override var preferredStatusBarStyle: UIStatusBarStyle {
//        return .default
//    }
    
    @IBAction func signInClicked(_ sender: Any) {

        guard let emailText = loginView.usernameField.text?.trimmingCharacters(in: CharacterSet.whitespaces), !emailText.isEmpty else {
            self.loginView.msgLbl.text = "Please enter username"
            self.loginView.usernameField.layer.borderColor = UIColor.red.cgColor
            return
        }
        guard let password = loginView.pswField.text, !password.isEmpty else {
            self.loginView.msgLbl.text = "Please enter password"
            self.loginView.pswField.layer.borderColor = UIColor.red.cgColor
            return
        }

        showSpinner(onView: self.view)
        loginService.loginWith(username: emailText, password: password) { login,err  in
            DispatchQueue.main.async {
                if(err != nil) {
                    print("error is\(err!.localizedDescription)")
                    self.loginView.msgLbl.text = err?.localizedDescription
                    self.hideSpinner()
                } else {
                    self.login = login
                }
            }
        }
    }
    
    @IBAction func viewPaswdClicked(_ sender: Any) {
        if let btn = sender as? UIButton {
            if btn.isSelected {
                self.loginView.pswField.isSecureTextEntry = true
            } else {
                self.loginView.pswField.isSecureTextEntry = false
            }
            btn.isSelected = !btn.isSelected
        }
    }
    
    func getAllActiveTerminalIdsFor() {
        ApiKeyService().getTerminalIdsFromServer(success:  { (json, err)  in
            DispatchQueue.main.async {

            guard err == nil else {
                self.hideSpinner()
                self.loginView.msgLbl.text = err?.localizedDescription
                return
            }
            
            let msg = json?.dictionaryValue["Message"]
            if msg == "Authorization has been denied for this request." {
                LoginService().refreshTokenInServer(success: { (status) in
                    if status == true {
                        self.getAllActiveTerminalIdsFor()
                    } else {
                        self.hideSpinner()
                        Session.shared.logOut()
                        let loginVc = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateInitialViewController()
                        self.view.window?.rootViewController = loginVc
                    }
                })
                return
            }
            
            if let jsonArr = json?.arrayValue, jsonArr.count > 0 {
                    var activeTerminalIds = Array<String>()
                    var activeTerminalTypes = Array<String>()
                    var activeTerminalNames = Array<String>()
                    for dict in jsonArr {
                        let terminalType = dict["TerminalType"].stringValue
                        let activeState = dict["Active"].boolValue
                        if (terminalType == "RETAIL" || terminalType == "MOTO") && (activeState == true){
                            let merchantId = dict["Id"].stringValue
                            let terminalName = dict["TerminalName"].stringValue
                            activeTerminalIds.append(merchantId)
                            activeTerminalTypes.append(terminalType)
                            activeTerminalNames.append(terminalName)
                        }
                    }
                    if(activeTerminalIds.count != 0) {
                        PaymentSettings.shared.setSelectedTerminal(Id: activeTerminalIds[0])
                        PaymentSettings.shared.setSelectedTerminal(Type: activeTerminalTypes[0])
                        PaymentSettings.shared.setActiveTerminal(Ids: activeTerminalIds)
                        PaymentSettings.shared.setActiveTerminal(Types: activeTerminalTypes)
                        PaymentSettings.shared.setActiveTerminal(Names: activeTerminalNames)

                        self.hideSpinner()
                        
                       // UIApplication.shared.statusBarUIView?.backgroundColor = UIColor.black
                        let sideMenuVc = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "sideMenuVc")
                        self.view.window?.rootViewController = sideMenuVc
                        
                    } else {
                        Session.shared.logOut()
                        self.loginView.msgLbl.text = "No active terminal id available"
                        self.hideSpinner()
                    }
            } else {
                Session.shared.logOut()
                self.loginView.msgLbl.text = "No terminal id available"
                self.hideSpinner()
            }
          }
        })
        
    }
    

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let portalVc = segue.destination as? PortalWebviewViewController
        portalVc?.urlString = segue.identifier == "Register" ? APIs().appBaseAPI() : APIs().forgotPasswordAPI()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

