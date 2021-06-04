//
//  HomeViewController.swift
//  OnePay
//
//  Created by Palani Krishnan on 5/17/19.
//  Copyright © 2019 Certify Global. All rights reserved.
//

import UIKit
import Stripe
import SwiftyJSON
import CoreLocation
import SkyFloatingLabelTextField
import ApplicationInsights


let actualViewHeight:Float = 477.0
//let additionalHeight:Float = 200.0
let modeViewHeight:Float = 70.0
let modeExpandedHeight:Float = 140.0

class CheckoutViewController: UIViewController, STPPaymentCardTextFieldDelegate, BBDeviceControllerDelegate, CLLocationManagerDelegate, settingDelegate, UITextFieldDelegate,UIActionSheetDelegate, MTSCRAEventDelegate, BLEScanListEvent {
    
    var lib: MTSCRA!;
    var devicePaired : Bool?
    var cmdCompletion: cmdCompBlock?

    var userSelection:UIActionSheet?;
    var tmrTimeout:Timer?;
    var arqcFormat : UInt8?
     var tempAmount = [UInt8] (repeating: 0, count: 6)
     var amount = [UInt8] (repeating: 0, count: 6)

//     var currencyCode = [UInt8] (repeating: 0, count: 2)
//     var cashBack = [UInt8] (repeating: 0, count: 6)
     
     let ARQC_DYNAPRO_FORMAT : UInt8 = 0x01
     let ARQC_EDYNAMO_FORMAT : UInt8 = 0x00
     
     typealias commandCompletion = (String?) -> Void

    var locationManager: CLLocationManager!
    let geoCoder = CLGeocoder()

    @IBOutlet weak var grayBgView: UIView!
    @IBOutlet weak var checkOutView: CheckoutView!
    @IBOutlet weak var paymentModeView: PaymentModeView!
    @IBOutlet weak var numberBoardView: UIView!
    var paymentTextField = STPPaymentCardTextField()
    var plsSwipeView: UIView!
    
    @IBOutlet weak var instructionLbl: UILabel!
    @IBOutlet weak var modeView: UIView!
    @IBOutlet weak var modeViewHeight: NSLayoutConstraint!
    
    @IBOutlet weak var manualEntryView: UIView!
    @IBOutlet weak var cardSwipeView: UIView!
    @IBOutlet weak var manualEntryViewHeight: NSLayoutConstraint!
    @IBOutlet weak var cardSwipeViewHeight: NSLayoutConstraint!
    @IBOutlet weak var optionalFieldsTableView: UITableView!
    @IBOutlet weak var optionalFieldsViewHeight: NSLayoutConstraint!
    
    @IBOutlet weak var creditcardSwipeLbl: UILabel!
    
    @IBOutlet weak var firstNameField: SkyFloatingLabelTextField!
    @IBOutlet weak var lastNameField: SkyFloatingLabelTextField!
    @IBOutlet weak var customerIdField: SkyFloatingLabelTextField!
    @IBOutlet weak var invoiceNumberField: SkyFloatingLabelTextField!
    @IBOutlet weak var notesField: SkyFloatingLabelTextField!
    
    @IBOutlet weak var fnTop: NSLayoutConstraint!
    @IBOutlet weak var lnTop: NSLayoutConstraint!
    @IBOutlet weak var cIdTop: NSLayoutConstraint!
    @IBOutlet weak var noteTop: NSLayoutConstraint!
    @IBOutlet weak var ivTop: NSLayoutConstraint!
    
    @IBOutlet weak var connectBtn: UIButton!
    @IBOutlet weak var confirmBtn: UIButton!
    var pvIsUp: Bool!
    var modeViewUpdatedHeight: CGFloat!
    
    var customerInfo = Dictionary<String, Any>()
    var cardInfo = Dictionary<String, Any>()
    var emv:Dictionary<String, Any>? = nil
    let paymentService = PaymentService()
    var payment = Payment()
    var ref_tran_id: String!
    var flashing = false

    var checkout: Checkout? {
        didSet {
            guard let checkout = checkout else {
                return
            }
            if(checkout.enteredAmount.count > 2) {
                checkOutView.chargeBtn.blink()
            } else {
                checkOutView.chargeBtn.blink(enabled: false)
            }
            let amount = Double(checkout.enteredAmount)
            let amountWithDecimal:Double = amount!/100
            let finalAmount = String(format: "%.2f", amountWithDecimal)
            payment = Payment(amount: finalAmount)
            let finalStr = String(format: "$%.2f", amountWithDecimal)
            checkOutView.amountLbl.text = finalStr
            checkOutView.chargeBtn.setTitle("Charge \(finalStr)", for: .normal)
        }
    }
   
    @IBAction func chargeBtnClicked(_ sender: Any) {
        if(checkout != nil) {
            startLocationFetching()
            pullUpPaymentModeView()
        } else {
            self.displayAlert(title: "Please enter amount", message: "")
        }
    }
    
    func resetPaymentModeView() {
        
        self.firstNameField.text = ""
        self.lastNameField.text = ""
        self.customerIdField.text = ""
        self.invoiceNumberField.text = ""
        self.notesField.text = ""

        if(self.pvIsUp) {
            pullDownPaymentModeView()
        }
        pullDownPaymentModeView()
        
    }
    
    @IBAction func confirmBtnClicked(_ sender: Any) {
        
        showSpinner(onView: self.view)
        
        if let fname = self.firstNameField.text?.trimmingCharacters(in: CharacterSet.whitespaces), !fname.isEmpty {
            customerInfo["first_name"] = self.firstNameField.text
        }
        
        if let lname = self.lastNameField.text?.trimmingCharacters(in: CharacterSet.whitespaces), !lname.isEmpty {
            customerInfo["last_name"] = self.lastNameField.text
        }
        
        if let cusId = self.customerIdField.text?.trimmingCharacters(in: CharacterSet.whitespaces), !cusId.isEmpty {
            customerInfo["customer_id"] = self.customerIdField.text
        }
        
        if let ivnumber = self.invoiceNumberField.text?.trimmingCharacters(in: CharacterSet.whitespaces), !ivnumber.isEmpty {
            customerInfo["invoice_number"] = self.invoiceNumberField.text
        }
        
        if let note = self.notesField.text?.trimmingCharacters(in: CharacterSet.whitespaces), !note.isEmpty {
            customerInfo["notes"] = self.notesField.text
        }
        
        if let cardNo = cardInfo["number"] as? String, cardNo.isEmpty {
            self.cardSwipeSelected(Any.self)
        } else {
            self.manualEntryClicked(Any.self)
        }
        
        self.resetPaymentModeView()
        createApiKey()
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
            self.makeTransaction()
            }
        })
    }
    
    func makeTransaction() {
        self.paymentService.makePayment(payment:payment, cardInfo: self.cardInfo, customerInfo: self.customerInfo, emv: emv) { (jsonValue, err) in
            DispatchQueue.main.async {
                self.removeDisplayedBrandImage()
                self.connectBtn.setTitle("CONNECT", for: .normal)
                guard err == nil else {
                    self.hideSpinner()
                    self.resetPaymentInfo()
                    self.displayAlert(title: err!.localizedDescription, message: "")
                    return
                }
                guard let json = jsonValue else {
                    self.hideSpinner()
                    self.resetPaymentInfo()
                    self.displayAlert(title: "Something went wrong", message: "")
                    return
                }
                print(json)
                self.hideSpinner()
                let response = json["transaction_response"].dictionaryValue
                print(response)
                if let code = response["result_code"]?.intValue, code == 1, let trsn_id = response["transaction_id"]?.stringValue, let amount = response["amount"]?.stringValue, let authcode = response["auth_code"]?.stringValue {
                    print("payment success with\(trsn_id)")
                    self.ref_tran_id = trsn_id
                    self.confirmBtn.isEnabled = false
                    self.confirmBtn.alpha = 0.5
                    self.stopLocationFetching()
                    self.showPaymentAlertWith(title: "Approved", btnName: "Continue", amount: amount, authCode: authcode, success: true)
                } else if let status = response["result_text"]?.stringValue {
                    print(status)
                    self.resetPaymentInfo()
                    self.showPaymentAlertWith(title: "Declined", btnName: "Retry", amount: "", authCode: "", success: false)
                }
            }
        }
    }
    
    
    func showPaymentAlertWith(title: String, btnName: String, amount:String, authCode:String, success:Bool) {
        
        let showAlert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
       
        let imageView = UIImageView(frame: CGRect(x: 110, y: 70, width: 50, height: 50))
        imageView.image = success == true ? UIImage(named:"approved") : UIImage(named:"declined")
        showAlert.view.addSubview(imageView)
        
        if(success) {
            let amountLbl = UILabel(frame: CGRect(x: 10, y: 130, width: 250, height: 20))
            amountLbl.text = "Amount: $\(amount)"
            amountLbl.textAlignment = .center
            amountLbl.font = .boldSystemFont(ofSize: 16)
            showAlert.view.addSubview(amountLbl)
            
            let authLbl = UILabel(frame: CGRect(x: 10, y: 160, width: 250, height: 20))
            authLbl.text = "Auth Code: \(authCode)"
            authLbl.textAlignment = .center
            authLbl.font = .boldSystemFont(ofSize: 16)
            showAlert.view.addSubview(authLbl)
        }
        
        let height = NSLayoutConstraint(item: showAlert.view as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: success ? 260 : 200)
        
        let width = NSLayoutConstraint(item: showAlert.view as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 250)
        
        showAlert.view.addConstraint(height)
        showAlert.view.addConstraint(width)
        
        showAlert.addAction(UIAlertAction(title: btnName, style: .default, handler: { action in
            if(success) {
                self.performSegue(withIdentifier: "ManualEntryToSign", sender: nil)
            }
        }))
        self.present(showAlert, animated: true, completion: nil)
    }
    
    
    @IBAction func cancelClicked(_ sender: Any) {
        self.resetPaymentInfo()
        pullDownPaymentModeView()
    }
    
    func resetPaymentInfo() {
        DispatchQueue.main.async {
            self.lib.cancelTransaction()
            //self.lib.closeDevice()
            if(self.plsSwipeView != nil) {
                self.plsSwipeView.removeFromSuperview()
            }
            self.creditcardSwipeLbl.text = "Credit Card Swipe/Insert"
            self.removeDisplayedBrandImage()
            self.connectBtn.setTitle("CONNECT", for: .normal)
            self.confirmBtn.isEnabled = false
            self.confirmBtn.alpha = 0.5
            self.paymentTextField.clear()
            self.cardInfo = [:]
            self.emv = nil
            self.stopLocationFetching()
        }
    }
    
    func showPopUpToSetupCardReader() {
        let alertControler = UIAlertController(title: "Please setup a card reader in settings", message: "", preferredStyle: .alert)
        let yesAction = UIAlertAction(title: "Settings", style: .default) { (action) in
            if let settings = self.storyboard?.instantiateViewController(withIdentifier: "settingsController") as? AppSettingsTableViewController  {
               // DeviceSettings.shared.setTemp(Amount: self.checkout?.enteredAmount)
                settings.cameFromCheckOut = true
                settings.settDelegate = self
                self.navigationController?.present(settings, animated: true, completion: nil)
            }
           
        }
        let noAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        alertControler.addAction(yesAction)
        alertControler.addAction(noAction)
        alertControler.preferredAction = yesAction
        self.present(alertControler, animated: true, completion: nil)
    }
    
    
    @objc func startEMV() {
        guard let isamount = checkout?.enteredAmount else {
            return
        }
        var convertedAmount = ""
        var k = 0
        while k < 12-isamount.count {
            convertedAmount.append("0")
            k += 1
        }
        convertedAmount.append(isamount)
        print(convertedAmount)
        
        let dataAmount = HexUtil.getBytesFromHexString(convertedAmount)
        memcpy(&tempAmount, dataAmount?.bytes, 6)
        memcpy(&amount, &tempAmount,6);
       
        let timeLimit : UInt8 = 0x3C
        let cardType:UInt8 = 0x07;
        let option :UInt8 = 0x00;
        let transactionType:UInt8 = 0x00;
        var cashBack:[UInt8] = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00];
        var currencyCode:[UInt8] = [0x08, 0x40];
        let reportingOption:UInt8 = 0x01;
        
        sendCommand(withCallBack: "000168") { data in
            
            let format = data ?? ""
            var tempFormat : NSString = ""
            tempFormat = "\(format)" as NSString

            if tempFormat.substring(to: 1) == "02"
            {
                self.arqcFormat = 0x00
            }
            else
            {
                let tempData : NSData  = HexUtil.getBytesFromHexString(tempFormat as String)!
                if tempData.length > 2
                {
                    let data : NSData = tempData.subdata(with: NSRange(location: 2, length: 1)) as NSData
                    data.getBytes(&self.arqcFormat, length: 1)
                }
            }
            
            DispatchQueue.main.async {
                self.lib.startTransaction(timeLimit, cardType:cardType, option: option, amount: &self.amount, transactionType: transactionType, cashBack: &cashBack, currencyCode: &currencyCode, reportingOption: reportingOption)
            }
        }
    }
    
    func didSelectBLEReader(_ per: CBPeripheral) {
        self.lib.delegate = self
        self.navigationController?.popViewController(animated: true);
        self.lib.setAddress(per.identifier.uuidString);
        self.lib.openDevice();
        self.setText(text: "Connecting...")
        // super.connect()
    }
    
    @objc func dismissNav() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func scanForBLE()
    {
        let list = BLEScannerList(style: .plain, lib: lib);
        list.delegate = self;
        
        let nav = UINavigationController(rootViewController: list)
        nav.navigationBar.isTranslucent = false
       // nav.modalPresentationStyle = .fullScreen
        self.present(nav, animated: true, completion: nil)
    }
    
    
    @objc func connectDevices()
    {
        if(self.lib.isDeviceOpened())
        {
            self.lib.clearBuffers();
            self.lib.closeDevice();
            return;
        }
        
        let alert = UIAlertController(title: "Payment Device Type", message: "Which device are you connecting to", preferredStyle: .alert)
        
        let eDynamo = UIAlertAction(title: "eDynamo", style: .default, handler: { action in
            DispatchQueue.main.async(execute: {
                self.lib.setDeviceType(UInt32(MAGTEKEDYNAMO))
                self.scanForBLE()
            })
            
        })
        let tDynamo = UIAlertAction(title: "tDynamo", style: .default, handler: { action in
            DispatchQueue.main.async(execute: {
                self.lib.setDeviceType(UInt32(MAGTEKTDYNAMO))
                self.scanForBLE()
            })
        })
        
        let kDynamo = UIAlertAction(title: "kDynamo", style: .default, handler: { action in
            DispatchQueue.main.async(execute: {
                self.lib.setDeviceType(UInt32(MAGTEKKDYNAMO));
                self.lib.setDeviceProtocolString("com.magtek.idynamo")
                self.lib.openDevice()
            })
        })
        
        
        let btnCancel = UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
            
        })
        alert.addAction(eDynamo)
        alert.addAction(tDynamo)
        alert.addAction(kDynamo)
        alert.addAction(btnCancel)
        present(alert, animated: true)

    }
    
    
    @IBAction func connectClicked(_ sender: Any) {
        DispatchQueue.main.async {
           if(PaymentSettings.shared.paymentDeviceId() == 3) {
               print(BBDeviceController.shared()?.getState() as Any)
               print(BBDeviceController.shared()?.getConnectionMode() as Any)
              if BBDeviceController.shared()?.getConnectionMode() == BBDeviceConnectionMode.bluetooth ,BBDeviceController.shared()?.getState() == BBDeviceControllerState.idle {
                self.startBbPosEMV()
                self.startLocationFetching()
                self.connectBtn.setTitle("CONNECTED", for: .normal)
                   self.designPleaseSwipeView()
               } else {
                self.showPopUpToSetupCardReader()
               }
             } else if self.lib.isDeviceOpened() {
                self.startLocationFetching()
                self.connectBtn.setTitle("CONNECTED", for: .normal)
                self.designPleaseSwipeView()
                self.startEMV()
            } else {
                 self.connectDevices()
               // self.showPopUpToSetupCardReader()
            }
        }
    }
    
    func deviceSelected() {
        self.connectClicked((Any).self)
    }
    
    func onDeviceConnectionDidChange(_ deviceType: UInt, connected: Bool, instance: Any?) {
       // super.onDeviceConnectionDidChange(deviceType, connected: connected, instance: instance)
     //   {
           
                

                if((instance as! MTSCRA).isDeviceOpened() && self.lib.isDeviceConnected())
                {
                    
                    if(connected)
                    {
                        if self.lib.isDeviceConnected() && self.lib.isDeviceOpened()
                        {
                            
                            let opsQue = OperationQueue()
                            let op1 = Operation()
                            let op2 = Operation()
                            let op3 = Operation()
                            let op4 = Operation()


                            if deviceType == MAGTEKDYNAMAX || deviceType == MAGTEKEDYNAMO || deviceType == MAGTEKTDYNAMO {
                                if let name = (instance as? MTSCRA)?.getConnectedPeripheral().name {
                                    self.setText(text:"Connected to \(name)")
                                }


                                if !self.devicePaired! {
                                    return
                                }

                                if deviceType == MAGTEKDYNAMAX || deviceType == MAGTEKEDYNAMO || deviceType == MAGTEKTDYNAMO {
                                    self.setText(text:"Setting data output to Bluetooth LE...")

                                    op1.completionBlock = {
                                        //sn = self.sendCommandSync("000103")!
                                        self.sendCommand(withCallBack: "480101", completion: { (response) in
                                            self.setText(text: "[Output Result]\r\(response!)")
                                            opsQue.addOperation(op2)

                                        })

                                        // self.setText(text: "[Device SN]\n\(sn)")
                                    }

                                    //
                                    //                            let bleOutput = self.sendCommandSync("480101")
                                    //                           self.setText(text:"[Output Result]\r\(bleOutput)")
                                } else if deviceType == MAGTEKDYNAMAX {
                                    op1.completionBlock = {
                                        self.sendCommand(withCallBack: "000101", completion: { (response) in
                                            self.setText(text: "[Output Result]\r\(response!)")
                                            opsQue.addOperation(op2)

                                        })

                                    }

                                    //   self.lib.sendcommand(withLength: "000101")
                                }
                            } else {
                                op1.completionBlock = {

                                    self.setText(text:"Device Connected...") // @"Connected...";
                                    opsQue.addOperation(op2)

                                }
                            }

                            op2.completionBlock = {
                                self.setText(text: "Getting FW ID...")

                                if self.lib.getDeviceType() == MAGTEKAUDIOREADER {
                                    self.sendCommand(withCallBack: self.buildCommand(forAudioTLV: "000100"), completion: { (response) in
                                        self.setText(text: "[Firmware ID]\n\(response!)")
                                        opsQue.addOperation(op3)
                                    })
                                }
                                else
                                {
                                    self.sendCommand(withCallBack: "000100", completion: { (response) in
                                        self.setText(text: "[Firmware ID]\n\(response!)")
                                        opsQue.addOperation(op3)

                                    })
                                }

                            }

                            op3.completionBlock = {
                                //sn = self.sendCommandSync("000103")!
                                self.setText(text: "Getting SN...")
                                if self.lib.getDeviceType() == MAGTEKAUDIOREADER {
                                    self.sendCommand(withCallBack: self.buildCommand(forAudioTLV: "000103"), completion: { (response) in
                                        self.setText(text: "[Device SN]\n\(response!)")
                                        opsQue.addOperation(op4)

                                    })
                                }
                                else
                                {

                                    self.sendCommand(withCallBack: "000103", completion: { (response) in

                                        self.setText(text: "[Device SN]\n\(response!)")
                                        opsQue.addOperation(op4)

                                    })
                                }

                                // self.setText(text: "[Device SN]\n\(sn)")
                            }



                            op4.completionBlock = {
                                self.setText(text: "Getting Security Level...")

                                if self.lib.getDeviceType() == MAGTEKAUDIOREADER {
                                    self.sendCommand(withCallBack: self.buildCommand(forAudioTLV: "1500"), completion: { (response) in
                                        self.setText(text: "[Security Level]\n\(response!)")
                                    })
                                }
                                else
                                {
                                    self.sendCommand(withCallBack: "1500", completion: { (response) in
                                        self.setText(text: "[Security Level]\n\(response!)")
                                    })
                                }

                            }


                            opsQue.addOperation(op1)//*/
                            
                            if deviceType == MAGTEKTDYNAMO || deviceType == MAGTEKKDYNAMO
                            {
                               // self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "MSR On", style: .plain, target: self, action: #selector(self.turnMSROn))
                                self.setText(text: "Setting Date Time...")
                                self.setDateTime()
                            }
                            
                            if deviceType == MAGTEKTDYNAMO
                            {
                               // self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "MSR On", style: .plain, target: self, action: #selector(self.turnMSROn))
                            }
                            
                            self.startLocationFetching()
                            self.connectBtn.setTitle("CONNECTED", for: .normal)
                            self.designPleaseSwipeView()
                            self.perform(#selector(startEMV), with: nil, afterDelay: 3)
                        }
                    }
                    else
                    {
                        self.devicePaired = true
                        self.setText(text: "Disconnected")
                        PaymentSettings.shared.setPaymentDevice(id: 0)
                        self.removeDisplayedBrandImage()
                        self.connectBtn.setTitle("CONNECT", for: .normal)
                        self.creditcardSwipeLbl.text = "Credit Card Swipe/Insert"
                        if(self.plsSwipeView != nil) {
                        self.plsSwipeView.removeFromSuperview()
                        }
        //                self.btnConnect?.setTitle("Connect", for:UIControl.State())
        //                self.btnConnect?.backgroundColor = UIColor(hex:0x3465AA);
                    }
                }
                else
                {
                    self.devicePaired = true
                    self.setText(text: "Disconnected")
                    PaymentSettings.shared.setPaymentDevice(id: 0)
                    self.removeDisplayedBrandImage()
                    self.connectBtn.setTitle("CONNECT", for: .normal)
                    self.creditcardSwipeLbl.text = "Credit Card Swipe/Insert"
                    if(self.plsSwipeView != nil) {
                    self.plsSwipeView.removeFromSuperview()
                    }
                    
        //            self.btnConnect?.setTitle("Connect", for:UIControl.State())
        //            self.btnConnect?.backgroundColor = UIColor(hex:0x3465AA);
                    
                    if deviceType == MAGTEKTDYNAMO
                    {
                       // self.navigationItem.leftBarButtonItem = nil
                    }
                }
        //    }
        
    }
    
    func sendCommand(withCallBack command: String?, completion: @escaping (String?) -> Void)  {
        
        if completion != nil {
            
            cmdCompletion = completion
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.lib.sendcommand(withLength: command)
        }

        //}
    }
    
    
    func buildCommand(forAudioTLV commandIn: String?) -> String? {
           
           let commandSize = String(format: "%02x", UInt(commandIn?.count ?? 0) / 2)
           let newCommand = "8402\(commandSize)\(commandIn ?? "")"
           
           let fullLength = String(format: "%02x", UInt(newCommand.count) / 2)
           let tlvCommand = "C102\(fullLength)\(newCommand)"
           
           return tlvCommand
           
       }
    
    public func setText(text:String)
    {
        DispatchQueue.main.async {
            print("\(text)")
            //self.txtData!.text = self.txtData!.text + "\r\(text)"
           // self.scrollTextView(toBottom: self.txtData)
        }
    }
    
    func deviceNotPaired() {
        self.devicePaired = false
        self.setText(text: "Device is not paired")
        lib.closeDevice()
        displayAlert(title: "Device is not paired/connected", message: "Please press push button for 2 seconds to pair")
    }
    
    func setDateTime() {
        
        let date = Date()
        
        let calendar = Calendar.current
        let year = calendar.component(.year, from:date)-2008
        let month = calendar.component(.month, from:date)
        let day = calendar.component(.day, from:date)
        let hour = calendar.component(.hour, from:date)
        let minute = calendar.component(.minute, from:date)
        let second = calendar.component(.second, from:date)
        
        
        let cmd = "030C"
        let  size = "0018"
        let  deviceSn = "00000000000000000000000000000000"
        let strMonth = String(format: "%02lX", month)
        let strDay = String(format: "%02lX", day)
        let strHour = String(format: "%02lX", hour)
        let strMinute = String(format: "%02lX", minute)
        let strSecond = String(format: "%02lX", second)
        // NSString* placeHol = [NSString stringWithFormat:@"%02lX", (long)second];
        let strYear = String(format: "%02lX", year)
        let commandToSend = "\(cmd)\(size)00\(deviceSn)\(strMonth)\(strDay)\(strHour)\(strMinute)\(strSecond)00\(strYear)"
        lib.sendExtendedCommand(commandToSend)
    }

    
    
    func onDataReceived(_ cardDataObj: MTCardData!, instance: Any!) {
        DispatchQueue.main.async {
            AudioServicesPlaySystemSound(1200);
            self.cardInfo.updateValue("", forKey: "number")
            self.cardInfo.updateValue("", forKey: "expiration_date")
            self.cardInfo.updateValue("", forKey: "code")
            self.cardInfo.updateValue("", forKey: "type")
            if(cardDataObj.encryptedTrack1.count > 10) {
                self.cardInfo.updateValue(cardDataObj.encryptedTrack1! as Any, forKey: "track_data")
            } else if(cardDataObj.encryptedTrack2.count > 10) {
                self.cardInfo.updateValue(cardDataObj.encryptedTrack2! as Any, forKey: "track_data")
            } else if(cardDataObj.encryptedTrack3.count > 10) {
                self.cardInfo.updateValue(cardDataObj.encryptedTrack3! as Any, forKey: "track_data")
            } else {
                self.displayAlert(title: "Sorry!", message: "Please swipe/insert the card properly")
                return
            }
            
            if let firstFour = cardDataObj.cardPAN {
                switch CardState(fromPrefix: firstFour) {
                case .identified(let card):
                    print("\(card)")
                    self.setDisplayBrandImage(cardState: .identified(card))
                    break
                    //do something with card
                    
                case .indeterminate(let possibleCards):
                    print("\(possibleCards)")
                    self.setDisplayBrandImage(cardState: .indeterminate(possibleCards))
                    break
                    //do something with possibleCards
                    
                case .invalid:
                    print("invalid")
                    break
                    //show some validation error
                }
            }
            
            self.cardInfo.updateValue(cardDataObj.deviceKSN! as Any, forKey: "ksn")
            self.connectBtn.setTitle("************\(cardDataObj.cardLast4!)", for: .normal)
            self.confirmBtn.isEnabled = true
            self.creditcardSwipeLbl.text = "Credit Card Swipe/Insert"
            self.emv = nil
            if(self.plsSwipeView != nil) {
            self.plsSwipeView.removeFromSuperview()
            }
            self.confirmBtn.alpha = 1.0
        }
    }

    
    //EMV delegate

    
     func onDeviceExtendedResponse(_ data: String!) {
        print("onDeviceExtendedResponse:\(data!)")
    }
   
    
    func getUserFriendlyLanguage(_ codeIn: String) -> String
    {
        let lanCode:NSDictionary = ["EN": "English","DE": "Deutsch","FR": "Français","ES": "Español","ZH": "中文","IT": "Italiano"];
        
        return lanCode.object(forKey: codeIn.uppercased()) as! String;
    }
    
     func onDisplayMessageRequest(_ data: Data!) {
        if(data != nil)
        {
            let dataString = data.hexadecimalString
            
            DispatchQueue.main.async
                {
                    print("\n[Display Message Request]\n" +  (dataString as String).stringFromHexString);
                    self.creditcardSwipeLbl.text = "Credit Card Swipe/Insert"
                    if(self.plsSwipeView != nil) {
                     self.plsSwipeView.removeFromSuperview()
                    }
                    self.connectBtn.isEnabled = false
                    self.connectBtn.setTitle((dataString as String).stringFromHexString, for: .normal)
            }
        }
    }
     func onEMVCommandResult(_ data: Data!) {

        let dataString = data.hexadecimalString;
        DispatchQueue.main.async{
            print("[EMV Command Result]\n\(dataString)");
             // self.setText(text:"[EMV Command Result]\n\(dataString)");
        }
    }
   
     func onUserSelectionRequest(_ data: Data!) {

        let dataString = data.hexadecimalString;
        DispatchQueue.main.async{
            
            print("\n[User Selection Request]\n\(dataString) ");

            // self.setText(text:  "\n[User Selection Request]\n\(dataString) ");
            var dataType = [UInt8](repeating: 0, count: 1);
            //(data.subdata(in: NSMakeRange(0, 1)) as NSData).getBytes(&dataType, length: 1);
            dataType = data.subdata(in: 0 ..< 1).toArray(type: UInt8.self)
            
            var timeOut:NSInteger = 0;
            //(data.subdata(in: NSMakeRange(1, 1)) as NSData).getBytes(&timeOut, length:1);
            (data.subdata(in:  1 ..< 2) as NSData).getBytes(&timeOut, length: MemoryLayout<Int>.size)
            var dataSTr = data.subdata(in: 2 ..< data.count - 1).hexadecimalString;
            let menuItems:[String] = data.subdata(in: 2 ..< data.count - 1).hexadecimalString.components(separatedBy: "00");//.components(separatedBy: "00");
            
            
            
            self.userSelection = UIActionSheet();
            self.userSelection?.title = (menuItems[0] ).stringFromHexString;
            self.userSelection?.delegate = self;
            
            for i in 1 ..< menuItems.count
            {
                if((dataType[0] & 0x01) == 1)
                {
                    self.userSelection?.addButton(withTitle: self.getUserFriendlyLanguage((menuItems[i] ).stringFromHexString));
                    
                }
                else
                {
                    self.userSelection?.addButton(withTitle: (menuItems[i] ).stringFromHexString);
                    
                }
            }
            
            self.userSelection?.destructiveButtonIndex = (self.userSelection?.addButton(withTitle: "Cancel"))!;
            self.userSelection?.show(in: self.view);
            if(timeOut > 0 )
            {
                self.tmrTimeout = Timer.scheduledTimer(timeInterval: Double(timeOut), target: self, selector: #selector(self.selectionTimedOut), userInfo: nil, repeats: false);
                
            }
            
        }
    }
    
    
    @objc func selectionTimedOut()
    {
        userSelection?.dismiss(withClickedButtonIndex: (userSelection?.destructiveButtonIndex)!, animated: true);
        self.lib.setUserSelectionResult(0x02, selection: UInt8((userSelection?.destructiveButtonIndex)! ));
        UIAlertView(title: "Transaction Timed Out", message: "User took too long to enter a selection, trasnaction has been canceled", delegate: nil, cancelButtonTitle: "Done").show();
        
    }
    
     func onTransactionStatus(_ data: Data!) {
        let dataString = data.hexadecimalString;
        DispatchQueue.main.async{
            
            print("\n[Transaction Status]\n\(dataString)");

           // self.txtData?.text = self.txtData!.text + "\n[Transaction Status]\n\(dataString)";
            
        }
    }

     func onDeviceResponse(_ data: Data!) {
        //super.onDeviceResponse(data)
        
        if(cmdCompletion != nil)
        {
            let dataStr = HexUtil.toHex(data)
           // DispatchQueue.main.asyncAfter(deadline: .now()+0.2) {
            DispatchQueue.main.async {
                self.cmdCompletion!(dataStr)
                self.cmdCompletion = nil
            }
                
           // }

           return;
        }
        
        let dataString = data.hexadecimalString
        print("\n[Command Result]\n\(dataString)")
       // self.setText(text: "\n[Command Result]\n\(dataString)")
    }
    
     func onARQCReceived(_ data: Data!) {
        let dataString = data.hexadecimalString;
           let emvBytes  = HexUtil.getBytesFromHexString(dataString)
        let tlv = (emvBytes)!.parseTLVData();
        
        DispatchQueue.main.async{
            print("\n[ARQC Received]\n\(dataString)")

          //  self.txtData!.text = self.txtData!.text + "\n[ARQC Received]\n\(dataString)"
            
            if tlv != nil {
                
//                if (self.opt?.isQuickChip())!
//                {
//                    self.setText(text: "\n[Quick Chip]\r\nNot sending response\n")
//                    return
//                }
                
                var snStr = ""
                if let tempTLVObj = tlv?["DFDF25"] as? MTTLV
                {
                    snStr = tempTLVObj.value
                    print("\nSN String = \(snStr.stringFromHexString)")

                   // self.setText(text: "\nSN String = \(snStr.stringFromHexString)")
                }
                
                var dfdf55Str = ""
                if let tempTLVObj = tlv?["DFDF55"] as? MTTLV
                {
                    dfdf55Str = tempTLVObj.value
                }
                
                var dfdf54Str = ""
                if let tempTLVObj = tlv?["DFDF54"] as? MTTLV
                {
                    dfdf54Str = tempTLVObj.value
                }

                
                var response : Data
                if self.arqcFormat == self.ARQC_EDYNAMO_FORMAT
                {

                    response = self.buildAcquirerResponse(HexUtil.getBytesFromHexString(snStr)! as Data, encryptionType: Data(), ksn: Data(), approved: true)
                }
                else
                {
                    response = self.buildAcquirerResponse(HexUtil.getBytesFromHexString(snStr)! as Data,  encryptionType: HexUtil.getBytesFromHexString(dfdf55Str)! as Data, ksn:HexUtil.getBytesFromHexString(dfdf54Str)! as Data, approved: true )
                    
                }
                print("\n[Send Respond]\n\(response.hexadecimalString)")

               // self.setText(text: "\n[Send Respond]\n\(response.hexadecimalString)")
                self.lib.setAcquirerResponse(UnsafeMutablePointer<UInt8> (mutating: (response as NSData).bytes.bindMemory(to: UInt8.self, capacity: response.count)), length: Int32( response.count))
  
            }
            
        }
        
    }
    
    
    func buildAcquirerResponse(_ deviceSN: Data,  encryptionType: Data,ksn: Data, approved: Bool) ->Data
    {
        let response  = NSMutableData();
        var lenSN = 0;
        if (deviceSN.count > 0)
        {
            lenSN = deviceSN.count;
            
        }
//
        let snTagByte:[UInt8] = [0xDF, 0xdf, 0x25, UInt8(lenSN)];
        let snTag = Data(fromArray: snTagByte)
        
        var encryptLen:UInt8 = 0;
        _ = Data(bytes: &encryptLen, count: MemoryLayout.size(ofValue: encryptionType.count))
        
        let encryptionTypeTagByte:[UInt8] = [0xDF, 0xDF, 0x55, 0x01];
        let encryptionTypeTag =  Data(fromArray: encryptionTypeTagByte)
        
        var ksnLen:UInt8 = 0;
        _ = Data(bytes: &ksnLen, count: MemoryLayout.size(ofValue: encryptionType.count))
        let ksnTagByte:[UInt8] = [0xDF, 0xDF, 0x54, 0x0a];
        let ksnTag = Data(fromArray: ksnTagByte)

        let containerByte:[UInt8] = [0xFA, 0x06, 0x70, 0x04];
        let container = Data(fromArray: containerByte)
        

        
        
        
        let approvedARCByte:[UInt8] = [0x8A, 0x02, 0x30,0x30];
        let approvedARC = Data(fromArray: approvedARCByte)
//
        let declinedARCByte:[UInt8] = [0x8A, 0x02, 0x30,0x35];
        let declinedARC = Data(fromArray: declinedARCByte)
        
        let macPadding:[UInt8] = [0x00, 0x00,0x00,0x00,0x00,0x00,0x01,0x23, 0x45, 0x67];

        var len = 2 + snTag.count + lenSN + container.count + approvedARC.count ;
        if(arqcFormat == ARQC_DYNAPRO_FORMAT)
        {
        len += encryptionTypeTag.count + encryptionType.count + ksnTag.count + ksn.count;
        }
        
        var len1 = (UInt8)((len >> 8) & 0xff);
        var len2 = (UInt8)(len & 0xff);
        
        var tempByte = 0xf9;
        response.append(&len1, length: 1)
        response.append(&len2, length: 1)
        response.append(&tempByte, length: 1)
        tempByte = (len - 2)
        if(arqcFormat == ARQC_DYNAPRO_FORMAT)
        {
            tempByte = encryptionTypeTag.count + encryptionType.count + ksnTag.count + ksn.count +  snTag.count + lenSN + container.count + approvedARC.count;

        }
        response.append(&tempByte, length: 1)
        if(arqcFormat == ARQC_DYNAPRO_FORMAT)
        {
            response.append(ksnTag);
            response.append(ksn);
            response.append(encryptionTypeTag);
            response.append(encryptionType);
        }

        response.append(snTag);
        response.append(deviceSN);
        response.append(container);
        if(approved)
        {
            response.append(approvedARC);
        }
        else{
            response.append(declinedARC);
            
        }
        
        if(arqcFormat == ARQC_DYNAPRO_FORMAT)
        {
        response.append(Data(fromArray: macPadding))
        }
        
        return response as Data;

    }
    
 
    
    
    func actionSheet(_ actionSheet: UIActionSheet, clickedButtonAt buttonIndex: Int) {
        if((tmrTimeout) != nil)
        {
            tmrTimeout?.invalidate();
            tmrTimeout = nil;
        }
        
        if(buttonIndex == actionSheet.destructiveButtonIndex)
        {
            self.lib.setUserSelectionResult(0x01, selection: 0x00);
            return;
        }
        
        self.lib.setUserSelectionResult(0x00, selection: UInt8(buttonIndex));
            
    }

     func onTransactionResult(_ data: Data!) {
        let tempDataObj : NSData = (data as NSData)

        let dataString = data.hexadecimalString;
        DispatchQueue.main.async{
            print("\n[Transaction Result]\n\(dataString)")
           // self.setText(text: "\n[Transaction Result]\n\(dataString)");
            let dataString = tempDataObj.subdata(with: NSRange(location: 1, length: data.count-1)).hexadecimalString

            let emvBytes = HexUtil.getBytesFromHexString(dataString as String);
            let tlv = (emvBytes! as NSData).parseTLVData();
            let dataDump = tlv?.dumpTags();
            
            var pos_entry_mode = ""
            var service_code = ""
            if let pos = tlv?["9F39"] {
                pos_entry_mode = (pos as! MTTLV).value
            }
            if let service = tlv?["5F30"] {
                service_code = (service as! MTTLV).value
            }
            
            print("pos_entry_mode:\(pos_entry_mode) and service_code:\(service_code)")
            
            self.emv = Dictionary<String, Any>()
            self.emv?.updateValue(dataString, forKey: "emv_data")
            self.emv?.updateValue(pos_entry_mode, forKey: "pos_entry_mode")
            self.emv?.updateValue(service_code, forKey: "service_code")

            self.confirmBtn.isEnabled = true
            self.confirmBtn.alpha = 1.0
            
            if(self.arqcFormat == self.ARQC_EDYNAMO_FORMAT)
            {
                let responseTag = HexUtil.getBytesFromHexString((tlv!["DFDF1A"] as! MTTLV).value)
                print("\n[Parsed Transaction Result]\n \(dataDump!)")
               // self.setText(text: "\n[Parsed Transaction Result]\n \(dataDump!)")
               let sigReq : NSData = tempDataObj.subdata(with: NSRange(location: 0, length: 1)) as NSData
                
                if(sigReq[0] == 0x01 && (responseTag![0] == 0x00))
                {
                   // UIAlertView(title: "Signature", message: "Signature required, please sign.", delegate: self, cancelButtonTitle: "Ok").show()
//                    let sig = eDynamoSignature()
//                    self.navigationController?.pushViewController(sig, animated: true)

                }
           }
        }
    }
    
    func led(on: Int, completion: @escaping cmdCompBlock) -> Int {
        let rs = self.lib.sendcommand(withLength: String(format: "4D010%i", on))
        if rs == 0 {
            cmdCompletion = completion
        }
        //0 - sent successful
        //15 - device is busy
        return Int(rs)
    }

    
    func onDeviceError(_ error: Error!) {
        print(error.localizedDescription)
      //  self.txtData!.text = self.txtData!.text + "\n" + error.localizedDescription
    }
    
    func bleReaderStateUpdated(_ state: MTSCRABLEState) {
        print(state)
        if state == UNSUPPORTED
        {
            UIAlertView(title: "Bluetooth LE Error", message: "Bluetooth LE is unsupported on this device", delegate: nil, cancelButtonTitle: "OK").show()

        }
    }
        
    
    //--------------------
    
    
    @IBAction func cardSwipeSelected(_ sender: Any) {
        
        let topImage = modeView.viewWithTag(100) as? UIImageView
        let bottomImage = modeView.viewWithTag(101) as? UIImageView

        UIView.transition(with: paymentModeView, duration: 0.4, options: UIView.AnimationOptions.curveEaseOut, animations: {
            
            if(self.cardSwipeViewHeight.constant == 60) {
                self.cardSwipeViewHeight.constant = 120
                self.cardSwipeView.frame.size.height = 120
                self.manualEntryViewHeight.constant = 60
                self.manualEntryView.frame.size.height = 60
                self.modeViewHeight.constant = 200
                self.optionalFieldsViewHeight.constant = 37
                self.optionalFieldsTableView.frame.size.height = 37
                bottomImage?.image = UIImage(named: "uparrow")
                topImage?.image = UIImage(named: "downarrow")

            } else {
                self.cardSwipeViewHeight.constant = 60
                self.cardSwipeView.frame.size.height = 60
                self.modeViewHeight.constant = 140
                self.optionalFieldsViewHeight.constant = 97
                self.optionalFieldsTableView.frame.size.height = 97
                bottomImage?.image = UIImage(named: "downarrow")
            }
            
        }, completion: nil)
        
    }
    
    @IBAction func manualEntryClicked(_ sender: Any) {
       
        let topImage = modeView.viewWithTag(100) as? UIImageView
        let bottomImage = modeView.viewWithTag(101) as? UIImageView
        
        UIView.transition(with: paymentModeView, duration: 0.4, options: UIView.AnimationOptions.curveEaseOut, animations: {
            
            if(self.manualEntryViewHeight.constant == 60) {
                self.manualEntryViewHeight.constant = 120
                self.manualEntryView.frame.size.height = 120
                self.cardSwipeViewHeight.constant = 60
                self.cardSwipeView.frame.size.height = 60
                self.modeViewHeight.constant = 200
                self.optionalFieldsViewHeight.constant = 37
                self.optionalFieldsTableView.frame.size.height = 37

                bottomImage?.image = UIImage(named: "downarrow")
                topImage?.image = UIImage(named: "uparrow")
                
            } else {
                self.manualEntryViewHeight.constant = 60
                self.manualEntryView.frame.size.height = 60
                self.modeViewHeight.constant = 140
                self.optionalFieldsViewHeight.constant = 97
                self.optionalFieldsTableView.frame.size.height = 97
                topImage?.image = UIImage(named: "downarrow")
            }
            
        }, completion: nil)
        
        self.paymentTextField.frame = CGRect(x: 16, y: 61, width: self.manualEntryView.frame.width-32, height: 50)
//        self.plsSwipeView.removeFromSuperview()
//        self.creditcardSwipeLbl.text = "Credit Card Swipe"
    }
    
    func pullUpPaymentModeView() {

        let screenHeight = self.view.frame.height
        self.paymentModeView.amountLbl.text = "$\(payment.amount!)"
        self.connectBtn.isEnabled = true
        self.grayBgView.isHidden = false
        self.paymentModeView.frame.origin.y = screenHeight
        
        UIView.transition(with: paymentModeView, duration: 0.4, options: UIView.AnimationOptions.curveEaseOut, animations: {
            self.paymentModeView.alpha = 1.0
            self.paymentModeView.frame.origin.y = 190
        }, completion: nil)
        
    }
    
    func pullUpPaymentModeViewToTop() {
    
        let topImage = paymentModeView.viewWithTag(1000) as? UIImageView

        let screenHeight = self.view.frame.height
        let bottomSpace = self.modeView.frame.origin.y+140
        modeViewUpdatedHeight = self.modeViewHeight.constant
 
        UIView.transition(with: paymentModeView, duration: 0.4, options: UIView.AnimationOptions.curveEaseOut, animations: {
            self.pvIsUp = true
            self.paymentModeView.frame.origin.y = 20
            self.paymentModeView.frame.size.height = screenHeight
            self.modeViewHeight.constant = 0
            self.modeView.frame.size.height = 0
            
            topImage?.image = UIImage(named: "ArrowDOWN")
            
            self.optionalFieldsViewHeight.constant = screenHeight-bottomSpace
            self.optionalFieldsTableView.frame.size.height = screenHeight-bottomSpace
            self.optionalFieldsTableView.alpha = 1
            self.instructionLbl.text = "Swipe down for payment entry"

        }, completion: nil)
        
    }
    
    
    func pullDownPaymentModeView() {
        
        let screenHeight = self.view.frame.height

        UIView.transition(with: paymentModeView, duration: 0.4, options: UIView.AnimationOptions.curveEaseOut, animations: {
            if(self.pvIsUp) {
                
                self.paymentModeView.frame.origin.y = 190
              //  self.paymentModeView.frame.size.height = CGFloat(actualViewHeight)
                self.modeViewHeight.constant = self.modeViewUpdatedHeight
                self.modeView.frame.size.height = self.modeViewUpdatedHeight
                self.optionalFieldsViewHeight.constant =  self.modeViewUpdatedHeight == 140 ? 97 : 37
                self.optionalFieldsTableView.frame.size.height = self.modeViewUpdatedHeight == 140 ? 97 : 37
                self.optionalFieldsTableView.alpha = 0
                self.instructionLbl.text = "Connect a reader to swipe, insert or tap"
                self.pvIsUp = false
                
                let topImage = self.paymentModeView.viewWithTag(1000) as? UIImageView
                topImage?.image = UIImage(named: "ArrowUP")

            } else {
                self.paymentModeView.alpha = 0.0
                self.paymentModeView.frame.origin.y = screenHeight
                self.grayBgView.isHidden = true
            }
           
        }, completion: nil)
        self.view.endEditing(true)
//        self.disconnectBbPos()
//        self.disconnect()
    }
    
    
    func addSwipe() {
        let directions: [UISwipeGestureRecognizer.Direction] = [.right, .left, .up, .down]
        for direction in directions {
            let gesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(sender:)))
            gesture.direction = direction
            self.view.addGestureRecognizer(gesture)
        }
    }
    
    @objc func handleSwipe(sender: UISwipeGestureRecognizer) {
        print(sender.direction)
        if(sender.direction == .down && self.paymentModeView.alpha == 1.0) {
            self.pullDownPaymentModeView()
        } else  if(sender.direction == .up && self.pvIsUp != true && self.paymentModeView.alpha == 1.0) {
            self.pullUpPaymentModeViewToTop()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        devicePaired = true

        self.lib = MTSCRA();
        self.lib.delegate = self;
        //self.lib.setDeviceType(UInt32(MAGTEKEDYNAMO));
        self.lib.setConnectionType(UInt(UInt32(BLE_EMV)))
        
        self.arqcFormat = UInt8("0")

        self.firstNameField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        self.lastNameField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        self.customerIdField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        self.invoiceNumberField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        self.notesField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        customerInfo = ["first_name":"Unknown", "last_name":"user", "street_1":"", "street_2":"", "city":"", "state":"", "zip":"", "country":"", "phone_number":"", "company":"", "customer_id":"", "invoice_number":"", "email":"", "email_receipt":"NO", "notes":""]
        
        pvIsUp = false
        modeViewUpdatedHeight = 140
        
        paymentTextField.delegate = self
        paymentTextField.font = UIFont.systemFont(ofSize: 17, weight: .light)
        self.manualEntryView.addSubview(paymentTextField)
        
        
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
        paymentTextField.inputAccessoryView = numberToolbar
        invoiceNumberField.inputAccessoryView = numberToolbar
        
        addSwipe()
        
        if(PaymentSettings.shared.selectedTerminalType() == "MOTO") {
            cardSwipeView.isHidden = true
        }
        
        // Do any additional setup after loading the view.
    }
    
    @objc func doneClicked () {
        paymentTextField.resignFirstResponder()
        self.view.endEditing(true)
    }
    
    func designPleaseSwipeView() {
        creditcardSwipeLbl.text = "Please Swipe or Insert The Card"
        DispatchQueue.main.async {
            self.plsSwipeView = UIView(frame: CGRect(x: 0, y: 60, width: self.cardSwipeView.frame.size.width, height: 60))
            self.plsSwipeView.backgroundColor = UIColor(named: "BgColor")
            
            let progresslineBg = UIView(frame: CGRect(x: 60, y: 0, width: self.cardSwipeView.frame.size.width-120, height: 10))
            progresslineBg.backgroundColor = UIColor(named: "blueTextColor")
            progresslineBg.alpha = 0.2
            progresslineBg.layer.cornerRadius = 5
            self.plsSwipeView.addSubview(progresslineBg)
            
            let progressline = UIView(frame: CGRect(x: 60, y: 0, width: 60, height: 10))
            progressline.backgroundColor = UIColor(named: "blueTextColor")
            progressline.layer.cornerRadius = 5
            self.plsSwipeView.addSubview(progressline)
            
            self.cardSwipeView.addSubview(self.plsSwipeView)
            
            UIView.animate(withDuration: 1.0, delay: 0.0,
                           options: [.repeat, .autoreverse, .curveEaseInOut],
                           animations: {
                            progressline.layer.position.x += progresslineBg.frame.width-60
            }, completion: nil)
        }
    }
    
    func startLocationFetching() {
        locationManager = CLLocationManager()
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
    }
    
    func stopLocationFetching() {
        if(locationManager != nil) {
            locationManager.stopUpdatingLocation()
            locationManager = nil
        }
    }
    
//    override func viewDidAppear(_ animated: Bool) {
//        navigationController?.navigationBar.barStyle = .black
//    }
    
//    override var preferredStatusBarStyle: UIStatusBarStyle {
//        return .lightContent
//    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.lib.closeDevice()
        if (self.isMovingFromParent) {
            UIDevice.current.setValue(Int(UIInterfaceOrientation.portrait.rawValue), forKey: "orientation")
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    
    @objc func canRotate() -> Void {}
    
    
//    func connectBbPos() {
//        BBDeviceController.shared()?.delegate = self
//        BBDeviceController.shared()?.isDebugLogEnabled = true
//        BBDeviceController.shared()?.startBTScan(nil, scanTimeout: 120)
//    }
//
//    func disconnectBbPos() {
//        BBDeviceController.shared()?.disconnectBT()
//        BBDeviceController.shared()?.release()
//        BBDeviceController.shared()?.delegate = nil
//    }
//
//    func onBTReturnScanResults(_ devices: [Any]!) {
//        let foundDevice = devices[0] as? CBPeripheral
//        print(foundDevice as Any)
//        BBDeviceController.shared()?.stopBTScan()
//        BBDeviceController.shared()?.connectBT(foundDevice)
//    }

    func startBbPosEMV() {
        
        let inputData = NSMutableDictionary()
        
        let formatter = DateFormatter()
        formatter.dateFormat = "YYMMddHHmmss"
        formatter.timeZone = NSTimeZone.local
        inputData.setValue(formatter.string(from: Date()), forKey: "terminalTime")
        
        let one = NSNumber(value:BBDeviceCurrencyCharacter.U.rawValue)
        let two = NSNumber(value: BBDeviceCurrencyCharacter.S.rawValue)
        let three = NSNumber(value: BBDeviceCurrencyCharacter.D.rawValue)

        let currencyCharacter = [one, two, three]
        
        inputData.setValue(currencyCharacter, forKey: "currencyCharacters")
        inputData.setValue("840", forKey: "currencyCode")
        inputData.setValue(payment.amount, forKey: "amount")
        inputData.setValue(BBDeviceCheckCardMode.swipeOrInsertOrTap.rawValue, forKey: "checkCardMode")
        inputData.setValue(BBDeviceTransactionType.payment.rawValue, forKey: "transactionType")
        
        BBDeviceController.shared()?.delegate = self
        BBDeviceController.shared()?.startEmv(withData: inputData as? [AnyHashable : Any])
    }
    
    /*
    func getDisplayTextString(displayText:BBDeviceDisplayText) -> String {
        switch displayText {
            case BBDeviceDisplayText.APPROVED: return "APPROVED"
            case BBDeviceDisplayText.CALL_YOUR_BANK: return "CALL_YOUR_BANK"
            case BBDeviceDisplayText.DECLINED: return "DECLINED"
            case BBDeviceDisplayText.ENTER_AMOUNT: return "ENTER_AMOUNT"
            case BBDeviceDisplayText.ENTER_PIN: return "ENTER_PIN"
            case BBDeviceDisplayText.INCORRECT_PIN: return "INCORRECT_PIN"
            case BBDeviceDisplayText.INSERT_CARD: return "INSERT_CARD"
            case BBDeviceDisplayText.NOT_ACCEPTED: return "NOT_ACCEPTED"
            case BBDeviceDisplayText.PIN_OK: return "PIN_OK"
            case BBDeviceDisplayText.PLEASE_WAIT: return "PLEASE_WAIT"
            case BBDeviceDisplayText.REMOVE_CARD: return "REMOVE_CARD"
            case BBDeviceDisplayText.USE_MAG_STRIPE: return "USE_MAG_STRIPE"
            case BBDeviceDisplayText.TRY_AGAIN: return "TRY_AGAIN"
            case BBDeviceDisplayText.REFER_TO_YOUR_PAYMENT_DEVICE: return "REFER_TO_YOUR_PAYMENT_DEVICE"
            case BBDeviceDisplayText.TRANSACTION_TERMINATED: return "TRANSACTION_TERMINATED"
            case BBDeviceDisplayText.PROCESSING: return "PROCESSING"
            case BBDeviceDisplayText.LAST_PIN_TRY: return "LAST_PIN_TRY"
            case BBDeviceDisplayText.SELECT_ACCOUNT: return "SELECT_ACCOUNT"
            case BBDeviceDisplayText.PRESENT_CARD:return "PRESENT_CARD"
            case BBDeviceDisplayText.APPROVED_PLEASE_SIGN: return "APPROVED_PLEASE_SIGN"
            case BBDeviceDisplayText.PRESENT_CARD_AGAIN: return "PRESENT_CARD_AGAIN"
            case BBDeviceDisplayText.AUTHORISING: return "AUTHORISING"
            case BBDeviceDisplayText.INSERT_SWIPE_OR_TRY_ANOTHER_CARD: return "INSERT_SWIPE_OR_TRY_ANOTHER_CARD"
            case BBDeviceDisplayText.INSERT_OR_SWIPE_CARD: return "INSERT_OR_SWIPE_CARD"
            case BBDeviceDisplayText.MULTIPLE_CARDS_DETECTED: return "MULTIPLE_CARDS_DETECTED"
            case BBDeviceDisplayText.TIMEOUT: return "TIMEOUT"
            case BBDeviceDisplayText.APPLICATION_EXPIRED: return "APPLICATION_EXPIRED"
            case BBDeviceDisplayText.FINAL_CONFIRM: return "FINAL_CONFIRM"
            case BBDeviceDisplayText.SHOW_THANK_YOU: return "SHOW_THANK_YOU"
            case BBDeviceDisplayText.PIN_TRY_LIMIT_EXCEEDED: return "PIN_TRY_LIMIT_EXCEEDED"
            case BBDeviceDisplayText.NOT_ICC_CARD: return "NOT_ICC_CARD"
            case BBDeviceDisplayText.CARD_INSERTED: return "CARD_INSERTED"
            case BBDeviceDisplayText.CARD_REMOVED: return "CARD_REMOVED"
            case BBDeviceDisplayText.NO_EMV_APPS: return "NO_EMV_APPS"
            @unknown default:
            return "\(displayText.rawValue))"
        }
    }
    */
    
//    func onRequestStartEmv() {
//        <#code#>
//    }
    
//    - (void)onRequestTerminalTime;
//    - (void)onRequestSetAmount;
//    - (void)onRequestSelectApplication:(NSArray *)applicationArray;
//
//    // Confirm Amount on device with keypad after set amount
//    - (void)onReturnAmountConfirmResult:(BOOL)isConfirmed;
    
     func onBTConnected(_ connectedDevice: NSObject!) {
        print(connectedDevice as Any)
        startBbPosEMV()
        connectBtn.isSelected = true
    }
    
    func onBTDisconnected() {
        PaymentSettings.shared.setPaymentDevice(id: 0)
        connectBtn.setTitle("CONNECT", for: .normal)
    }
    
     func onWaiting(forCard checkCardMode: BBDeviceCheckCardMode) {
        print(checkCardMode)
//        if ([[BBDeviceController sharedController] getConnectionMode] == BBDeviceConnectionMode_None){
//            lblGeneralData.text = @"BBDeviceConnectionMode_None";
//            return;
//        }
    }
    
    func getDisplayTextString(displayText:BBDeviceDisplayText)-> String {
        switch displayText {
        case BBDeviceDisplayText.APPROVED: return "APPROVED"
        case BBDeviceDisplayText.CALL_YOUR_BANK: return "CALL_YOUR_BANK"
        case BBDeviceDisplayText.DECLINED: return "DECLINED"
        case BBDeviceDisplayText.ENTER_AMOUNT: return "ENTER_AMOUNT"
        case BBDeviceDisplayText.ENTER_PIN: return "ENTER_PIN"
        case BBDeviceDisplayText.INCORRECT_PIN: return "INCORRECT_PIN"
        case BBDeviceDisplayText.INSERT_CARD: return "INSERT_CARD"
        case BBDeviceDisplayText.NOT_ACCEPTED: return "NOT_ACCEPTED"
        case BBDeviceDisplayText.PIN_OK: return "PIN_OK"
        case BBDeviceDisplayText.PLEASE_WAIT: return "PLEASE_WAIT"
        case BBDeviceDisplayText.REMOVE_CARD: return "REMOVE_CARD"
        case BBDeviceDisplayText.USE_MAG_STRIPE: return "USE_MAG_STRIPE"
        case BBDeviceDisplayText.TRY_AGAIN: return "TRY_AGAIN"
        case BBDeviceDisplayText.REFER_TO_YOUR_PAYMENT_DEVICE: return "REFER_TO_YOUR_PAYMENT_DEVICE"
        case BBDeviceDisplayText.TRANSACTION_TERMINATED: return "TRANSACTION_TERMINATED"
        case BBDeviceDisplayText.PROCESSING: return "PROCESSING"
        case BBDeviceDisplayText.LAST_PIN_TRY: return "LAST_PIN_TRY"
        case BBDeviceDisplayText.SELECT_ACCOUNT: return "SELECT_ACCOUNT"
        case BBDeviceDisplayText.PRESENT_CARD: return "PRESENT_CARD"
        case BBDeviceDisplayText.APPROVED_PLEASE_SIGN: return "APPROVED_PLEASE_SIGN"
        case BBDeviceDisplayText.PRESENT_CARD_AGAIN: return "PRESENT_CARD_AGAIN"
        case BBDeviceDisplayText.AUTHORISING: return "AUTHORISING"
        case BBDeviceDisplayText.INSERT_SWIPE_OR_TRY_ANOTHER_CARD: return "INSERT_SWIPE_OR_TRY_ANOTHER_CARD"
        case BBDeviceDisplayText.INSERT_OR_SWIPE_CARD: return "INSERT_OR_SWIPE_CARD"
        case BBDeviceDisplayText.MULTIPLE_CARDS_DETECTED: return "MULTIPLE_CARDS_DETECTED"
        case BBDeviceDisplayText.TIMEOUT: return "TIMEOUT"
        case BBDeviceDisplayText.APPLICATION_EXPIRED: return "APPLICATION_EXPIRED"
        case BBDeviceDisplayText.FINAL_CONFIRM: return "FINAL_CONFIRM"
        case BBDeviceDisplayText.SHOW_THANK_YOU: return "SHOW_THANK_YOU"
        case BBDeviceDisplayText.PIN_TRY_LIMIT_EXCEEDED: return "PIN_TRY_LIMIT_EXCEEDED"
        case BBDeviceDisplayText.NOT_ICC_CARD: return "NOT_ICC_CARD"
        case BBDeviceDisplayText.CARD_INSERTED: return "CARD_INSERTED"
        case BBDeviceDisplayText.CARD_REMOVED: return "CARD_REMOVED"
        case BBDeviceDisplayText.NO_EMV_APPS: return "NO_EMV_APPS"
        @unknown default:
            return ("\(displayText.rawValue)")
        }
        
    }
    func getTransactionResultString(transactionResult:BBDeviceTransactionResult) -> String {
        var returnString = ""
        switch transactionResult {
        case BBDeviceTransactionResult.approved: returnString = "Approved"
        case BBDeviceTransactionResult.terminated: returnString = "Terminated"
        case BBDeviceTransactionResult.declined: returnString = "Declined"
        case BBDeviceTransactionResult.canceledOrTimeout: returnString = "CanceledOrTimeout"
        case BBDeviceTransactionResult.capkFail: returnString = "CapkFail"
        case BBDeviceTransactionResult.notIcc: returnString = "NotIcc"
        case BBDeviceTransactionResult.cardBlocked: returnString = "CardBlocked"
        case BBDeviceTransactionResult.deviceError: returnString = "DeviceError"
        case BBDeviceTransactionResult.cardNotSupported: returnString = "CardNotSupported"
        case BBDeviceTransactionResult.selectApplicationFail: returnString = "SelectApplicationFail"
        case BBDeviceTransactionResult.missingMandatoryData: returnString = "MissingMandatoryData"
        case BBDeviceTransactionResult.noEmvApps: returnString = "NoEmvApps"
        case BBDeviceTransactionResult.invalidIccData: returnString = "InvalidIccData"
        case BBDeviceTransactionResult.conditionsOfUseNotSatisfied: returnString = "ConditionsOfUseNotSatisfied"
        case BBDeviceTransactionResult.applicationBlocked: returnString = "ApplicationBlocked"
        case BBDeviceTransactionResult.iccCardRemoved: returnString = "IccCardRemoved"
        case BBDeviceTransactionResult.cardSchemeNotMatched: returnString = "CardSchemeNotMatched"
        case BBDeviceTransactionResult.canceled: returnString = "Canceled"
        case BBDeviceTransactionResult.timeout:
             returnString = "Timeout"
             self.connectBtn.setTitle("CONNECT", for: .normal)
             if(self.plsSwipeView != nil) {
             self.plsSwipeView.removeFromSuperview()
             }
             self.creditcardSwipeLbl.text = "Credit Card Swipe/Insert"
        default: returnString = "\(transactionResult.rawValue)"
        }
        return returnString;
    }
    
    func onReturn(_ result: BBDeviceTransactionResult) {
        let strDisplayMessage = self.getTransactionResultString(transactionResult: result)
        self.displayAlert(title:strDisplayMessage , message: "")
    }
    
     func onRequest(_ displayMessage: BBDeviceDisplayText) {
        print(displayMessage)
       //  let strDisplayMessage = self.getDisplayTextString(displayText: displayMessage)
       // self.displayAlert(title:strDisplayMessage , message: "")
    }
    
     func onReturn(_ result: BBDeviceCheckCardResult, cardData: [AnyHashable : Any]!) {
        print(cardData)
        DispatchQueue.main.async {
            AudioServicesPlaySystemSound(1200);
            self.cardInfo.updateValue("", forKey: "number")
            self.cardInfo.updateValue("", forKey: "expiration_date")
            self.cardInfo.updateValue("", forKey: "code")
            self.cardInfo.updateValue("", forKey: "type")
            if let track1 = cardData["encTrack1"] as? String, track1.count > 10 {
                self.cardInfo.updateValue(track1, forKey: "track_data")
            } else if let track2 = cardData["encTrack2"] as? String, track2.count > 10 {
                self.cardInfo.updateValue(track2, forKey: "track_data")
            } else if let track3 = cardData["encTrack3"] as? String, track3.count > 10 {
                self.cardInfo.updateValue(track3, forKey: "track_data")
            } else {
                self.displayAlert(title: "Sorry!", message: "Please swipe/insert the card properly")
                return
            }
            if let ksn = cardData["ksn"] as? String {
                self.cardInfo.updateValue(ksn, forKey: "ksn")
            }
            if let maskedPan = cardData["maskedPAN"] as? String {
                let lastFour = String(maskedPan.suffix(4))
                let firstFour = String(maskedPan.prefix(4))

                switch CardState(fromPrefix: firstFour) {
                    
                case .identified(let card):
                    print("\(card)")
                    self.setDisplayBrandImage(cardState: .identified(card))
                    break
                    //do something with card
                    
                case .indeterminate(let possibleCards):
                    print("\(possibleCards)")
                    self.setDisplayBrandImage(cardState: .indeterminate(possibleCards))
                    break
                    //do something with possibleCards
                    
                case .invalid:
                    print("invalid")
                    break
                    //show some validation error
                    
                }
                self.connectBtn.setTitle("************\(lastFour)", for: .normal)
            }
            
            self.confirmBtn.isEnabled = true
            if(self.plsSwipeView != nil) {
            self.plsSwipeView.removeFromSuperview()
            }
            self.creditcardSwipeLbl.text = "Credit Card Swipe or Insert"
            self.emv = nil
            self.confirmBtn.alpha = 1.0
            
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        paymentTextField.clear()
        
    }
    
    func removeDisplayedBrandImage() {
        if let imageView = cardSwipeView.viewWithTag(111) as? UIImageView {
            imageView.removeFromSuperview()
        }
    }
    
    func setDisplayBrandImage(cardState:CardState) {
        let imgView = UIImageView(frame: CGRect(x: connectBtn.frame.origin.x+20, y: connectBtn.frame.origin.y, width: 30, height: connectBtn.frame.height))
        imgView.contentMode = .scaleAspectFit
        imgView.tag = 111
        imgView.image = cardImage(forState: cardState)
        cardSwipeView.addSubview(imgView)
    }
    
    
    func cardImage(forState cardState:CardState) -> UIImage? {
        switch cardState {
        case .identified(let cardType):
            switch cardType{
            case .visa:
                return STPPaymentCardTextField.brandImage(for: .visa)
            case .masterCard:
                return STPPaymentCardTextField.brandImage(for: .mastercard)
            case .amex:
                return STPPaymentCardTextField.brandImage(for: .amex)
            case .diners:
                return STPPaymentCardTextField.brandImage(for: .dinersClub)
            case .discover:
                return STPPaymentCardTextField.brandImage(for: .discover)
            case .jcb:
                return STPPaymentCardTextField.brandImage(for: .JCB)
            }
        case .indeterminate:
            return STPPaymentCardTextField.brandImage(for: .unknown)
        case .invalid:
            return STPPaymentCardTextField.brandImage(for: .unknown)
        }
    }

    
    func paymentCardTextFieldDidChange(_ textField: STPPaymentCardTextField) {
        DispatchQueue.main.async {
            if(textField.isValid) {
                self.cardInfo.updateValue(textField.cardNumber!, forKey: "number")
                self.cardInfo.updateValue(NSString(format: "%02ld%02ld", textField.expirationMonth, textField.expirationYear) as String, forKey: "expiration_date")
                
                if textField.expirationMonth == 0 {
                    self.cardInfo.updateValue("", forKey: "expiration_date")
                }
                
                self.cardInfo.updateValue(textField.cvc ?? "", forKey: "code")
                
                self.cardInfo.updateValue("Amex", forKey: "type")
                self.cardInfo.updateValue("", forKey: "track_data")
                self.cardInfo.updateValue("", forKey: "ksn")
                self.confirmBtn.isEnabled = true
                self.confirmBtn.alpha = 1.0
                
            } else {
                print("need to give all")
                self.confirmBtn.isEnabled = false
                self.confirmBtn.alpha = 0.5
            }
        }
        
    }
    
    func paymentCardTextFieldDidEndEditing(_ textField: STPPaymentCardTextField) {
        self.view.endEditing(true)
    }
    
    @IBAction func menuPressed(_ sender: Any) {
        sideMenuController?.revealMenu()
    }

    @IBAction func clearClicked(_ sender: Any) {
        checkout = Checkout(amount: "0")
        checkout = nil
     //   DeviceSettings.shared.setTemp(Amount: nil)
    }
    
    @IBAction func backspaceClicked(_ sender: Any) {
        if let checkOut = checkout, var oldValue = checkOut.enteredAmount {
            oldValue.removeLast()
            if oldValue.isEmpty {
                checkout = Checkout(amount: "0")
                checkout = nil
             //   DeviceSettings.shared.setTemp(Amount: nil)
            } else {
                checkout = Checkout(amount: String(format: "%@", oldValue))
            }
        }
    }
    
    @IBAction func numberClicked(_ sender: Any) {
        let numberBtn = sender as! UIButton
        let pressedNumber = numberBtn.titleLabel!.text
        if(checkout == nil) {
            checkout = Checkout(amount: String(format: "%@", pressedNumber!))
        } else {
            let oldValue = checkout?.enteredAmount
            checkout = Checkout(amount: String(format: "%@%@",oldValue!,pressedNumber!))
        }
    }
    
    func adjustFieldsPositionWith(Top:CGFloat, textField:SkyFloatingLabelTextField) {
        switch textField {
        case firstNameField:
            fnTop.constant = Top
        case lastNameField:
            lnTop.constant = Top
        case customerIdField:
            cIdTop.constant = Top
        case invoiceNumberField:
            ivTop.constant = Top
        case notesField:
            noteTop.constant = Top
        default:
            fnTop.constant = Top
        }
    }
    
    @objc func textFieldDidChange(_ textfield: UITextField) {
        DispatchQueue.main.async {
            if let text = textfield.text {
                if let floatingLabelTextField = textfield as? SkyFloatingLabelTextField {
                    if(text.count == 0) {
                        self.adjustFieldsPositionWith(Top: 3, textField: floatingLabelTextField)
                    }
                    else {
                        self.adjustFieldsPositionWith(Top: 11, textField: floatingLabelTextField)
                    }
                }
            }
        }
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        let signVc = segue.destination as? SignatureViewController
        signVc?.reference_transaction_id = ref_tran_id
        checkout = Checkout(amount: "0")
        checkout = nil
    }
}


extension CheckoutViewController {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let location = locations.first else {
            return
        }
        
        self.geoCoder.reverseGeocodeLocation(location) { placemarks, _ in
            if let place = placemarks?.first {
                // let description = "\(place)"
                let geoLocStr = String(format: "%0.6f;%0.6f", place.location?.coordinate.latitude ?? "", place.location?.coordinate.longitude ?? "")
                Session.shared.setUser(Loc: geoLocStr)
                // self.newVisitReceived(visit, description: description)
            }
        }
    }
    
    /*
    func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
        // create CLLocation from the coordinates of CLVisit
        let clLocation = CLLocation(latitude: visit.coordinate.latitude, longitude: visit.coordinate.longitude)
        
        // Get location description
        self.geoCoder.reverseGeocodeLocation(clLocation) { placemarks, _ in
            if let place = placemarks?.first {
               // let description = "\(place)"
                let geoLocStr = String(format: "%0.6f;%0.6f", place.location?.coordinate.longitude ?? "", place.location?.coordinate.latitude ?? "")
                Session.shared.setUser(Loc: geoLocStr)
               // self.newVisitReceived(visit, description: description)
            }
        }
        
    }
 
    func newVisitReceived(_ visit: CLVisit, description: String) {
        // let location = Location(visit: visit, descriptionString: description)
        print(visit)
        // Save location to disk
    }
 */
}
