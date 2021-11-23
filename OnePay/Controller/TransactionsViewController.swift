//
//  TransactionsViewController.swift
//  OnePay
//
//  Created by Palani Krishnan on 5/20/19.
//  Copyright © 2019 Certify Global. All rights reserved.
//

import UIKit
import Stripe

class TransactionsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, voidDelegate {

    @IBOutlet weak var transactionTableView: UITableView!
    let imageView = UIImageView()
    @IBOutlet weak var topView: UIView!
    var transactionHistroy: TransactionHistory!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
       // transactionTableView.contentInset = UIEdgeInsets(top: 80, left: 0, bottom: 0, right: 0)
        
        imageView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 105)
        imageView.image = UIImage.init(named: "CheckoutBg")
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        topView.addSubview(imageView)
        showSpinner(onView: self.view)
        getTransactionsList()
        // Do any additional setup after loading the view.
    }
    
    func madeVoidPayment() {
        getTransactionsList()
    }
    
    func getTransactionsList() {
        let fromDate = Date.changeDaysBy(days: -7)
        let toDate = Date().generateCurrentTime()
        TransactionHistoryService().retrieveTransactions(from: fromDate, to: toDate) { (json, err) in
            DispatchQueue.main.async {
            if(err == nil) {
                let msg = json?.dictionaryValue["Message"]
                if msg == "Authorization has been denied for this request." {
                    LoginService().refreshTokenInServer(success: { (status) in
                        if status == true {
                            self.getTransactionsList()
                        } else {
                            self.hideSpinner()
                            Session.shared.logOut()
                            let loginVc = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateInitialViewController()
                            self.view.window?.rootViewController = loginVc
                        }
                    })
                    return
                }
                
                self.transactionHistroy = TransactionHistory(transactionsList: json!.arrayValue)
                self.transactionTableView.reloadData()
                self.hideSpinner()
              }
            else {
                self.hideSpinner()
                self.displayAlert(title: err!.localizedDescription, message: "")
            }
          }
        }
    }
    
//    override var preferredStatusBarStyle: UIStatusBarStyle {
//        return .default
//    }
    
    @IBAction func menuClicked(_ sender: Any) {
        sideMenuController?.revealMenu()
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


extension TransactionsViewController {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if((transactionHistroy) != nil) {
           return transactionHistroy.transactionsList.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "transactionCell", for: indexPath)
        let nameLbl = cell.viewWithTag(10) as? UILabel
        nameLbl?.text = transactionHistroy.name(forIndex: indexPath.row)
        
        let statusLbl = cell.viewWithTag(11) as? UILabel
        statusLbl?.text = transactionHistroy.status(forIndex: indexPath.row)
        
        let amountLbl = cell.viewWithTag(100) as? UILabel
        amountLbl?.text = String(format: "$%0.2f", transactionHistroy.amount(forIndex: indexPath.row)!)
        
        let dateLbl = cell.viewWithTag(101) as? UILabel
        dateLbl?.text = transactionHistroy.transactionDate(forIndex: indexPath.row)
        
        if let cardtype = transactionHistroy.cardType(forIndex: indexPath.row) {
            let imageView = cell.viewWithTag(1000) as? UIImageView
            imageView?.image = imageFor(cardType: cardtype)
        }
        
        return cell
    }
    
    func imageFor(cardType:String) -> UIImage {
        switch cardType {
        case "Visa":
            return STPPaymentCardTextField.brandImage(for: .visa)!
        case "Amex":
            return STPPaymentCardTextField.brandImage(for: .amex)!
        case "Master Card":
            return STPPaymentCardTextField.brandImage(for: .masterCard)!
        case "Discover":
            return STPPaymentCardTextField.brandImage(for: .discover)!
        case "JCB":
            return STPPaymentCardTextField.brandImage(for: .JCB)!
        case "Diners":
            return STPPaymentCardTextField.brandImage(for: .dinersClub)!
        case "Union Pay":
            return STPPaymentCardTextField.brandImage(for: .unionPay)!
        default:
            return STPPaymentCardTextField.brandImage(for: .unknown)!
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let detailVc = self.storyboard?.instantiateViewController(withIdentifier: "transactionDetail") as? TransactionInfoViewController
        detailVc?.transactionId = transactionHistroy.transactionId(forIndex: indexPath.row)
        detailVc?.transactionStatus = transactionHistroy.status(forIndex: indexPath.row)
        detailVc?.vDelegate = self
        if let cardtype = transactionHistroy.cardType(forIndex: indexPath.row) {
            detailVc?.cardBrandImage = imageFor(cardType: cardtype)
        }
        self.navigationController?.pushViewController(detailVc!, animated: true)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let y = 105 - (scrollView.contentOffset.y + 105)
        let height = min(max(y, 105), 400)
        imageView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: height)
    }
    
}
