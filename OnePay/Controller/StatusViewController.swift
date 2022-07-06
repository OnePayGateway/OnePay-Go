//
//  StatusViewController.swift
//  OnePay
//
//  Created by Palani Krishnan on 6/16/22.
//  Copyright © 2022 Certify Global. All rights reserved.
//

import UIKit

class StatusViewController: UIViewController {

    var reference_transaction_id: String!
    @IBOutlet weak var statuView: PaymentStatusView!
    

    var status: String!
    var transactionId: String?
    var amount: String!
    var customer: String?
    var transactionDate: String!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        let value = UIInterfaceOrientation.portrait.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
        UIViewController.attemptRotationToDeviceOrientation()
        
        statuView.loadUI(with: amount, transId: transactionId, status: status, name: customer ?? "", date: transactionDate)
        // Do any additional setup after loading the view.
    }
    
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    @IBAction func cancelClicked(_ sender: Any) {
        NotificationCenter.default.post(name: Notification.Name("resetSalePage"), object: nil, userInfo: nil)
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    @IBAction func retryOrReceiptClicked(_ sender: Any) {
        if status.lowercased() == "successful" {
            NotificationCenter.default.post(name: Notification.Name("resetSalePage"), object: nil, userInfo: nil)
            self.performSegue(withIdentifier: "fromStatusToReceipt", sender: nil)
        } else {
            self.navigationController?.popToRootViewController(animated: true)
        }
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
