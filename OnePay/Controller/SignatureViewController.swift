//
//  SignatureViewController.swift
//  OnePay
//
//  Created by Palani Krishnan on 5/24/19.
//  Copyright © 2019 Certify Global. All rights reserved.
//

import UIKit

class SignatureViewController: UIViewController,YPSignatureDelegate {
    @IBOutlet weak var amountLbl: UILabel!
    
    var reference_transaction_id: String!
    let signatureService = SignatureService()
    let requiredHeight:CGFloat = 50.0
    var signature = Signature()

    @IBOutlet weak var signatureView: YPDrawSignatureView!
    
    @IBAction func backClicked(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        signature.setTransaction(Id: reference_transaction_id)
      //  let finalAmount = String(format: "$%@", amount)
       // self.amountLbl.text = finalAmount
        // Do any additional setup after loading the view, typically from a nib.
        
        // Setting this view controller as the signature view delegate, so the didStart(_ view: YPDrawSignatureView) and
        // didFinish(_ view: YPDrawSignatureView) methods below in the delegate section are called.
        signatureView.delegate = self
        let value = UIInterfaceOrientation.landscapeLeft.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
        UIViewController.attemptRotationToDeviceOrientation()
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
    
    func makeTransactionWith() {
        showSpinner(onView: self.view)
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
                    self.performSegue(withIdentifier: "SignToReceipt", sender: nil)
                } else if let status = response["result_text"]?.stringValue {
                    print(status)
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
            makeTransactionWith()
            
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
        let receiptVc = segue.destination as? ReceiptViewController
        receiptVc?.reference_transaction_id = reference_transaction_id
     }
    
}
