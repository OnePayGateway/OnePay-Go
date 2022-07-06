//
//  PaymentStatusView.swift
//  OnePay
//
//  Created by Palani Krishnan on 6/27/22.
//  Copyright © 2022 Certify Global. All rights reserved.
//

import UIKit
import Foundation

class PaymentStatusView: UIView {
    
    @IBOutlet weak var statusLbl: UILabel!
    @IBOutlet weak var transactionIdLbl: UILabel!
    @IBOutlet weak var amountLbl: UILabel!
    @IBOutlet weak var cuustomerLbl: UILabel!
    @IBOutlet weak var transactionDateLbl: UILabel!
    @IBOutlet weak var statuIcon: UIImageView!
    @IBOutlet weak var sendReceipt: UIButton!
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    func loadUI(with amount:String, transId: String?, status:String, name:String, date:String) {
        self.statusLbl.text = String(format: "Payment %@", status)
        if status.lowercased() == "successful" {
            self.statuIcon.image =  UIImage(named: "approved")
        } else {
            self.statuIcon.image =  UIImage(named: "declined")
            self.sendReceipt.setTitle("Retry", for: .normal)
        }
        self.transactionIdLbl.text = transId
        self.amountLbl.text = String(format: "$%@", amount)
        self.cuustomerLbl.text = name.isEmpty ? "Unknown" : name
        self.transactionDateLbl.text = date
    }

}
