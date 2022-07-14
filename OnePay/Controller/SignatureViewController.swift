//
//  SignatureViewController.swift
//  OnePay
//
//  Created by Palani Krishnan on 5/24/19.
//  Copyright © 2019 Certify Global. All rights reserved.
//

import UIKit
import CoreLocation

class SignatureViewController: UIViewController,YPSignatureDelegate {
    @IBOutlet weak var amountLbl: UILabel!
    @IBOutlet weak var checkMarkImageView: UIImageView!
    @IBOutlet weak var doneBtn: UIButton!

    var reference_transaction_id: String!
    let signatureService = SignatureService()
    let requiredHeight:CGFloat = 50.0
    var signature = Signature()
    
    
    let paymentService = PaymentService()
    var payment: Payment!
    var cardDic = Dictionary<String, Any>()
    var customerDic = Dictionary<String, Any>()
    var emv: Dictionary<String, Any>?
    var deviceCode: String!
    
    var statusString = "Successful"
        
    var locationManager: CLLocationManager!
    let geoCoder = CLGeocoder()

    @IBOutlet weak var signatureView: YPDrawSignatureView!
    
    @IBAction func backClicked(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let finalAmount = String(format: "$%@", payment.amount)
        self.amountLbl.text = finalAmount
        // Do any additional setup after loading the view, typically from a nib.
        
        // Setting this view controller as the signature view delegate, so the didStart(_ view: YPDrawSignatureView) and
        // didFinish(_ view: YPDrawSignatureView) methods below in the delegate section are called.
        signatureView.delegate = self
        let value = UIInterfaceOrientation.landscapeLeft.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
        UIViewController.attemptRotationToDeviceOrientation()
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
    
    
//    override var preferredStatusBarStyle: UIStatusBarStyle {
//        return .lightContent
//    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscapeLeft
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if (self.isMovingFromParent) {
            UIDevice.current.setValue(Int(UIInterfaceOrientation.portrait.rawValue), forKey: "orientation")
        }
        startLocationFetching()

    }
    
    @objc func canRotate() -> Void {}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Function for clearing the content of signature view
    @IBAction func clearSignature(_ sender: UIButton) {
        // This is how the signature gets cleared
        self.signatureView.clear()
    }
    
    @IBAction func checkmarkClicked(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            self.checkMarkImageView.image = UIImage(systemName: "checkmark")
            self.doneBtn.isEnabled = true
            self.doneBtn.alpha = 1.0
        } else {
            self.checkMarkImageView.image = nil
            self.doneBtn.isEnabled = false
            self.doneBtn.alpha = 0.5
        }
    }
    
    
    func createApiKey() {
        showSpinner(onView: self.view)
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
        self.paymentService.makePayment(payment:payment, cardInfo: self.cardDic, customerInfo: self.customerDic, emv: emv, device_code: self.deviceCode) { (jsonValue, err) in
            DispatchQueue.main.async {
               
                guard err == nil else {
                    self.hideSpinner()
                  //  self.resetPaymentInfo()
                    self.displayAlert(title: err!.localizedDescription, message: "")
                    return
                }
                guard let json = jsonValue else {
                    self.hideSpinner()
                   // self.resetPaymentInfo()
                    self.displayAlert(title: "Something went wrong", message: "")
                    return
                }
                print(json)
                let response = json["transaction_response"].dictionaryValue
                print(response)
                if let code = response["result_code"]?.intValue, code == 1, let trsn_id = response["transaction_id"]?.stringValue, let amount = response["amount"]?.stringValue, let authcode = response["auth_code"]?.stringValue {
                    print("payment success with\(trsn_id)")
                    self.signature.setTransaction(Id: trsn_id)
                    self.reference_transaction_id = trsn_id
//                    self.confirmBtn.isEnabled = false
//                    self.confirmBtn.alpha = 0.5
                    self.stopLocationFetching()
                   // self.miura.displayText("Transaction Approved\n Thank you.".center, completion: nil)
                     DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.makeTransactionWith()
                            //call any function
                     }
                    
                   // self.makeTransactionWith()
                  //  self.showPaymentAlertWith(title: "Approved", btnName: "Continue", amount: amount, authCode: authcode, success: true)
                } else if let status = response["result_text"]?.stringValue {
                    print(status)
                    self.hideSpinner()
                    self.statusString = "Failed"
                    self.performSegue(withIdentifier: "signToStatus", sender: nil)
                   // self.miura.displayText("Transaction Declined\n Try again.".center, completion: nil)
                  //  self.showPaymentAlertWith(title: "Declined", btnName: "Retry", amount: "", authCode: "", success: false)
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
//            self.miura.closeSession()
//            if(success) {
//                self.performSegue(withIdentifier: "ManualEntryToSign", sender: nil)
//            }
            self.makeTransaction()
        }))
        self.present(showAlert, animated: true, completion: nil)
    }
    
    
    
    @objc func makeTransactionWith() {
       // showSpinner(onView: self.view)
        self.signatureService.sendSignature(signature:signature) { (jsonValue, err) in
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
                    self.performSegue(withIdentifier: "signToStatus", sender: nil)
                } else if let status = response["result_text"]?.stringValue {
                    print(status)
                    self.statusString = "Failed"
                    self.performSegue(withIdentifier: "signToStatus", sender: nil)
                }
            }
        }
    }
    
    
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    // Function for saving signature
    @IBAction func saveSignature(_ sender: UIButton) {
        
        // Getting the Signature Image from self.drawSignatureView using the method getSignature().
        if let signatureImage = self.signatureView.getCroppedSignature() {

            let aspectRatio = signatureImage.size.width / signatureImage.size.height
            let newWidth = requiredHeight * aspectRatio
            let resizedImage = resizeImage(image: signatureImage, targetSize: CGSize(width: newWidth, height: requiredHeight))
            
            // Saving signatureImage from the line above to the Photo Roll.
            // The first time you do this, the app asks for access to your pictures.
          //  UIImageWriteToSavedPhotosAlbum(resizedImage, nil, nil, nil)
            // Since the Signature is now saved to the Photo Roll, the View can be cleared anyway.
            
           // print(resizedImage.getBase64Size(.low) as Any)
            let base64Str = resizedImage.toBase64(.low)!
           // print(base64Str)
            signature.setSignature(base64Str: base64Str)
            createApiKey()
            
        } else {
            signatureView.viewBorderColor = .red
        }
    }
    
    // MARK: - Delegate Methods
    
    // The delegate functions gives feedback to the instanciating class. All functions are optional,
    // meaning you just implement the one you need.
    
    // didStart() is called right after the first touch is registered in the view.
    // For example, this can be used if the view is embedded in a scroll view, temporary
    // stopping it from scrolling while signing.
    func didStart(_ view : YPDrawSignatureView) {
        print("Started Drawing")
        signatureView.viewBorderColor = .lightGray
    }
    
    // didFinish() is called rigth after the last touch of a gesture is registered in the view.
    // Can be used to enabe scrolling in a scroll view if it has previous been disabled.
    func didFinish(_ view : YPDrawSignatureView) {
        print("Finished Drawing")
    }
    
    
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
        let statusVc = segue.destination as? StatusViewController
        statusVc?.reference_transaction_id = reference_transaction_id
         statusVc?.amount = payment.amount
         if let fn = customerDic["first_name"] as? String, let ln = customerDic["last_name"] as? String {
             statusVc?.customer = String(format: "%@ %@", fn, ln)
         }
         statusVc?.transactionId = reference_transaction_id
         statusVc?.transactionDate = Date().generateCurrentDateTime()
         statusVc?.status = statusString
     }
    
}


extension SignatureViewController: CLLocationManagerDelegate {
    
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
